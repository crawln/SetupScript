# Fedora Ultimate Post-Install & NVIDIA Setup

This repository contains a robust Bash script designed to automate the configuration of a fresh Fedora installation. It focuses on setting up NVIDIA drivers, gaming tools, essential software, and mounting network storage.

## 🚀 Overview

The `setup_nvidia.sh` script automates the following nine steps:
1.  **System Update:** Upgrades all packages and the kernel using `dnf5`.
2.  **RPM Fusion:** Enables Free and Non-Free repositories for proprietary drivers and codecs.
3.  **Third-Party Repos:** Configures Flathub, Google Chrome, VS Code, and Cider repositories.
4.  **NVIDIA Drivers:** Installs `akmod-nvidia`, CUDA support, and 32-bit libraries for gaming.
5.  **Software Suite:** Installs a curated list of applications via DNF and Flatpak, including Steam, Lutris, BambuStudio, and Spotify.
6.  **Multimedia Codecs:** Installs essential audio/video codecs and plugins.
7.  **Gaming Optimization:** Installs and enables `GameMode`, `MangoHud`, and `Goverlay`.
8.  **Service Configuration:** Starts the GameMode daemon for immediate use.
9.  **NAS Integration:** Securely mounts a CIFS/SMB share from a NAS to `/backup` with auto-mount configuration.

## 📋 Prerequisites

-   **OS:** Fedora Workstation (designed for versions utilizing `dnf5`).
-   **Hardware:** NVIDIA GPU (for driver installation).
-   **Network:** Active internet connection and access to your NAS (if using Step 9).
-   **Permissions:** Sudo privileges are required.

## 🛠️ Usage

1.  **Clone or Download** the script to your local machine.
2.  **Make the script executable:**
    ```bash
    chmod +x setup_nvidia.sh
    ```
3.  **Run the script:**
    ```bash
    ./setup_nvidia.sh
    ```

## 📦 Installed Applications

### Native (DNF)
- **Utilities:** `fastfetch`, `git`, `timeshift`, `backintime-qt`, `gnome-system-monitor`
- **Gaming:** `steam`, `lutris`, `protonplus`, `gamemode`, `mangohud`
- **Productivity/Web:** `google-chrome-stable`, `code` (VS Code), `Cider`

### Flatpak
- **Entertainment:** Spotify
- **Gaming:** Heroic Games Launcher
- **3D Printing:** BambuStudio

## 🔐 NAS Setup Details
The script will prompt you for your NAS username and password. 
- It creates a secure credentials file at `/etc/nas-credentials` with `600` permissions.
- It adds an entry to `/etc/fstab` using `x-systemd.automount` to ensure the share is available whenever accessed.

## ⚠️ Important Note on NVIDIA Drivers
At the end of the script, a verification check runs. If the script reports that the driver is still "compiling," **do not reboot immediately**. Fedora uses `akmods` to build the NVIDIA kernel module locally. Please wait 2–5 minutes and run the following command to verify readiness:
```bash
modinfo -F version nvidia
