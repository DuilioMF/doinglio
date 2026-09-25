param()
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Root = "C:\Sistemas\DoingLioLauncher"
$Launcher = Join-Path $Root "doinglio_launcher.ps1"
$Log = Join-Path $Root "inicio.log"
$Url = "https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/doinglio_launcher.ps1"
New-Item -ItemType Directory -Path $Root -Force | Out-Null
function Log([string]$Text){
 Add-Content -Path $Log -Value ("["+(Get-Date).ToString("s")+"] "+$Text)
}
try {
 Log "Inicio desde icono de cerebro; build real en BUILD"
 $Temp = "$Launcher.download"
 try {
   Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Temp -TimeoutSec 30
   if((Get-Item $Temp).Length -lt 100){throw "Descarga de lanzador incompleta"}
   Move-Item -Path $Temp -Destination $Launcher -Force
   Log "Lanzador actualizado"
 } catch {
   Log ("No se pudo actualizar: "+$_.Exception.Message)
   if(-not (Test-Path $Launcher)){throw "Sin Internet y sin lanzador local disponible."}
   Log "Usando ultima version local conocida"
 } finally {
   Remove-Item $Temp -Force -ErrorAction SilentlyContinue
 }
 # Leer el build publicado y enviarlo al reloj mientras permanece visible.
 # El splash antiguo ya consulta last_build.txt periódicamente.
 try {
   $b=Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/DuilioMF/doinglio/main/BUILD' -TimeoutSec 10
   $number=([string]$b).Trim()
   if($number -match '^\d+$'){
     [IO.File]::WriteAllText((Join-Path $Root 'last_build.txt'),$number)
     Log ('Versión del reloj actualizada desde GitHub: D'+$number)
   }
 }catch{Log ('Lectura anticipada BUILD no disponible: '+$_.Exception.Message)}
 & $Launcher *>> $Log
 if($LASTEXITCODE -and $LASTEXITCODE -ne 0){throw "Lanzador devolvio codigo $LASTEXITCODE"}
 $PortPath=Join-Path $Root "web.port"
 if(-not (Test-Path $PortPath)){throw "No se genero web.port (ver launcher.log)"}
 $Port=(Get-Content $PortPath -Raw).Trim()
 if($Port -notmatch '^[0-9]{4,5}$'){throw "Puerto web invalido: $Port"}
 $Health=Invoke-RestMethod -Uri ("http://127.0.0.1:"+$Port+"/_doinglio_health") -TimeoutSec 4
 if(-not $Health.ok){throw "La web local no respondio correctamente"}
 Log ("Web de escritorio verificada en puerto "+$Port)
 exit 0
} catch {
 Log ("ERROR: "+$_.Exception.Message)
 exit 1
}
