# `rocky-wsl`

> [English](README.md), [Korean](README.ko.md)

- Rocky Linux setup for `WSL`
- Use `WSL2` or higher

---

- Run the script in PowerShell:

```
PS C:\workspace\wsl\rocky> .\Install-RockyWSL.ps1
```

- Adjust the following fields before execution:

```powershell
[CmdletBinding()]
param(
  # "9" or "8" → latest pub path
  # "9.6", "9.4", "8.10" → fixed vault path
  [string]$RockyVersion = "9",

  [ValidateSet("Base","Minimal","UBI")]
  [string]$Variant = "Base",

  [string]$DistroName = "Rocky9",

  [string]$InstallPath = "C:\WSL\Rocky9",

  [string]$Username = "rocky",

  [bool]$EnableSystemd = $true,

  [bool]$SkipUpdate = $false
)
```

- `UBI`: Universal Base Image compatible with Red Hat (RHEL). Intended for container environments (Docker, Podman, etc.).

---

## Major version comparison table (`Rocky` vs `RHEL`)

| Rocky Version | Release Date | Corresponding RHEL Version / Release Date | Main Kernel / Features | End of Support / EOL (Rocky) | Notes |
|--------------|---------------|-------------------------------------------|-------------------------|-------------------------------|-------|
| **Rocky 8.4** (“Green Obsidian”) | 2021-06-21 | RHEL 8.4 (2021-05-18) | Kernel 4.18 | Security support until May 2029 | Release delayed by about 34 days |
| **Rocky 8.5** | 2021-11-15 | RHEL 8.5 (2021-11-09) | — | Same | Delay about 6 days |
| **Rocky 8.6** | 2022-05-16 | RHEL 8.6 (2022-05-10) | — | Same | Delay about 6 days |
| **Rocky 8.7** | 2022-11-14 | RHEL 8.7 (2022-11-09) | — | Same | Delay about 5 days |
| **Rocky 8.8** | 2023-05-20 | RHEL 8.8 (2023-05-16) | — | Same | Delay about 4 days |
| **Rocky 8.9** | 2023-11-22 | RHEL 8.9 (2023-11-14) | — | Same | Delay about 8 days |
| **Rocky 8.10** | 2024-05-30 | RHEL 8.10 (2024-05-23) | — | Security support until 2029 | Last minor release of 8 series |
| **Rocky 9.0** (“Blue Onyx”) | 2022-07-14 | RHEL 9.0 (2022-05-17) | Kernel 5.14 | Support planned until May 2032 | Delay about 58 days |
| **Rocky 9.x** | Ongoing | Corresponding RHEL minor releases | — | Same | Example: RHEL 9.3 (2023-11-07), Rocky 9.3 (2023-11-20) |
| **Rocky 10.0** (“Red Quartz”) | 2025-06-11 | RHEL 10 (Kernel 6.12) | — | Support planned until ~2035 | — |

---

## Default account settings

```bash
# Create home directory (-m) and default shell (/bin/bash)
useradd -m -s /bin/bash j2

# Set password
passwd j2

# Grant sudo privileges
usermod -aG wheel j2

# Change default WSL user
vim /etc/wsl.conf

# Add this:
[user]
default=j2

# Restart WSL from PowerShell:
wsl --shutdown
wsl -d RockyLinux
```

---

## Install development tools

```bash
# Update system
sudo dnf update -y

# Install Development Tools group
sudo dnf groupinstall -y "Development Tools"

# Additional packages for C++17+
sudo dnf install -y gcc-c++ cmake ninja-build git
```
