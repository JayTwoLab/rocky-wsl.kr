<#
  Install-RockyWSL.ps1
  --------------------
  Script to automatically install/register Rocky Linux in WSL
  - Download rootfs(.tar.xz) → Register with wsl --import (WSL2)
  - Auto-detect package manager (dnf or microdnf) → Update/install basic tools
  - Create user/set default user → /etc/wsl.conf (including systemd)
  - If .tar.xz import fails, convert to .tar and retry
  - Support both latest (pub) and fixed (vault) versions with single RockyVersion parameter
#>

[CmdletBinding()]
param(
  # "9" or "8" → pub path latest
  # "9.6", "9.4", "8.10" → vault path fixed
  [string]$RockyVersion = "9",

  [ValidateSet("Base","Minimal","UBI")]
  [string]$Variant = "Base",

  [string]$DistroName = "RockyLinux",

  [string]$InstallPath = "C:\WSL\Rocky",

  [string]$Username = "rocky",

  [bool]$EnableSystemd = $true,

  [bool]$SkipUpdate = $false
)

$ErrorActionPreference = "Stop"

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-OK($msg)    { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# Parse RockyVersion: "9" / "8" → pub latest, "9.6" etc → vault fixed
function Resolve-RockyChannel([string]$Version, [string]$Var) {
  $isMinorPinned = $Version -match '^\d+\.\d+$'
  $isMajorOnly   = $Version -match '^\d+$'

  if (-not ($isMinorPinned -or $isMajorOnly)) {
    throw "RockyVersion format error: '$Version' (e.g., '9', '8', '9.6', '8.10')"
  }

  if ($isMinorPinned) {
    $major = [int]($Version.Split('.')[0])
    if ($major -notin @(8,9)) { throw "Supported major versions are 8 or 9. Input: $major" }
    $baseUrl = "https://dl.rockylinux.org/vault/rocky/$Version/images/x86_64"
    $mode = "vault"
  } else {
    $major = [int]$Version
    if ($major -notin @(8,9)) { throw "Supported major versions are 8 or 9. Input: $major" }
    $baseUrl = "https://dl.rockylinux.org/pub/rocky/$major/images/x86_64"
    $mode = "pub"
  }

  $stem   = "Rocky-$major-Container-$Var.latest.x86_64"
  $xzName = "$stem.tar.xz"

  [PSCustomObject]@{
    Mode      = $mode
    Major     = $major
    Version   = $Version
    BaseUrl   = $baseUrl
    FileStem  = $stem
    TarXzName = $xzName
    Url       = "$baseUrl/$xzName"
  }
}

function Download-Rootfs($info, $tempDir) {
  $tarXzPath = Join-Path $tempDir $info.TarXzName
  if (-not (Test-Path $tarXzPath)) {
    Write-Info "Downloading rootfs: $($info.Url)"
    Invoke-WebRequest -Uri $info.Url -OutFile $tarXzPath -UseBasicParsing
    Write-OK "Rootfs download complete: $tarXzPath"
  } else {
    Write-Info "Using previously downloaded rootfs: $tarXzPath"
  }
  return $tarXzPath
}

function Import-WSL([string]$Distro, [string]$Path, [string]$TarXzPath) {
  Write-Info "Attempting to register WSL distribution: $Distro → $Path"
  
  wsl --import "$Distro" "$Path" "$TarXzPath" --version 2 2>$null
  
  if ($LASTEXITCODE -eq 0) {
    Write-OK "WSL distribution registered successfully (.tar.xz): $Distro"
  } else {
    Write-Warn "Failed to import compressed file (.tar.xz). Converting to .tar and retrying."
    $tempDir    = Split-Path $TarXzPath -Parent
    $extractDir = Join-Path $tempDir "rootfs_extract"
    $tarPath    = Join-Path $tempDir ((Split-Path $TarXzPath -Leaf) -replace '\.tar\.xz$','.tar')

    if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

    & tar -C $extractDir -xJf $TarXzPath
    if ($LASTEXITCODE -ne 0) { throw "Failed to extract .tar.xz file" }
    
    if (Test-Path $tarPath) { Remove-Item -Force $tarPath }
    Push-Location $extractDir
    try { 
      & tar -cf $tarPath *
      if ($LASTEXITCODE -ne 0) { throw "Failed to create .tar file" }
    } finally { Pop-Location }

    wsl --import "$Distro" "$Path" "$tarPath" --version 2
    if ($LASTEXITCODE -ne 0) { throw "Failed to import .tar file to WSL" }
    Write-OK "WSL distribution registered successfully (.tar conversion): $Distro"
  }
}

# Check paths and duplicates
$TempDir = Join-Path $env:TEMP "rocky-wsl"
$null = New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
if (-not (Test-Path $InstallPath)) { New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null }
try { $existing = wsl -l -q | Where-Object { $_ -eq $DistroName } } catch { $existing=$null }
if ($existing) { Write-Err "Distribution with the same name already exists: $DistroName"; exit 1 }

# Determine channel/URL and download
$info = Resolve-RockyChannel -Version $RockyVersion -Var $Variant
Write-Info ("Download channel: {0} (Requested='{1}')" -f $info.Mode, $info.Version)
$tarXzPath = Download-Rootfs -info $info -tempDir $TempDir

# import
Import-WSL -Distro $DistroName -Path $InstallPath -TarXzPath $tarXzPath

# Initialization script (bash) — Base64 transfer, /etc/wsl.conf written with printf
$EnableSystemdStr = if ($EnableSystemd) { "true" } else { "false" }
$SkipUpdateStr    = if ($SkipUpdate)    { "true" } else { "false" }

$initScript = @"
set -e

SKIP_UPDATE="$SkipUpdateStr"
ENABLE_SYSTEMD="$EnableSystemdStr"

# Auto-detect package manager
PKG=""
if command -v dnf >/dev/null 2>&1; then
  PKG="dnf"
elif command -v microdnf >/dev/null 2>&1; then
  PKG="microdnf"
else
  echo "[ERROR] dnf/microdnf not found"
  exit 1
fi

# Update/install basic tools
if [ "\$SKIP_UPDATE" != "true" ]; then
  \$PKG -y update || true
fi

# Include shadow-utils as some images may not have useradd
\$PKG -y install sudo passwd which vim curl git shadow-utils || true

# Create regular user and grant wheel access
if ! id -u "$Username" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$Username" || true
  echo "$Username:changeme" | chpasswd || true
  usermod -aG wheel "$Username" || true
  chage -d 0 "$Username" || true
fi

# Backup and overwrite /etc/wsl.conf
[ -f /etc/wsl.conf ] && cp -f /etc/wsl.conf /etc/wsl.conf.bak || true
printf '%s\n' "[user]" "default = $Username" "" "[boot]" "systemd = $ENABLE_SYSTEMD" > /etc/wsl.conf

echo "[DONE] Initialization complete. Run 'wsl --shutdown' in PowerShell and reconnect."
"@

# Encode to Base64 and execute inside WSL
$bytes = [System.Text.Encoding]::UTF8.GetBytes(($initScript -replace "`r`n","`n").Replace("`r","`n"))
$b64   = [Convert]::ToBase64String($bytes)

$bashCmd = "base64 -d > /tmp/init.sh <<< $b64; sed -i 's/\r$//' /tmp/init.sh; chmod +x /tmp/init.sh; bash /tmp/init.sh; rm -f /tmp/init.sh"
wsl -d "$DistroName" -u root -- bash -lc "$bashCmd"
Write-OK "Internal initialization complete"

try { wsl --set-default "$DistroName" | Out-Null; Write-OK "Set as default distribution: $DistroName" } catch { }
wsl --shutdown
Write-OK "Installation complete!"
Write-Host "Connect: wsl -d $DistroName" -ForegroundColor Green
Write-Host "Initial password: 'changeme' (you will be prompted to change on first login)" -ForegroundColor Yellow
