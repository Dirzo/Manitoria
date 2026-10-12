$ErrorActionPreference = 'Stop'
$checks = Get-Content (Join-Path $PSScriptRoot 'sha256.json') | ConvertFrom-Json
foreach ($name in @('Manitoria.exe','Manitoria.pck')) {
 $output = [IO.File]::Create((Join-Path $PSScriptRoot $name))
 try { Get-ChildItem -LiteralPath $PSScriptRoot -Filter "$name.part*" | Sort-Object Name | ForEach-Object {
  $inputFile = [IO.File]::OpenRead($_.FullName)
  try { $inputFile.CopyTo($output) } finally { $inputFile.Dispose() }
 }} finally { $output.Dispose() }
 if ((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $name) -Algorithm SHA256).Hash.ToLower() -ne $checks.$name) { throw "Checksum failed: $name" }
}
Write-Host 'Manitoria v0.79 is ready. Run Manitoria.exe or Narrate-Manitoria.cmd.'
