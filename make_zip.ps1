Add-Type -AssemblyName System.IO.Compression.FileSystem

$src = "C:\xampp83\htdocs\KiosAisyha\staging_deploy"
$zip = "C:\xampp83\htdocs\KiosAisyha\kios_deploy.zip"

if (Test-Path $zip) {
    Remove-Item $zip -Force
}

Write-Host "Creating zip package..."
[System.IO.Compression.ZipFile]::CreateFromDirectory($src, $zip, [System.IO.Compression.CompressionLevel]::Fastest, $false)

$item = Get-Item $zip
Write-Host "Done! File: $zip"
Write-Host "Size:" ($item.Length / 1MB).ToString("0.00") "MB"
