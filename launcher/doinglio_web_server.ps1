param(
  [Parameter(Mandatory=$true)][string]$Root,
  [int]$Port = 8790
)
$ErrorActionPreference = "Stop"
$Root = [IO.Path]::GetFullPath($Root)
$ConnectorState = Join-Path $Root "connector.json"
$MaxBody = 131072
$ExitToken = [guid]::NewGuid().ToString('N') # token efímero para cerrar solo el escritorio local
function Get-Mime([string]$Path){
 switch([IO.Path]::GetExtension($Path).ToLowerInvariant()){
 '.html'{'text/html; charset=utf-8'} '.htm'{'text/html; charset=utf-8'}
 '.js'{'application/javascript; charset=utf-8'} '.css'{'text/css; charset=utf-8'}
 '.json'{'application/json; charset=utf-8'} '.svg'{'image/svg+xml'}
 '.png'{'image/png'} '.ico'{'image/x-icon'} '.jpg'{'image/jpeg'}
 '.jpeg'{'image/jpeg'} '.gif'{'image/gif'} default{'application/octet-stream'}
 }
}
function Send-Response($Stream,[int]$Code,[string]$Type,[byte[]]$Body){
 $statusText=switch($Code){200{'OK'}400{'Bad Request'}403{'Forbidden'}404{'Not Found'}405{'Method Not Allowed'}413{'Payload Too Large'}500{'Internal Server Error'}502{'Bad Gateway'}503{'Service Unavailable'} default{'Error'}}
 $nl=[string]([char]13)+[string]([char]10)
 $headers="HTTP/1.1 $Code $statusText" + $nl + "Content-Type: $Type" + $nl + "Content-Length: $($Body.Length)" + $nl + "Cache-Control: no-store" + $nl + "X-Content-Type-Options: nosniff" + $nl + "Connection: close" + $nl + $nl
 $h=[Text.Encoding]::ASCII.GetBytes($headers)
 $Stream.Write($h,0,$h.Length)
 if($Body.Length){$Stream.Write($Body,0,$Body.Length)}
 $Stream.Flush()
}
function Send-Text($Stream,[int]$Code,[string]$Text,[string]$Mime='text/plain; charset=utf-8'){
 Send-Response $Stream $Code $Mime ([Text.Encoding]::UTF8.GetBytes($Text))
}
function Send-Json($Stream,[int]$Code,$Object){
 Send-Text $Stream $Code ($Object | ConvertTo-Json -Depth 5 -Compress) 'application/json; charset=utf-8'
}
function Receive-Request($Stream){
 $header=New-Object 'System.Collections.Generic.List[byte]'
 $matched=0
 $end=[byte[]](13,10,13,10)
 while($header.Count -lt 32768){
   $b=$Stream.ReadByte()
   if($b -lt 0){return $null}
   $header.Add([byte]$b)
   if($b -eq $end[$matched]){$matched++}else{$matched=if($b -eq 13){1}else{0}}
   if($matched -eq 4){break}
 }
 if($matched -ne 4){throw 'Cabecera HTTP demasiado grande'}
 $crlf=[string]([char]13)+[string]([char]10)
 $lines=([Text.Encoding]::ASCII.GetString($header.ToArray())).Split([string[]]@($crlf),[StringSplitOptions]::None)
 $start=$lines[0].Split(' ')
 if($start.Count -lt 2){throw 'Peticion HTTP invalida'}
 $headers=@{}
 foreach($line in $lines[1..($lines.Count-1)]){
  $idx=$line.IndexOf(':')
  if($idx -gt 0){$headers[$line.Substring(0,$idx).Trim().ToLowerInvariant()]=$line.Substring($idx+1).Trim()}
 }
 $size=0
 if($headers.ContainsKey('content-length') -and -not [int]::TryParse($headers['content-length'],[ref]$size)){throw 'Content-Length invalido'}
 if($size -lt 0 -or $size -gt $MaxBody){throw 'Cuerpo demasiado grande'}
 $body=New-Object byte[] $size
 $read=0
 while($read -lt $size){
   $n=$Stream.Read($body,$read,$size-$read)
   if($n -le 0){throw 'Cuerpo HTTP incompleto'}
   $read+=$n
 }
 return [pscustomobject]@{method=$start[0];path=$start[1];headers=$headers;body=$body}
}
function Read-ConnectorSafeDiagnostic {
 $expected=''
 $expectedPath=Join-Path $Root 'capitan-rodolfo\VERSION'
 try {if(Test-Path $expectedPath){$expected=(Get-Content $expectedPath -Raw).Trim()}}catch{}
 $detail=@{expectedVersion=$expected;serviceState='sin estado';serviceVersion='';serviceError='';launcherLog='C:\Sistemas\DoingLioLauncher\launcher.log';bridgeErrorLog='C:\Sistemas\DoingLioConnector\bridge.err.log'}
 $file='C:\Sistemas\DoingLio\data\capitan\estado.json'
 if(Test-Path $file){
  try {
   $st=Get-Content $file -Raw|ConvertFrom-Json
   $detail.serviceState=[string]$st.state
   $detail.serviceVersion=[string]$st.version
   if($st.error){
    $message=[string]$st.error
    if($message -match '(?i)password|contrase.a|bearer|token|api.key|secret|sk-'){ $message='Ver estado.json local para diagnóstico protegido' }
    $detail.serviceError=$message.Substring(0,[Math]::Min(250,$message.Length))
   }
  } catch {$detail.serviceState='No se puede leer estado.json'}
 }
 return $detail
}
function Test-PortService([int]$Port,[string]$ExpectedVersion) {
 if($Port -lt 1024 -or $Port -gt 65535){return $false}
 try {
  $h=Invoke-RestMethod -Uri ("http://127.0.0.1:"+$Port+"/health") -TimeoutSec 1
  return ($h.ok -and $h.service -eq 'Capitan Rodolfo Local' -and
    [string]$h.version -eq $ExpectedVersion -and $h.apiSqlObject -eq $true)
 }catch{return $false}
}
function Find-ReadyConnector {
 # En caso de conflicto Windows elige un puerto libre; el PID del servicio lo
 # guarda en estado.json. No probar puertos arbitrarios sin verificar /health.
 $d=Read-ConnectorSafeDiagnostic
 if([string]::IsNullOrWhiteSpace($d.expectedVersion)){return $null}
 $ports=@()
 $file='C:\Sistemas\DoingLio\data\capitan\estado.json'
 if(Test-Path $file){
  try{
   $st=Get-Content $file -Raw|ConvertFrom-Json
   $foundPort=0
   if([int]::TryParse([string]$st.port,[ref]$foundPort) -and
      $foundPort -ge 1024 -and $foundPort -le 65535){$ports += $foundPort}
  }catch{}
 }
 # Dos puertos habituales como respaldo, no esperar siete intentos por request.
 $ports += @(8787,8797)
 foreach($port in @($ports | Select-Object -Unique)){
  if(Test-PortService -Port ([int]$port) -ExpectedVersion ([string]$d.expectedVersion)){
   $found=@{ok=$true;port=[int]$port;version=[string]$d.expectedVersion;updatedAt=(Get-Date).ToString('o')}
   $found | ConvertTo-Json | Set-Content -Path $ConnectorState -Encoding UTF8
   return $found
  }
 }
 return $null
}
function Proxy-Sql($Stream,$Request){
 $state=$null
 if(Test-Path $ConnectorState){
  try{$state=Get-Content -Path $ConnectorState -Raw | ConvertFrom-Json}catch{}
 }
 # connector.json podria ser anterior al nuevo arranque. Confirmar servicio y version
 # ANTES de enviar credenciales de SQL o cualquier otra solicitud.
 $expected=(Read-ConnectorSafeDiagnostic).expectedVersion
 if(-not $state -or -not $state.ok -or -not $state.port -or
    -not (Test-PortService -Port ([int]$state.port) -ExpectedVersion ([string]$expected))){
  $state=Find-ReadyConnector
 }
 if(-not $state -or -not $state.ok -or -not $state.port){
  $diag=Read-ConnectorSafeDiagnostic
  Send-Json $Stream 503 @{ok=$false;error='El conector SQL no esta activo. Revisá el diagnóstico local; se reintenta descubrir el servicio automáticamente.';diagnostic=$diag};return
 }
 $sqlPort=[int]$state.port
 if($sqlPort -lt 1024 -or $sqlPort -gt 65535){
  Send-Json $Stream 503 @{ok=$false;error='El conector registro un puerto invalido.'};return
 }
 $path=$Request.path.Substring('/_doinglio_sql'.Length)
 if($path -eq '' -or $path -eq '/'){$path='/'}
 if(-not $path.StartsWith('/')){$path='/'+$path}
 $target='http://127.0.0.1:'+$sqlPort+$path
 try{
  $req=[Net.HttpWebRequest]::Create($target)
  $req.Method=$Request.method
  $proxyTimeout=if($path -in @('/api/circuit/install','/api/circuit/admin-install')){120000} elseif($path -in @('/api/station/payments','/api/station/payment-cards','/api/station/payment-evidence')){90000} else {20000}
  $req.Timeout=$proxyTimeout
  $req.ReadWriteTimeout=$proxyTimeout
  $req.AllowAutoRedirect=$false
  $req.ServicePoint.Expect100Continue=$false
  if($Request.method -eq 'POST'){
   $req.ContentType='application/json; charset=utf-8'
   $req.ContentLength=$Request.body.Length
   $out=$req.GetRequestStream()
   try{$out.Write($Request.body,0,$Request.body.Length)}finally{$out.Close()}
  }
  $resp=$null
  try{$resp=$req.GetResponse()}
  catch [Net.WebException]{if($_.Exception.Response){$resp=$_.Exception.Response}else{throw}}
  if(-not $resp){throw 'Sin respuesta del conector'}
  try{
   $ms=New-Object IO.MemoryStream
   $input=$resp.GetResponseStream()
   try{$input.CopyTo($ms)}finally{$input.Close()}
   $mime=[string]$resp.ContentType
   if(-not $mime){$mime='application/octet-stream'}
   Send-Response $Stream ([int]$resp.StatusCode) $mime ($ms.ToArray())
  }finally{$resp.Close()}
 }catch{Send-Json $Stream 502 @{ok=$false;error=('Conector en puerto '+$sqlPort+' sin respuesta: '+$_.Exception.Message)}}
}
$listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
$listener.Start()
try{
 while($true){
  $client=$listener.AcceptTcpClient()
  try{
   $client.ReceiveTimeout=20000
   $stream=$client.GetStream()
   $req=Receive-Request $stream
   if($null -eq $req){continue}
   $hostValue=[string]$req.headers['host']
   if(@("127.0.0.1:$Port","localhost:$Port") -notcontains $hostValue){Send-Text $stream 403 'Host no permitido';continue}
   if($req.method -ne 'GET' -and $req.method -ne 'POST'){Send-Text $stream 405 'Metodo no permitido';continue}
   $origin=[string]$req.headers['origin']
   if($origin -and @("http://127.0.0.1:$Port","http://localhost:$Port") -notcontains $origin){Send-Text $stream 403 'Origen no permitido';continue}
   $path=($req.path -split '\?')[0]
   if($path -eq '/_doinglio_exit'){
     if($req.method -ne 'POST'){Send-Text $stream 405 'Solo POST';continue}
     if($origin -ne ("http://127.0.0.1:" + $Port)){Send-Text $stream 403 'Origen no autorizado';continue}
     if([string]$req.headers['x-doinglio-exit'] -ne $ExitToken){Send-Text $stream 403 'Cierre no autorizado';continue}
     Send-Json $stream 200 @{ok=$true}
     # Solo matar procesos bajo el perfil exclusivo. Nunca cerrar el navegador personal.
     Start-Sleep -Milliseconds 350
     try {
       $managed=@(Get-CimInstance Win32_Process -Filter "Name='msedge.exe' OR Name='chrome.exe'" |
         Where-Object { $_.CommandLine -and
           ($_.CommandLine -match [regex]::Escape('C:\Sistemas\DoingLioLauncher\browser-profile-')) })
       $appPattern='--app=http://127\.0\.0\.1:' + $Port + '(?:/|\?)'
       $leaders=@($managed | Where-Object { $_.CommandLine -match $appPattern })
       if($leaders.Count -gt 0){
         foreach($p in $managed){try{Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop}catch{}}
       }
     }catch{}
     break
   }
   if($req.path -match '^/_doinglio_sql(/|$|\?)'){Proxy-Sql $stream $req;continue}
   if($req.method -ne 'GET'){Send-Text $stream 405 'Solo GET para archivos de la aplicacion';continue}
   
   if($path -eq '/_doinglio_health'){
     Send-Json $stream 200 @{ok=$true;service='DoingLio Local';port=$Port;connectorStateFile=$ConnectorState};continue
   }
   if($path -eq '/_doinglio_diagnostic'){
     Send-Json $stream 200 (Read-ConnectorSafeDiagnostic)
     continue
   }
   if($path -eq '/'){$path='/index.html'}
   $relative=[Uri]::UnescapeDataString($path.TrimStart('/')) -replace '/','\'
   $file=[IO.Path]::GetFullPath((Join-Path $Root $relative))
   $prefix=$Root.TrimEnd('\')+'\'
   if(-not $file.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){Send-Text $stream 403 'Acceso denegado';continue}
   if(-not (Test-Path $file -PathType Leaf)){Send-Text $stream 404 'Archivo no encontrado';continue}
   $bytes=[IO.File]::ReadAllBytes($file)
   if([IO.Path]::GetExtension($file).ToLowerInvariant() -in @('.html','.htm')){
     $page=[Text.Encoding]::UTF8.GetString($bytes)
     $injection='<script>window.__doinglioExitToken=' + ($ExitToken | ConvertTo-Json -Compress) + ';</script>'
     if($page -notmatch 'doinglio-window\.js'){
       $injection += '<script src="/doinglio-window.js" defer></script>'
     }
     $headEnd=[regex]::new('(?i)</head>')
     if($headEnd.IsMatch($page)){$page=$headEnd.Replace($page,($injection+'</head>'),1)}
     else{$page=$injection+$page}
     $bytes=[Text.Encoding]::UTF8.GetBytes($page)
   }
   Send-Response $stream 200 (Get-Mime $file) $bytes
  }catch{try{Send-Json $stream 500 @{error=$_.Exception.Message}}catch{}}
  finally{try{$client.Close()}catch{}}
 }
}finally{$listener.Stop()}
