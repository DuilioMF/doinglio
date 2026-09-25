$ErrorActionPreference='Stop'
$port=37890
$base="http://127.0.0.1:$port"
$project=(Resolve-Path '.').Path
$fixture=Join-Path $env:RUNNER_TEMP 'doinglio-http-smoke'
Remove-Item $fixture -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path (Join-Path $fixture 'capitan-rodolfo') -Force | Out-Null
Copy-Item (Join-Path $project 'index.html') (Join-Path $fixture 'index.html')
Copy-Item (Join-Path $project 'doinglio-window.js') (Join-Path $fixture 'doinglio-window.js')
Set-Content (Join-Path $fixture 'capitan-rodolfo\index.html') '<html><head><title>Especialista</title></head><body>Prueba</body></html>'
$serverScript=Join-Path $project 'launcher\doinglio_web_server.ps1'
$arguments=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$serverScript+'"'),'-Root',('"'+$fixture+'"'),'-Port',[string]$port)
$server=Start-Process -FilePath powershell.exe -ArgumentList $arguments -PassThru -WindowStyle Hidden
try {
  $ready=$false
  for($i=0;$i -lt 30;$i++){
    Start-Sleep -Milliseconds 250
    try{
      $health=Invoke-RestMethod -Uri "$base/_doinglio_health" -TimeoutSec 2
      if($health.ok){$ready=$true;break}
    }catch{}
  }
  if(-not $ready){throw 'El servidor local no inició'}
  $master=(Invoke-WebRequest -UseBasicParsing -Uri "$base/" -TimeoutSec 3).Content
  if($master -notmatch 'window.__doinglioExitToken='){throw 'Falta token en Cuaderno Maestro'}
  if($master -notmatch 'src="doinglio-window.js"'){throw 'Cuaderno Maestro no carga X'}
  $child=(Invoke-WebRequest -UseBasicParsing -Uri "$base/capitan-rodolfo/index.html" -TimeoutSec 3).Content
  if($child -notmatch 'src="/doinglio-window.js"'){throw 'No se inyectó X en especialista'}
  if($child -notmatch 'window.__doinglioExitToken='){throw 'Falta token en especialista'}
  $invalidRejected=$false
  try {
    Invoke-WebRequest -UseBasicParsing -Uri "$base/_doinglio_exit" -Method POST -Headers @{'Origin'=$base;'X-DoingLio-Exit'='invalido'} -TimeoutSec 3 | Out-Null
  }catch [System.Net.WebException]{
    if([int]$_.Exception.Response.StatusCode -eq 403){$invalidRejected=$true}else{throw}
  }
  if(-not $invalidRejected){throw 'Token inválido aceptado'}
  $tokenMatch=[regex]::Match($master, 'window\.__doinglioExitToken="([a-f0-9]{32})"')
  if(-not $tokenMatch.Success){throw 'No se obtuvo token de la sesión'}
  $response=Invoke-RestMethod -Uri "$base/_doinglio_exit" -Method POST -Headers @{'Origin'=$base;'X-DoingLio-Exit'=$tokenMatch.Groups[1].Value} -TimeoutSec 3
  if(-not $response.ok){throw 'Cierre válido rechazado'}
  Start-Sleep -Milliseconds 1000
  if(-not $server.HasExited){
    $server.Refresh()
    if(-not $server.HasExited){throw 'Servidor no terminó tras cierre válido'}
  }
  Write-Host 'OK: servidor local, X compartida en todas las páginas y cierre con token.'
}finally{
  if(-not $server.HasExited){Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue}
  Remove-Item $fixture -Recurse -Force -ErrorAction SilentlyContinue
}
