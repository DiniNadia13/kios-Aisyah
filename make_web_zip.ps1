Add-Type -AssemblyName System.IO.Compression.FileSystem

$base = 'C:\xampp83\htdocs\KiosAisyha'
$webStaging = Join-Path $base 'staging_web'
$zipWeb = Join-Path $base 'web_update.zip'

if (Test-Path $webStaging) {
    Remove-Item $webStaging -Recurse -Force
}
New-Item -ItemType Directory -Path $webStaging -Force | Out-Null

$source = Join-Path $base 'staging_deploy\public_html'
Get-ChildItem -Path $source -Exclude '*.apk' | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $webStaging -Recurse -Force
}

if (Test-Path $zipWeb) {
    Remove-Item $zipWeb -Force
}

[System.IO.Compression.ZipFile]::CreateFromDirectory($webStaging, $zipWeb, [System.IO.Compression.CompressionLevel]::Optimal, $false)
Remove-Item $webStaging -Recurse -Force

$item = Get-Item $zipWeb
Write-Host "Done! File: $zipWeb"
Write-Host "Size:" ($item.Length / 1MB).ToString("0.00") "MB"

