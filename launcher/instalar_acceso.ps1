param([switch]$NoLaunch)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Instalacion por usuario: acceso de Windows, SIN privilegios de administrador.
$Root = "C:\Sistemas\DoingLioLauncher"
$Base = "https://raw.githubusercontent.com/DuilioMF/doinglio/main"
$Bat = Join-Path $Root "DOINGLIO.bat"
$Icon = Join-Path $Root "brain-davinci.ico"
$Vbs = Join-Path $Root "DoingLioInicio.vbs"
$Splash = Join-Path $Root "reloj_inicio.hta"
$InstallLog = Join-Path $Root "instalador.log"

New-Item -ItemType Directory -Force -Path $Root | Out-Null
function Write-InstallLog([string]$Message) {
    Add-Content -Path $InstallLog -Value ("["+(Get-Date).ToString("s")+"] "+$Message)
}
function Download-Atomic([string]$Url,[string]$File) {
    $temp = $File + ".download"
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $temp -TimeoutSec 40
        if(-not (Test-Path $temp) -or (Get-Item $temp).Length -eq 0){ throw "Descarga vacia: $Url" }
        Move-Item -Path $temp -Destination $File -Force
    } finally {
        Remove-Item $temp -Force -ErrorAction SilentlyContinue
    }
}

try {
    Write-InstallLog "Instalando acceso directo DoingLio"
    Download-Atomic ($Base + "/DOINGLIO.bat") $Bat
    $OpenScript = Join-Path $Root "abrir_doinglio.ps1"
    Download-Atomic ($Base + "/launcher/abrir_doinglio.ps1") $OpenScript
    $encodedPath = Join-Path $Root "brain-davinci.ico.b64"
    Download-Atomic ($Base + "/launcher/brain-davinci.ico.b64") $encodedPath
    $bytes = [Convert]::FromBase64String(([IO.File]::ReadAllText($encodedPath)).Trim())
    if($bytes.Length -lt 100){ throw "Archivo de icono incompleto" }
    [IO.File]::WriteAllBytes($Icon,$bytes)
    Remove-Item $encodedPath -Force

    # La apertura silenciosa muestra el mismo reloj 4:10 de la portada
    # mientras el launcher descarga y activa la copia local.
    Download-Atomic ($Base + "/launcher/reloj_inicio.hta") $Splash
    Download-Atomic ($Base + "/launcher/DoingLioInicio.vbs") $Vbs
    if(-not (Test-Path $Splash) -or (Get-Item $Splash).Length -lt 600){
       throw "No se pudo instalar el reloj de arranque"
    }

    $desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
    if([string]::IsNullOrWhiteSpace($desktop)){ throw "Windows no devolvio la ubicacion del Escritorio" }
    $destination = Join-Path $desktop "DoingLio.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($destination)
    $shortcut.TargetPath = Join-Path $env:WINDIR "System32\wscript.exe"
    $shortcut.Arguments = '"' + $Vbs + '"'
    $shortcut.WorkingDirectory = $Root
    $shortcut.IconLocation = $Icon + ",0"
    $shortcut.Description = "DoingLio - Cuaderno Maestro (se actualiza al iniciar)"
    $shortcut.WindowStyle = 7
    $shortcut.Save()

    if(-not (Test-Path $destination)){ throw "No se pudo crear el acceso directo en el Escritorio" }
    if(-not (Test-Path $OpenScript)){ throw "No se descargo el arrancador con diagnostico" }
    $check = $shell.CreateShortcut($destination)
    if($check.IconLocation -notmatch "brain-davinci.ico"){ throw "El acceso directo no conserva el icono de cerebro" }
    Write-InstallLog ("Acceso creado: " + $destination + " | Icono: " + $Icon)
    Write-Host "LISTO: acceso DoingLio con icono de cerebro en el Escritorio."
    Write-Host "Acceso: $destination"
    Write-Host "Archivo: $Bat"

    if(-not $NoLaunch){ Start-Process -FilePath $destination }
    exit 0
} catch {
    Write-InstallLog ("ERROR: " + $_.Exception.Message)
    Write-Host ("ERROR creando acceso: " + $_.Exception.Message)
    Write-Host ("Log: " + $InstallLog)
    exit 1
}
