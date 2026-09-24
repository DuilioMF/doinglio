$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Root = "C:\Sistemas\DoingLioLauncher"
$Runtime = "C:\Sistemas\DoingLioRuntime"
$BuildRuntime = "C:\Sistemas\DoingLioRuntime.new"
$Connector = "C:\Sistemas\DoingLioConnector"
$BridgeDir = Join-Path $Connector "bridge"
$Bridge = Join-Path $BridgeDir "capitan_rodolfo_local.ps1"
$VersionFile = Join-Path $Connector "VERSION"
$Allowlist = Join-Path $Connector "sp_allowlist.json"
$ServerScript = Join-Path $Root "doinglio_web_server.ps1"
$WebPidFile = Join-Path $Root "web.pid"
$WebPortFile = Join-Path $Root "web.port"
$Log = Join-Path $Root "launcher.log"
$CI = ($env:DOINGLIO_CI -eq "1")

New-Item -ItemType Directory -Force -Path $Root,$Connector,$BridgeDir | Out-Null
Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] Inicio DoingLio D21")

function Log([string]$Message){
  Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] "+$Message)
}

function Download-Text([string]$Url,[string]$OutFile){
  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $OutFile -TimeoutSec 30
}

function Expand-Repo([string]$Repo,[string]$Destination,[string]$Work){
  $zip = Join-Path $Work ($Repo + ".zip")
  $extract = Join-Path $Work ($Repo + "_extract")
  if(Test-Path $extract){ Remove-Item $extract -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $extract | Out-Null
  $url = "https://github.com/DuilioMF/$Repo/archive/refs/heads/main.zip"
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip -TimeoutSec 60
  Expand-Archive -Path $zip -DestinationPath $extract -Force
  $source = Get-ChildItem -Path $extract -Directory | Select-Object -First 1
  if($null -eq $source){ throw "No pude extraer $Repo" }
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Copy-Item -Path (Join-Path $source.FullName "*") -Destination $Destination -Recurse -Force
}

function Stop-PreviousWeb {
  if(Test-Path $WebPidFile){
    try {
      $oldPid = [int](Get-Content $WebPidFile -Raw).Trim()
      $p = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
      if($p){ Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue }
    } catch {}
  }
  Remove-Item $WebPidFile,$WebPortFile -Force -ErrorAction SilentlyContinue
}

function Get-FreePort {
  foreach($p in @(8790,8791,18790,27890,37890)){
    try {
      $t=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$p)
      $t.Start()
      $t.Stop()
      return $p
    } catch {}
  }
  throw "No encontré un puerto local libre para DoingLio."
}

function Test-Connector {
  foreach($p in @(8787,8797,18787,27877,37877,48787,57877)){
    try {
      $r=Invoke-RestMethod -Uri ("http://127.0.0.1:"+$p+"/health") -TimeoutSec 1
      if($r.ok -and $r.service -eq "Capitan Rodolfo Local" -and [string]$r.version -eq "67"){ return $p }
    } catch {}
  }
  return $null
}

# 1. Descargar SIEMPRE la ultima pagina y especialistas en una carpeta nueva.
$work = Join-Path $env:TEMP ("doinglio_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $work | Out-Null
try {
  if(Test-Path $BuildRuntime){ Remove-Item $BuildRuntime -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $BuildRuntime | Out-Null

  Log "Descargando DoingLio main"
  Expand-Repo -Repo "doinglio" -Destination $BuildRuntime -Work $work
  Log "Descargando Capitan Rodolfo"
  Expand-Repo -Repo "capitan-rodolfo" -Destination (Join-Path $BuildRuntime "capitan-rodolfo") -Work $work
  Log "Descargando Ruben"
  Expand-Repo -Repo "ruben" -Destination (Join-Path $BuildRuntime "ruben") -Work $work

  # Copiar el componente SQL desde la misma version de Capitan que acabamos de bajar.
  Copy-Item (Join-Path $BuildRuntime "capitan-rodolfo\bridge\capitan_rodolfo_local.ps1") $Bridge -Force
  Copy-Item (Join-Path $BuildRuntime "capitan-rodolfo\VERSION") $VersionFile -Force
  if(Test-Path (Join-Path $BuildRuntime "capitan-rodolfo\sp_allowlist.json")){
    Copy-Item (Join-Path $BuildRuntime "capitan-rodolfo\sp_allowlist.json") $Allowlist -Force
  }

  # Actualizar el servidor local desde GitHub.
  Download-Text "https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/doinglio_web_server.ps1" $ServerScript

  Stop-PreviousWeb

  if(Test-Path $Runtime){ Remove-Item $Runtime -Recurse -Force }
  Move-Item $BuildRuntime $Runtime
  Log "Pagina local actualizada"
}
catch {
  Log ("ERROR actualizando pagina: " + $_.Exception.Message)
  if(Test-Path $BuildRuntime){ Remove-Item $BuildRuntime -Recurse -Force -ErrorAction SilentlyContinue }
  if(-not (Test-Path (Join-Path $Runtime "index.html"))){ throw }
}
finally {
  Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Levantar la conexion SQL local y esperar a que responda /health.
if(-not $CI){
  $connectorPort = Test-Connector
  if(-not $connectorPort -and (Test-Path $Bridge)){
    try {
      $bridgeOut = Join-Path $Connector "bridge.out.log"
      $bridgeErr = Join-Path $Connector "bridge.err.log"
      Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -ArgumentList @(
        "-NoProfile","-ExecutionPolicy","Bypass","-File",$Bridge,"-AppDir",$Connector,"-BackgroundChild"
      ) -RedirectStandardOutput $bridgeOut -RedirectStandardError $bridgeErr | Out-Null
      Log ("Conector SQL v67 lanzado; esperando health. stdout="+$bridgeOut+" stderr="+$bridgeErr)
    } catch {
      Log ("ERROR lanzando SQL: " + $_.Exception.Message)
    }
  }

  if(-not $connectorPort){
    for($i=0;$i -lt 30;$i++){
      Start-Sleep -Milliseconds 500
      $connectorPort = Test-Connector
      if($connectorPort){ break }
    }
  }

  if($connectorPort){
    Log ("Conector SQL v67 listo puerto " + $connectorPort)
    try {
      @{ok=$true;port=[int]$connectorPort;version="67";updatedAt=(Get-Date).ToString("o")} |
        ConvertTo-Json | Set-Content -Path (Join-Path $Runtime "connector.json") -Encoding UTF8
    } catch { Log ("No pude escribir connector.json: "+$_.Exception.Message) }
  } else {
    Log "ERROR: el conector SQL v67 no respondio /health luego de 15 segundos"
    try {
      @{ok=$false;port=$null;version="67";updatedAt=(Get-Date).ToString("o")} |
        ConvertTo-Json | Set-Content -Path (Join-Path $Runtime "connector.json") -Encoding UTF8
    } catch {}
  }
}

# 3. Servir la copia local actualizada.
$webPort = Get-FreePort
$web = Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -PassThru -ArgumentList @(
  "-NoProfile","-ExecutionPolicy","Bypass","-File",$ServerScript,"-Root",$Runtime,"-Port",$webPort
)
[IO.File]::WriteAllText($WebPidFile,[string]$web.Id)
[IO.File]::WriteAllText($WebPortFile,[string]$webPort)

$ready=$false
for($i=0;$i -lt 20;$i++){
  Start-Sleep -Milliseconds 150
  try {
    $h=Invoke-RestMethod -Uri ("http://127.0.0.1:"+$webPort+"/_doinglio_health") -TimeoutSec 1
    if($h.ok){ $ready=$true; break }
  } catch {}
}
if(-not $ready){
  try{ Stop-Process -Id $web.Id -Force }catch{}
  throw "La pagina local no pudo iniciar."
}
Log ("Web local lista en puerto " + $webPort)

if($CI){
  try{ Stop-Process -Id $web.Id -Force }catch{}
  exit 0
}

Start-Process ("http://127.0.0.1:"+$webPort+"/?desktop=1")
exit 0
