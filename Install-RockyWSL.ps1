<#
  Install-RockyWSL.ps1
  --------------------
  Rocky Linux를 WSL에 자동 설치/등록하는 스크립트
  - rootfs(.tar.xz) 다운로드 → wsl --import 등록(WSL2)
  - 패키지 매니저 자동 감지(dnf 또는 microdnf) → 업데이트/기본 툴 설치
  - 사용자 생성/기본 사용자 설정 → /etc/wsl.conf(systemd 포함)
  - .tar.xz import 실패 시 .tar 변환 후 재시도
  - RockyVersion 파라미터 하나로 최신(latest) 및 고정(vault) 모두 지원
#>

[CmdletBinding()]
param(
  # "9" 또는 "8" → pub 경로 최신(latest)
  # "9.6", "9.4", "8.10" → vault 경로 고정
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

function Write-Info($msg)  { Write-Host "[정보] $msg" -ForegroundColor Cyan }
function Write-OK($msg)    { Write-Host "[완료] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[주의] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[오류] $msg" -ForegroundColor Red }

# RockyVersion 해석: "9" / "8" → pub 최신, "9.6" 등 → vault 고정
function Resolve-RockyChannel([string]$Version, [string]$Var) {
  $isMinorPinned = $Version -match '^\d+\.\d+$'
  $isMajorOnly   = $Version -match '^\d+$'

  if (-not ($isMinorPinned -or $isMajorOnly)) {
    throw "RockyVersion 형식 오류: '$Version' (예: '9', '8', '9.6', '8.10')"
  }

  if ($isMinorPinned) {
    $major = [int]($Version.Split('.')[0])
    if ($major -notin @(8,9)) { throw "지원 메이저는 8 또는 9입니다. 입력: $major" }
    $baseUrl = "https://dl.rockylinux.org/vault/rocky/$Version/images/x86_64"
    $mode = "vault"
  } else {
    $major = [int]$Version
    if ($major -notin @(8,9)) { throw "지원 메이저는 8 또는 9입니다. 입력: $major" }
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
    Write-Info "rootfs 다운로드 중: $($info.Url)"
    Invoke-WebRequest -Uri $info.Url -OutFile $tarXzPath -UseBasicParsing
    Write-OK "rootfs 다운로드 완료: $tarXzPath"
  } else {
    Write-Info "기존에 다운로드된 rootfs를 사용합니다: $tarXzPath"
  }
  return $tarXzPath
}

function Import-WSL([string]$Distro, [string]$Path, [string]$TarXzPath) {
  Write-Info "WSL 배포판 등록 시도: $Distro → $Path"
  try {
    wsl --import "$Distro" "$Path" "$TarXzPath" --version 2
    Write-OK "WSL 배포판 등록 완료(.tar.xz): $Distro"
  } catch {
    Write-Warn "압축 파일(.tar.xz) import 실패. .tar 변환 후 재시도합니다."
    $tempDir    = Split-Path $TarXzPath -Parent
    $extractDir = Join-Path $tempDir "rootfs_extract"
    $tarPath    = Join-Path $tempDir ((Split-Path $TarXzPath -Leaf) -replace '\.tar\.xz$','.tar')

    if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

    & tar -C $extractDir -xJf $TarXzPath
    if (Test-Path $tarPath) { Remove-Item -Force $tarPath }
    Push-Location $extractDir
    try { & tar -cf $tarPath * } finally { Pop-Location }

    wsl --import "$Distro" "$Path" "$tarPath" --version 2
    Write-OK "WSL 배포판 등록 완료(.tar 변환): $Distro"
  }
}

# 경로 및 중복 확인
$TempDir = Join-Path $env:TEMP "rocky-wsl"
$null = New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
if (-not (Test-Path $InstallPath)) { New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null }
try { $existing = wsl -l -q | Where-Object { $_ -eq $DistroName } } catch { $existing=$null }
if ($existing) { Write-Err "이미 동일 이름의 배포판 존재: $DistroName"; exit 1 }

# 채널/URL 결정 및 다운로드
$info = Resolve-RockyChannel -Version $RockyVersion -Var $Variant
Write-Info ("다운로드 채널: {0} (요청='{1}')" -f $info.Mode, $info.Version)
$tarXzPath = Download-Rootfs -info $info -tempDir $TempDir

# import
Import-WSL -Distro $DistroName -Path $InstallPath -TarXzPath $tarXzPath

# 초기화 스크립트 (bash) — Base64 전달, /etc/wsl.conf는 printf로 작성
$EnableSystemdStr = if ($EnableSystemd) { "true" } else { "false" }
$SkipUpdateStr    = if ($SkipUpdate)    { "true" } else { "false" }

$initScript = @"
set -e

SKIP_UPDATE="$SkipUpdateStr"
ENABLE_SYSTEMD="$EnableSystemdStr"

# 패키지 매니저 자동 감지
PKG=""
if command -v dnf >/dev/null 2>&1; then
  PKG="dnf"
elif command -v microdnf >/dev/null 2>&1; then
  PKG="microdnf"
else
  echo "[오류] dnf/microdnf 없음"
  exit 1
fi

# 업데이트/기본 툴 설치
if [ "\$SKIP_UPDATE" != "true" ]; then
  \$PKG -y update || true
fi

# 일부 이미지에 useradd가 없을 수 있어 shadow-utils 포함
\$PKG -y install sudo passwd which vim curl git shadow-utils || true

# 일반 사용자 생성 및 wheel 부여
if ! id -u "$Username" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$Username" || true
  echo "$Username:changeme" | chpasswd || true
  usermod -aG wheel "$Username" || true
  chage -d 0 "$Username" || true
fi

# /etc/wsl.conf 백업 및 덮어쓰기
[ -f /etc/wsl.conf ] && cp -f /etc/wsl.conf /etc/wsl.conf.bak || true
printf '%s\n' "[user]" "default = $Username" "" "[boot]" "systemd = $ENABLE_SYSTEMD" > /etc/wsl.conf

echo "[완료] 초기화 끝. PowerShell에서 'wsl --shutdown' 후 다시 접속하세요."
"@

# Base64로 인코딩 후 WSL 내부에서 실행
$bytes = [System.Text.Encoding]::UTF8.GetBytes(($initScript -replace "`r`n","`n").Replace("`r","`n"))
$b64   = [Convert]::ToBase64String($bytes)

$bashCmd = "base64 -d > /tmp/init.sh <<< $b64; sed -i 's/\r$//' /tmp/init.sh; chmod +x /tmp/init.sh; bash /tmp/init.sh; rm -f /tmp/init.sh"
wsl -d "$DistroName" -u root -- bash -lc "$bashCmd"
Write-OK "내부 초기화 완료"

try { wsl --set-default "$DistroName" | Out-Null; Write-OK "기본 배포판으로 설정: $DistroName" } catch { }
wsl --shutdown
Write-OK "설치 완료!"
Write-Host "접속: wsl -d $DistroName" -ForegroundColor Green
Write-Host "초기 비밀번호: 'changeme' (첫 로그인 시 변경 안내)" -ForegroundColor Yellow
