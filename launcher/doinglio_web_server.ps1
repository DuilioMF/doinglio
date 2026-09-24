param(
  [Parameter(Mandatory=$true)][string]$Root,
  [int]$Port = 8790
)

$ErrorActionPreference = "Stop"
$Root = [IO.Path]::GetFullPath($Root)

function Get-Mime([string]$Path){
  switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()){
    ".html" { return "text/html; charset=utf-8" }
    ".htm"  { return "text/html; charset=utf-8" }
    ".js"   { return "application/javascript; charset=utf-8" }
    ".css"  { return "text/css; charset=utf-8" }
    ".json" { return "application/json; charset=utf-8" }
    ".svg"  { return "image/svg+xml" }
    ".png"  { return "image/png" }
    ".jpg"  { return "image/jpeg" }
    ".jpeg" { return "image/jpeg" }
    ".gif"  { return "image/gif" }
    ".ico"  { return "image/x-icon" }
    ".txt"  { return "text/plain; charset=utf-8" }
    default { return "application/octet-stream" }
  }
}

function Send-Response($Stream,[int]$Code,[string]$Type,[byte[]]$Body){
  $text = switch($Code){200{"OK"}404{"Not Found"}403{"Forbidden"}500{"Internal Server Error"}default{"OK"}}
  $nl = [Environment]::NewLine
  $headers = "HTTP/1.1 $Code $text" + $nl +
             "Content-Type: $Type" + $nl +
             "Content-Length: $($Body.Length)" + $nl +
             "Cache-Control: no-store, no-cache, must-revalidate" + $nl +
             "Connection: close" + $nl + $nl
  $hb=[Text.Encoding]::ASCII.GetBytes($headers)
  $Stream.Write($hb,0,$hb.Length)
  if($Body.Length -gt 0){ $Stream.Write($Body,0,$Body.Length) }
  $Stream.Flush()
}

$listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
$listener.Start()

try{
  while($true){
    $client=$listener.AcceptTcpClient()
    try{
      $stream=$client.GetStream()
      $reader=New-Object IO.StreamReader($stream,[Text.Encoding]::UTF8,$false,4096,$true)
      $line=$reader.ReadLine()
      if([string]::IsNullOrWhiteSpace($line)){ continue }
      $parts=$line.Split(' ')
      if($parts.Count -lt 2){ continue }
      $method=$parts[0]
      $rawPath=$parts[1]
      while($true){ $h=$reader.ReadLine(); if($null -eq $h -or $h -eq ''){break} }

      if($method -ne "GET"){
        Send-Response $stream 403 "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("GET only"))
        continue
      }

      $path=($rawPath -split '\?')[0]
      if($path -eq "/_doinglio_health"){
        Send-Response $stream 200 "application/json; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes('{"ok":true,"service":"DoingLio Local Web"}'))
        continue
      }
      if($path -eq "/"){ $path="/index.html" }

      $relative=[Uri]::UnescapeDataString($path.TrimStart('/')) -replace '/','\'
      $file=[IO.Path]::GetFullPath((Join-Path $Root $relative))
      if(-not $file.StartsWith($Root,[StringComparison]::OrdinalIgnoreCase)){
        Send-Response $stream 403 "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("Forbidden"))
        continue
      }
      if(-not (Test-Path $file -PathType Leaf)){
        Send-Response $stream 404 "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("Not found"))
        continue
      }

      $bytes=[IO.File]::ReadAllBytes($file)
      Send-Response $stream 200 (Get-Mime $file) $bytes
    } catch {
      try{ Send-Response $stream 500 "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes($_.Exception.Message)) }catch{}
    } finally {
      try{$client.Close()}catch{}
    }
  }
} finally {
  $listener.Stop()
}
