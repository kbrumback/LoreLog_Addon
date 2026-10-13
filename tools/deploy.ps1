# Updates C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns with the latest LoreLog files.
# Usage: powershell -ExecutionPolicy Bypass -File tools/deploy.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'LoreLog'
$destination = 'C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns'

if (-not (Test-Path $destination)) {
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
}

$target = Join-Path $destination 'LoreLog'
if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Force -Path $target | Out-Null
}

Get-ChildItem -Path $source -Exclude '.git' | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $target -Recurse -Force
}
Write-Host "Successfully updated '$target' with the latest addon files." -ForegroundColor Green
