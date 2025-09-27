# rocky-wsl

- Rocky Linux setting for WSL

---

- 파워쉘에서 스크립트 실행

```
PS C:\workspace\wsl\rocky> .\Install-RockyWSL.ps1
```

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







