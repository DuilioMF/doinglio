param(
  [Parameter(Mandatory=$true)][string]$Root,
  [int]$Port = 8790
)

$ErrorActionPreference = "Stop"
$Root = [IO.Path]::GetFullPath($Root)

function Mime([string]$Path){
  switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()){
    ".html" { "text/html; charset=utf-8" }
    ".htm"  { "text/html; charset=utf-8" }
    ".js"   { "application/javascript; charset=utf-8" }
    ".css"  { "text/css; charset=utf-8" }
    ".json" { "application/json; charset=utf-8" }
    ".svg"  { "image/svg+xml" }
    ".png"  { "image/png" }
    ".jpg"  { "image/jpeg" }
    ".jpeg" { "image/jpeg" }
    ".gif"  { "image/gif" }
    ".ico"  { "image/x-icon" }
    ".txt"  { "text/plain; charset=utf-8" }
    default { "application/octet-stream" }
  }
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

try {
  while($listener.IsListening){
    $ctx = $listener.GetContext()
    try {
      $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
      if($path -eq "/_doinglio_health"){
        $body = [Text.Encoding]::UTF8.GetBytes('{"ok":true,"service":"DoingLio Local Web"}')
        $ctx.Response.StatusCode = 200
        $ctx.Response.ContentType = "application/json; charset=utf-8"
        $ctx.Response.ContentLength64 = $body.Length
        $ctx.Response.OutputStream.Write($body,0,$body.Length)
        $ctx.Response.Close()
        continue
      }

      if($path -eq "/"){ $path = "/index.html" }
      $relative = $path.TrimStart("/") -replace "/","\"
      $file = [IO.Path]::GetFullPath((Join-Path $Root $relative))
      if(-not $file.StartsWith($Root,[StringComparison]::OrdinalIgnoreCase)){
        $ctx.Response.StatusCode = 403
        $ctx.Response.Close()
        continue
      }

      if(Test-Path $file -PathType Leaf){
        $bytes = [IO.File]::ReadAllBytes($file)
        $ctx.Response.StatusCode = 200
        $ctx.Response.ContentType = Mime $file
        $ctx.Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
      } else {
        $ctx.Response.StatusCode = 404
      }
    } catch {
      try { $ctx.Response.StatusCode = 500 } catch {}
    } finally {
      try { $ctx.Response.Close() } catch {}
    }
  }
}
finally {
  $listener.Stop()
  $listener.Close()
}
