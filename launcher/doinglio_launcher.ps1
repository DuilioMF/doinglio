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
Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] Inicio DoingLio D27")

function Log([string]$Message){
  Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] "+$Message)
}

function Download-Text([string]$Url,[string]$OutFile){
  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $OutFile -TimeoutSec 30
}
# Actualizar el splash y VBS del acceso ya instalado, sin recrear el acceso
# ni alterar el icono. Este cambio aparece desde la siguiente apertura.
if(-not $CI -and (Test-Path (Join-Path $Root "DoingLioInicio.vbs"))){
  foreach($item in @(
    @{source="reloj_inicio.hta";dest="reloj_inicio.hta"},
    @{source="DoingLioInicio.vbs";dest="DoingLioInicio.vbs"}
  )){
    $target=Join-Path $Root $item.dest
    $tmp=$target+".download"
    try {
      Download-Text ("https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/"+$item.source) $tmp
      if((Get-Item $tmp).Length -lt 100){throw "Descarga incompleta"}
      Move-Item $tmp $target -Force
    } catch {
      Log ("Reloj de apertura: no pude actualizar "+$item.source+": "+$_.Exception.Message)
    } finally {Remove-Item $tmp -Force -ErrorAction SilentlyContinue}
  }
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

function Get-ManagedProcesses([string]$ScriptFullPath){
  # Solo detener procesos cuyos argumentos apuntan a NUESTRA instalacion.
  $match = [regex]::Escape($ScriptFullPath)
  try {
    @(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction Stop |
      Where-Object { $_.CommandLine -and $_.CommandLine -match $match })
  } catch {
    Log ("No pude consultar procesos propios de " + $ScriptFullPath + ": " + $_.Exception.Message)
    @()
  }
}
function Stop-ManagedBridge {
  # La tarea podria estar ejecutando el antiguo script residente.
  # No se borran credenciales, bases ni archivos de estado.
  try { & schtasks.exe /End /TN "CapitanRodolfoLocal" 2>$null | Out-Null } catch {}
  foreach($proc in @(Get-ManagedProcesses $Bridge)){
    if($proc.ProcessId -eq $PID){ continue }
    Log ("Deteniendo SOLO conector anterior PID=" + $proc.ProcessId)
    try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop }
    catch { Log ("ERROR deteniendo PID " + $proc.ProcessId + ": " + $_.Exception.Message) }
  }
  Start-Sleep -Milliseconds 400
}
function Stop-PreviousWeb {
  # El pid guardado puede haber sido reutilizado. Validar la linea de comandos.
  foreach($proc in @(Get-ManagedProcesses $ServerScript)){
    if($proc.ProcessId -eq $PID){ continue }
    Log ("Cerrando servidor web propio anterior PID=" + $proc.ProcessId)
    try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop }
    catch { Log ("ERROR cerrando web anterior: " + $_.Exception.Message) }
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

$ConnectorServiceStatusPath = "C:\Sistemas\DoingLio\data\capitan\estado.json"
function Get-ConnectorCandidatePorts {
  # El conector guarda el puerto REAL que eligio Windows en estado.json.
  $ports = @()
  if(Test-Path $ConnectorServiceStatusPath){
    try{
      $st=Get-Content $ConnectorServiceStatusPath -Raw | ConvertFrom-Json
      $actual=0
      if([int]::TryParse([string]$st.port,[ref]$actual) -and $actual -ge 1024 -and $actual -le 65535){
        $ports += $actual
      }
    }catch{Log ("No se pudo leer puerto de conector: " + $_.Exception.Message)}
  }
  $ports += @(8787,8797,18787,27877,37877,48787,57877)
  return @($ports | Select-Object -Unique)
}
function Test-Connector {
  foreach($p in @(Get-ConnectorCandidatePorts)){
    try {
      $r=Invoke-RestMethod -Uri ("http://127.0.0.1:"+$p+"/health") -TimeoutSec 1
      if($r.ok -and $r.service -eq "Capitan Rodolfo Local" -and
         [string]$r.version -eq $ExpectedConnectorVersion -and $r.apiSqlObject -eq $true){ return $p }
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

  # El codigo descargado y el bridge residente deben quedar en la MISMA version.
  # Antes de reemplazar el archivo, retirar solo instancias de nuestro conector viejo.
  $NewConnectorVersion = (Get-Content (Join-Path $BuildRuntime "capitan-rodolfo\VERSION") -Raw).Trim()
  if(-not $CI){
    $oldRunning = $false
    foreach($port in @(Get-ConnectorCandidatePorts)){
      try {
        $h=Invoke-RestMethod -Uri ("http://127.0.0.1:"+$port+"/health") -TimeoutSec 1
        if($h.ok -and $h.service -eq "Capitan Rodolfo Local" -and
           [string]$h.version -eq $NewConnectorVersion -and $h.apiSqlObject -eq $true){
          $oldRunning=$true
          Log ("Conector correcto v" + $NewConnectorVersion + " ya activo en " + $port)
          break
        }
      } catch {}
    }
    if(-not $oldRunning){
      Log ("Retirando conector anterior antes de activar v" + $NewConnectorVersion)
      Stop-ManagedBridge
    }
  }

  # Copiar el componente SQL desde la misma version de Capitan que acabamos de bajar.
  Copy-Item (Join-Path $BuildRuntime "capitan-rodolfo\bridge\capitan_rodolfo_local.ps1") $Bridge -Force
  Copy-Item (Join-Path $BuildRuntime "capitan-rodolfo\VERSION") $VersionFile -Force
  # SP descargado en cada apertura. Solo el conector (con credenciales locales)
  # puede instalarlo si el usuario SQL tiene permiso de esquema.
  $circuitSource = Join-Path $BuildRuntime "capitan-rodolfo\sql\PA_CapitanRodolfo_CircuitoEstacion.sql"
  $circuitFolder = Join-Path $Connector "sql"
  if(Test-Path $circuitSource){
    New-Item -ItemType Directory -Path $circuitFolder -Force | Out-Null
    Copy-Item $circuitSource (Join-Path $circuitFolder "PA_CapitanRodolfo_CircuitoEstacion.sql") -Force
    Log "SP de circuito sincronizado desde GitHub. Instalacion automatica: solo si el usuario SQL cuenta con permisos."
  } else {
    Log "ADVERTENCIA: la descarga de Capitan no contiene el SP de circuito"
  }

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

# 2. Levantar la conexion SQL local, verificar su version y recordar su puerto.
$ExpectedConnectorVersion = "desconocida"
if(Test-Path $VersionFile){ $ExpectedConnectorVersion = (Get-Content $VersionFile -Raw).Trim() }
Log ("Version esperada del conector: "+$ExpectedConnectorVersion)
if(-not $CI){
  $connectorPort = Test-Connector
  if(-not $connectorPort -and (Test-Path $Bridge)){
    try {
      $bridgeOut = Join-Path $Connector "bridge.out.log"
      $bridgeErr = Join-Path $Connector "bridge.err.log"
      $bridgeProcess = Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -PassThru -ArgumentList @(
        "-NoProfile","-ExecutionPolicy","Bypass","-File",$Bridge,"-AppDir",$Connector,"-BackgroundChild"
      ) -RedirectStandardOutput $bridgeOut -RedirectStandardError $bridgeErr
      Log ("Conector SQL v"+$ExpectedConnectorVersion+" lanzado PID="+$bridgeProcess.Id+"; esperando health. stdout="+$bridgeOut+" stderr="+$bridgeErr)
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
    Log ("Conector SQL v$ExpectedConnectorVersion listo puerto " + $connectorPort)
    try {
      @{ok=$true;port=[int]$connectorPort;version=$ExpectedConnectorVersion;updatedAt=(Get-Date).ToString("o")} |
        ConvertTo-Json | Set-Content -Path (Join-Path $Runtime "connector.json") -Encoding UTF8
    } catch { Log ("No pude escribir connector.json: "+$_.Exception.Message) }
  } else {
    Log ("ERROR: el conector SQL v"+$ExpectedConnectorVersion+" no respondio /health luego de 15 segundos")
    try { if(Test-Path (Join-Path $Connector "bridge.err.log")){ Get-Content (Join-Path $Connector "bridge.err.log") -Tail 12 | ForEach-Object { Log ("bridge.err: "+$_) } } } catch {}
    try { if(Test-Path "C:\Sistemas\DoingLio\data\capitan\estado.json"){ Log ("Existe estado local en C:\Sistemas\DoingLio\data\capitan\estado.json") } } catch {}
    try {
      @{ok=$false;port=$null;version=$ExpectedConnectorVersion;updatedAt=(Get-Date).ToString("o")} |
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

# D27: abrir la web local en una ventana inmersiva propia.
# Start-Process de una URL abre el navegador NORMAL (barra de direcciones).
# Modo --app evita pestanas/barra y --start-fullscreen oculta tambien el
# marco. El perfil propio evita que una ventana anterior absorba los flags.
function Open-ImmersiveDoingLio([string]$Url) {
  $bases = @(
    [Environment]::GetEnvironmentVariable('ProgramFiles(x86)'),
    [Environment]::GetEnvironmentVariable('ProgramFiles'),
    [Environment]::GetEnvironmentVariable('LOCALAPPDATA')
  )
  $candidates = New-Object 'System.Collections.Generic.List[object]'
  foreach($base in $bases) {
    if([string]::IsNullOrWhiteSpace($base)){continue}
    foreach($relative in @('Microsoft\Edge\Application\msedge.exe','Google\Chrome\Application\chrome.exe')) {
      $executable = Join-Path $base $relative
      if((Test-Path $executable) -and -not @($candidates | Where-Object { $_.path -eq $executable }).Count) {
        $candidates.Add(@{path=$executable;name=if($relative.StartsWith('Microsoft')){'Edge'}else{'Chrome'}})
      }
    }
  }
  foreach($browser in $candidates) {
    try {
      $profile = Join-Path $Root ('browser-profile-' + $browser.name.ToLowerInvariant())
      New-Item -ItemType Directory -Path $profile -Force | Out-Null
      $args = @(
        '--app=' + $Url,
        '--start-fullscreen',
        '--new-window',
        '--no-first-run',
        '--no-default-browser-check',
        '--user-data-dir="' + $profile + '"'
      )
      $process = Start-Process -FilePath $browser.path -ArgumentList $args -PassThru -ErrorAction Stop
      Log ('D27: ventana inmersiva sin barra con ' + $browser.name + '; PID=' + $process.Id)
      return $true
    } catch {
      Log ('No pude abrir ' + $browser.name + ' en modo aplicacion: ' + $_.Exception.Message)
    }
  }
  Log 'ADVERTENCIA: no se encontro Edge/Chrome funcional; abriendo URL en navegador habitual CON barra.'
  Start-Process $Url
  return $false
}

$desktopUrl = 'http://127.0.0.1:'+$webPort+'/?desktop=1'
$null = Open-ImmersiveDoingLio $desktopUrl
exit 0
