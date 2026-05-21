param([string]$Src, [string]$Dst)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead($Src)
$e = $z.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
$s = New-Object System.IO.StreamReader($e.Open())
$xml = $s.ReadToEnd()
$s.Close()
$z.Dispose()

# Strip XML tags, but turn paragraph breaks into newlines
$xml = $xml -replace '</w:p>', "`n"
$xml = $xml -replace '<w:tab/>', "`t"
$xml = $xml -replace '<w:br/>', "`n"
$txt = [System.Text.RegularExpressions.Regex]::Replace($xml, '<[^>]+>', '')
# Decode XML entities
$txt = $txt -replace '&amp;','&' -replace '&lt;','<' -replace '&gt;','>' -replace '&quot;','"' -replace '&apos;',"'"
[System.IO.File]::WriteAllText($Dst, $txt, [System.Text.Encoding]::UTF8)
Write-Host "OK length=$($txt.Length)"
