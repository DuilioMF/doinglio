$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$Root = "C:\Sistemas\DoingLioLauncher"
$Connector = "C:\Sistemas\DoingLioConnector"
$BridgeDir = Join-Path $Connector "bridge"
$Bridge = Join-Path $BridgeDir "capitan_rodolfo_local.ps1"
$VersionFile = Join-Path $Connector "VERSION"
$Allowlist = Join-Path $Connector "sp_allowlist.json"
$Log = Join-Path $Root "launcher.log"
$Cloud = "https://duiliomf.github.io/doinglio/?desktop=1&build=17"
$CapRaw = "https://raw.githubusercontent.com/DuilioMF/capitan-rodolfo/main"

New-Item -ItemType Directory -Force -Path $Root,$Connector,$BridgeDir | Out-Null
Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] Inicio DoingLio D17")

# 1) Abrir la pagina primero. La interfaz siempre viene de la nube.
Start-Process $Cloud

function Test-DoingLioConnector {
    $ports = @(8787,8797,18787,27877,37877,48787,57877)
    foreach($p in $ports){
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $ar = $client.BeginConnect("127.0.0.1",$p,$null,$null)
            if($ar.AsyncWaitHandle.WaitOne(120)){
                $client.EndConnect($ar)
                $client.Close()
                try {
                    $health = Invoke-RestMethod -Uri ("http://127.0.0.1:"+$p+"/health") -TimeoutSec 1
                    if($health.ok -and $health.service -eq "Capitan Rodolfo Local"){
                        return $p
                    }
                } catch {}
            } else {
                $client.Close()
            }
        } catch {}
    }
    return $null
}

# 2) Si ya esta activo, no arrancar otro.
$active = Test-DoingLioConnector
if($active){
    Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] SQL ya activo puerto "+$active)
    exit 0
}

# 3) Actualizar solo el componente local SQL. Nunca se instala la pagina.
try {
    Invoke-WebRequest -UseBasicParsing ($CapRaw+"/bridge/capitan_rodolfo_local.ps1?ts="+[DateTime]::UtcNow.Ticks) -OutFile $Bridge
    Invoke-WebRequest -UseBasicParsing ($CapRaw+"/VERSION?ts="+[DateTime]::UtcNow.Ticks) -OutFile $VersionFile
    Invoke-WebRequest -UseBasicParsing ($CapRaw+"/sp_allowlist.json?ts="+[DateTime]::UtcNow.Ticks) -OutFile $Allowlist
    Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] Componente SQL actualizado")
} catch {
    Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] No se pudo actualizar SQL: "+$_.Exception.Message)
}

# 4) Arrancar oculto y salir. No esperar al SQL.
if(Test-Path $Bridge){
    try {
        Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy","Bypass",
            "-File",$Bridge,
            "-AppDir",$Connector,
            "-BackgroundChild"
        )
        Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] SQL lanzado en segundo plano")
    } catch {
        Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] Error al lanzar SQL: "+$_.Exception.Message)
    }
} else {
    Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] Falta bridge local")
}
exit 0
