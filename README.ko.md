# `rocky-wsl`

> [English](README.md), [Korean](README.ko.md)

- `WSL`용 Rocky Linux 설정
- `WSL2` 이상 사용

---

- PowerShell에서 스크립트 실행:

```
PS C:\workspace\wsl\rocky> .\Install-RockyWSL.ps1
```

- 실행 전 다음 필드를 조정하세요:

```powershell
[CmdletBinding()]
param(
  # "9" 또는 "8" → 최신 pub 경로
  # "9.6", "9.4", "8.10" → 고정 vault 경로
  [string]$RockyVersion = "9",

  [ValidateSet("Base","Minimal","UBI")]
  [string]$Variant = "Base",

  [string]$DistroName = "RockyLinux",

  [string]$InstallPath = "C:\WSL\Rocky",

  [string]$Username = "rocky",

  [bool]$EnableSystemd = $true,

  [bool]$SkipUpdate = $false
)
```

- `UBI`: Red Hat(RHEL)과 호환되는 Universal Base Image입니다. 컨테이너 환경(Docker, Podman 등)을 위한 이미지입니다.

---

## 주요 버전 비교표 (`Rocky` vs `RHEL`)

| Rocky 버전 | 릴리스 날짜 | 대응 RHEL 버전 / 릴리스 날짜 | 주요 커널 / 기능 | 지원 종료 / EOL (Rocky) | 비고 |
|--------------|---------------|-------------------------------------------|-------------------------|-------------------------------|-------|
| **Rocky 8.4** ("Green Obsidian") | 2021-06-21 | RHEL 8.4 (2021-05-18) | Kernel 4.18 | 2029년 5월까지 보안 지원 | 약 34일 지연 릴리스 |
| **Rocky 8.5** | 2021-11-15 | RHEL 8.5 (2021-11-09) | — | 동일 | 약 6일 지연 |
| **Rocky 8.6** | 2022-05-16 | RHEL 8.6 (2022-05-10) | — | 동일 | 약 6일 지연 |
| **Rocky 8.7** | 2022-11-14 | RHEL 8.7 (2022-11-09) | — | 동일 | 약 5일 지연 |
| **Rocky 8.8** | 2023-05-20 | RHEL 8.8 (2023-05-16) | — | 동일 | 약 4일 지연 |
| **Rocky 8.9** | 2023-11-22 | RHEL 8.9 (2023-11-14) | — | 동일 | 약 8일 지연 |
| **Rocky 8.10** | 2024-05-30 | RHEL 8.10 (2024-05-23) | — | 2029년까지 보안 지원 | 8 시리즈 마지막 마이너 릴리스 |
| **Rocky 9.0** ("Blue Onyx") | 2022-07-14 | RHEL 9.0 (2022-05-17) | Kernel 5.14 | 2032년 5월까지 지원 예정 | 약 58일 지연 |
| **Rocky 9.x** | 진행 중 | 해당 RHEL 마이너 릴리스 | — | 동일 | 예: RHEL 9.3 (2023-11-07), Rocky 9.3 (2023-11-20) |
| **Rocky 10.0** ("Red Quartz") | 2025-06-11 | RHEL 10 (Kernel 6.12) | — | ~2035년까지 지원 예정 | — |

---

## 기본 계정 설정

```bash
# 홈 디렉토리 생성(-m) 및 기본 셸(/bin/bash) 지정
useradd -m -s /bin/bash j2

# 비밀번호 설정
passwd j2

# sudo 권한 부여
usermod -aG wheel j2

# WSL 기본 사용자 변경
vim /etc/wsl.conf

# 다음 추가:
[user]
default=j2

# PowerShell에서 WSL 재시작:
wsl --shutdown
wsl -d RockyLinux
```

---

## 개발 도구 설치

```bash
# 시스템 업데이트
sudo dnf update -y

# Development Tools 그룹 설치
sudo dnf groupinstall -y "Development Tools"

# C++17+ 추가 패키지
sudo dnf install -y gcc-c++ cmake ninja-build git
```
