# init_inite_config.ps1
# Usage:
#   .\init_inite_config.ps1                 # auto-detect removable drive
#   .\init_inite_config.ps1 -Drive E        # use explicit drive letter
#   .\init_inite_config.ps1 -Force          # overwrite without prompt

param(
  [string]$Drive = "",
  [switch]$Force,
  [switch]$Help
)

if ($Help) {
  Write-Output "Usage: .\\init_inite_config.ps1 [-Drive <letter>] [-Force]"
  exit 0
}

function Get-RemovableDrive {
  # DriveType 2 = Removable
  $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -and $_.ProviderName -eq $null }
  if ($drives.Count -gt 0) { return $drives[0].DeviceID }
  return $null
}

if ($Drive -ne "") {
  if ($Drive -match "^[A-Za-z]:?$") {
    if ($Drive.Length -eq 1) { $Drive = "$Drive:`\" }
    elseif ($Drive.Length -eq 2 -and $Drive -notmatch ':$') { $Drive = "$Drive`\" }
  }
  if (-not (Test-Path $Drive)) {
    Write-Error "Drive path '$Drive' does not exist."
    exit 1
  }
  $root = $Drive
} else {
  $detected = Get-RemovableDrive
  if (-not $detected) {
    Write-Error "No removable drive detected. Provide -Drive <letter>."
    exit 2
  }
  $root = $detected + "\"
}

$file = Join-Path $root "inite.config"

if (Test-Path $file -and -not $Force) {
  $ans = Read-Host "File $file exists. Overwrite? (y/N)"
  if ($ans -notin @('y','Y','yes','Yes')) {
    Write-Output "Aborted."
    exit 0
  }
}

Add-Type -AssemblyName System
$uuid = [guid]::NewGuid().ToString()
$ts = (Get-Date).ToString("s")

$content = @"
[init]
created_by = $env:USERNAME
created_at = $ts
id = $uuid
note = This is an automatically created inite.config
"@

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Output "Created $file"
