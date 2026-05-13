#!/bin/bash

# Function to pause the script for troubleshooting
pause_step() {
    echo ""
    read -p "Step complete. Press [Enter] to continue to the next step..."
    echo "-------------------------------------------------------------"
}

# 1. Update the Operating System
echo "Step 1: Updating system packages and kernel..."
sudo dnf5 upgrade -y
pause_step

# 2. Enable RPM Fusion (Free and Non-Free)
echo "Step 2: Enabling RPM Fusion repositories..."
sudo dnf5 install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
pause_step

# 3. Enable 3rd Party Repositories (Chrome, VS Code, Cider, and Flathub)
echo "Step 3: Enabling 3rd party repositories..."
sudo dnf5 install -y fedora-workstation-repositories
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Refresh metadata
flatpak update --appstream
pause_step

# VS Code and Cider Repositories
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo rpm --import https://repo.cider.sh/RPM-GPG-KEY
sudo tee /etc/yum.repos.d/cider.repo << 'EOF'
[cidercollective]
name=Cider Collective Repository
baseurl=https://repo.cider.sh/rpm/RPMS
enabled=1
gpgcheck=1
gpgkey=https://repo.cider.sh/RPM-GPG-KEY
EOF
pause_step

# 4. Install NVIDIA Drivers and 32-bit Libraries
echo "Step 4: Installing NVIDIA drivers and kernel headers..."
sudo dnf5 install -y akmod-nvidia xorg-x11-drv-nvidia-cuda kernel-devel \
    xorg-x11-drv-nvidia-libs.i686 libva-nvidia-driver
pause_step

# 5. Install Applications and Gaming Compatibility Tools
echo "Step 5: Installing Applications (Gaming, Tools, 3D Printing)..."

# Enable COPR repositories for Gaming
sudo dnf5 copr enable wehagy/protonplus -y

# Force refresh metadata
sudo dnf5 clean all
sudo dnf5 makecache

# DNF applications (Native)
sudo dnf5 install -y gnome-system-monitor backintime-qt timeshift fastfetch steam lutris Cider google-chrome-stable code \
    cmatrix plasma-systemmonitor protonplus git \
    pkgconf-pkg-config \
    --enablerepo=google-chrome --refresh --best --allowerasing --skip-unavailable
    
# Flatpak applications
flatpak install flathub com.spotify.Client -y
flatpak install flathub com.heroicgameslauncher.hgl -y
flatpak install flathub com.bambulab.BambuStudio -y

# Verification Logic
echo ""
echo "Verifying Installations..."
echo "-------------------------------------------------------------"
APPS_DNF=("gnome-system-monitor" "backintime-qt" "timeshift" "fastfetch" "steam" "lutris" "Cider" "google-chrome-stable" "code" "plasma-systemmonitor" "protonplus" "git")
APPS_FLAT=("com.spotify.Client" "com.heroicgameslauncher.hgl" "com.bambulab.BambuStudio")

for app in "${APPS_DNF[@]}"; do
    if rpm -q "$app" >/dev/null 2>&1; then
        echo "[ OK ] Native: $app"
    else
        echo "[FAIL] Native: $app"
    fi
done

for app in "${APPS_FLAT[@]}"; do
    if flatpak list --app | grep -q "$app"; then
        echo "[ OK ] Flatpak: $app"
    else
        echo "[FAIL] Flatpak: $app"
    fi
done
pause_step

# 6. Multimedia Codecs
echo "Step 6: Installing multimedia codecs..."
sudo dnf5 install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
sudo dnf5 install -y lame\* --exclude=lame-devel
sudo dnf5 group install -y "sound-and-video"
pause_step

# 7. Gaming Optimization Tools
echo "Step 7: Installing Gaming Optimization Tools..."
sudo dnf5 install -y gamemode mangohud goverlay \
    gamemode.i686 mangohud.i686
pause_step

# 8. Enable GameMode daemon
echo "Step 8: Enabling GameMode daemon..."
systemctl --user enable --now gamemoded
pause_step

# 9. Mount Backup share from NAS (Secure Prompt)
echo "--- NAS Automount Setup Script ---"

# Configuration
NAS_IP="192.168.5.72"
NAS_SHARE="backup"
MOUNT_POINT="/backup"
CRED_FILE="/etc/nas-credentials"

# 1. Install dependencies
echo "[1/5] Installing cifs-utils..."
sudo dnf5 install -y cifs-utils

# 2. Prompt for credentials instead of hardcoding
echo "Please enter your NAS credentials:"
read -p "Username: " SMB_USER
read -sp "Password: " SMB_PASS
echo "" # Clean newline after hidden input

# 3. Create Mount Point
echo "[2/5] Creating mount point at $MOUNT_POINT..."
sudo mkdir -p "$MOUNT_POINT"

# 4. Create Credentials File
echo "[3/5] Creating secure credentials file..."
sudo bash -c "cat << EOF > $CRED_FILE
username=$SMB_USER
password=$SMB_PASS
EOF"
sudo chmod 600 "$CRED_FILE"

# 5. Update /etc/fstab
echo "[4/5] Updating /etc/fstab..."
FSTAB_ENTRY="//$NAS_IP/$NAS_SHARE $MOUNT_POINT cifs credentials=$CRED_FILE,iocharset=utf8,x-systemd.automount,_netdev,uid=1000,gid=1000 0 0"

if grep -qs "$MOUNT_POINT" /etc/fstab; then
    echo "Entry for $MOUNT_POINT already exists in /etc/fstab. Skipping."
else
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null

    # 6. Mount Share
    sudo systemctl daemon-reload
    sudo mount -a
fi
pause_step

echo "--------------------------------------------------------"
echo "Setup Complete!"
echo "--------------------------------------------------------"
echo "CHECKING NVIDIA BUILD STATUS..."
if modinfo -F version nvidia > /dev/null 2>&1; then
    echo "SUCCESS: NVIDIA driver version $(modinfo -F version nvidia) is ready."
    echo "You are safe to reboot!"
else
    echo "WAIT: The NVIDIA driver is still compiling (akmods) in the background."
    echo "Please wait 2-5 minutes, then run 'modinfo -F version nvidia' again."
fi
echo "--------------------------------------------------------"