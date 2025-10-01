# `rocky-wsl`

- `WSL` 을 위한 `Rocky` 리눅스 설정

<br />

---

- 파워쉘에서 스크립트 실행

```
 PS C:\workspace\wsl\rocky> .\Install-RockyWSL.ps1
```

- 실행 전 다음 필드들을 조정하여 설정

```powershell
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
```

- `UBI` : `Universal Base Image` 레드햇(RHEL)과 호환되는 범용 베이스 이미지. 컨테이너 환경(Docker, Podman 등)에서 사용하기 위해 제공.

- 주요 버전 비교 표 (`Rocky` vs `RHEL`)

| Rocky 버전           | 출격 릴리스 날짜        | 대응 RHEL 버전 / 릴리스 날짜     | 주요 커널 / 특징       | 지원 종료 / EOL (Rocky 기준)       | 비고 / 지연일 등                               |
| -------------------- | ----------------------- | -------------------------------- | ---------------------- | --------------------------------- | ---------------------------------------------- |
| **Rocky 8.4 ("Green Obsidian")** | 2021년 6월 21일   | RHEL 8.4 (2021년 5월 18일)  | 커널 4.18 계열          | Rocky 8은 2029년 5월까지 보안 지원  | 릴리스 지연 약 34일 정도                        |
| **Rocky 8.5**                    | 2021년 11월 15일  | RHEL 8.5 (2021년 11월 9일)  | —                      | 동일 (8 계열 지원)                  | 지연 약 6일                                    |
| **Rocky 8.6**                    | 2022년 5월 16일   | RHEL 8.6 (2022년 5월 10일)  | —                      | 동일                               | 지연 약 6일                                    |
| **Rocky 8.7**                    | 2022년 11월 14일  | RHEL 8.7 (2022년 11월 9일)  | —                      | 동일                               | 지연 약 5일                                    |
| **Rocky 8.8**                    | 2023년 5월 20일   | RHEL 8.8 (2023년 5월 16일)  | —                      | 동일                               | 지연 약 4일                                    |
| **Rocky 8.9**                    | 2023년 11월 22일 | RHEL 8.9 (2023년 11월 14일)  | —                      | 동일                               | 지연 약 8일                                    |
| **Rocky 8.10**                   | 2024년 5월 30일  | RHEL 8.10 (2024년 5월 23일)  | —                      | 보안 지원은 2029년까지 (8 계열)     | 이 버전이 8 계열의 마지막 마이너 릴리스임 (Rocky 8.11은 없음)  |
| **Rocky 9.0 ("Blue Onyx")**      | 2022년 7월 14일   | RHEL 9.0 (2022년 5월 17일)  | 커널 5.14 계열          | Rocky 9은 2032년 5월까지 지원 예정  | 릴리스 지연 약 58일                            |
| **Rocky 9.1, 9.2, 9.3 등**        | 이후 9 계열의 마이너 릴리스 연속           | 대응 RHEL 9의 마이너 릴리스   | —                                 | 동일 (9 계열 지원 기간 내)  | 예: RHEL 9.3은 2023년 11월 7일에 나왔고, Rocky 9.3은 11월 20일에 나옴  |
| **Rocky 10.0 ("Red Quartz")**    | 2025년 6월 11일    | RHEL 10 (커널 6.12 기반)   | —                      | 예정 (Rocky 10 지원 ~ 2035년까지)   | — |      

<br />

---

- 로키 리눅스의 디폴트 계정은 root 이며, 다음과 같은 설정으로 계정을 추가할 수 있다.

```bash

# 홈 디렉터리(-m), 기본 셸(-s /bin/bash) 지정
useradd -m -s /bin/bash j2

# 비밀번호 설정
passwd j2

# sudo 권한 부여
usermod -aG wheel j2

# WSL 기본 사용자 변경
vim /etc/wsl.conf 

# 아래 내용 추가
[user]
default=j2

# PowerShell에서 WSL을 완전히 종료 후 다시 실행:
wsl --shutdown
wsl -d RockyLinux

```

<br />

---

- 개발 도구 설치

```bash

# 시스템 업데이트
sudo dnf update -y

# Development Tools 그룹 설치 (gcc, g++, make, gdb 등 포함)
sudo dnf groupinstall -y "Development Tools"

# 추가 C++ 라이브러리와 헤더 (C++17 이상 개발 시 자주 필요)
sudo dnf install -y gcc-c++ cmake ninja-build git

```







