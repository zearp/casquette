firewall --enabled --service=mdns
keyboard 'us'
lang en_US.UTF-8
network  --bootproto=dhcp --device=link --activate
shutdown

repo --name="fedora" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name="fedora-updates" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch
repo --name="fedora-cisco-openh264" --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch
repo --name="rpmfusion-free" --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-$releasever&arch=$basearch
repo --name="rpmfusion-free-updates" --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch
repo --name="rpmfusion-nonfree" --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-$releasever&arch=$basearch
repo --name="rpmfusion-nonfree-updates" --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch

rootpw --iscrypted --lock locked
selinux --enforcing
services --disabled="sshd,ModemManager" --enabled="NetworkManager"
timezone Europe/Amsterdam
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch"
xconfig  --startxonboot
bootloader --location=none
zerombr
clearpart --all
part / --fstype="ext4" --size=8192

%post --nochroot
cp --remove-destination /etc/resolv.conf /mnt/sysimage/etc/resolv.conf
%end

# intel tweaks, remove enable_guc for 5th gen and older and set to 3 for 9th gen and newer
#
%post
echo "options i915 enable_guc=2 enable_fbc=1 fastboot=1" | tee /etc/modprobe.d/i915.conf
echo "dev.i915.perf_stream_paranoid = 0" | tee /etc/sysctl.d/98-i915.conf
%end

# setup darkmode and wallpaper
#
%post
mkdir -p /usr/share/backgrounds
wget -q -nc -4 --no-check-certificate https://raw.githubusercontent.com/zearp/casquette/main/assets/wallpaper.jpg -O /usr/share/backgrounds/casquette.jpg
chmod 644 /usr/share/backgrounds/casquette.jpg
cat > /etc/skel/.gtkrc-2.0 << EOF
include "/usr/share/themes/Adwaita-dark/gtk-2.0/gtkrc"
include "/etc/gtk-2.0/gtkrc"
gtk-theme-name="Adwaita-dark"
EOF
mkdir -p /etc/skel/.config/gtk-3.0
cat > /etc/skel/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name = Adwaita-dark
EOF
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/01-darkmode << EOF
[org/gnome/desktop/interface]
gtk-theme='Adwaita-dark'
color-scheme='prefer-dark'
EOF
cat > /etc/dconf/db/local.d/02-background << EOF
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/casquette.jpg'
picture-options='zoom'
EOF
dconf update
%end

# setup some misc stuff
#
%post
# sets the spinner theme, requires the plymouth-theme-spinner package
plymouth-set-default-theme spinner -R
# fixes flatseal not saving overrides properly
mkdir -p /etc/skel/.local/share/flatpak/overrides
# fix mpv not always using hardware encoding
mkdir -p /etc/skel/.config/mpv
echo "hwdec=auto" | tee /etc/skel/.config/mpv/mpv.conf
# fetch .zshrc
rm /etc/skel/.zshrc
wget -q -nc -4 --no-check-certificate https://raw.githubusercontent.com/zearp/casquette/main/assets/dot_zshrc -O /etc/skel/.zshrc
# fetch pfetch
wget -q -nc -4 --no-check-certificate https://raw.githubusercontent.com/zearp/casquette/main/assets/pfetch -O /usr/local/bin/pfetch
chmod 755 /usr/local/bin/pfetch
# some peace and quiet
touch /etc/skel/.hushlogin
echo "kernel.printk = 3 3 3 3" | tee /etc/sysctl.d/97-quiet-printk.conf
%end

%include include/fedora.ks

%post
systemctl disable NetworkManager-wait-online
systemctl enable --now acpid
#systemctl enable --now cockpit.socket
systemctl enable --now firewalld
systemctl enable --now fstrim.timer
systemctl enable --now sshd
systemctl enable --now thermald
systemctl enable --now tuned
tuned-adm profile desktop
%end

%post
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 
plymouth-set-default-theme spinner -R
dnf remove -y gnome-tour
%end

%post
dnf -y swap ffmpeg-free ffmpeg --allowerasing
dnf -y groupupdate multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf -y groupupdate sound-and-video
%end

%post
rm /etc/resolv.conf
%end

%packages
#@^minimal-environment -- seems to be removed from Fedora 41, can't find any info on it
@anaconda-tools
@fonts
@hardware-support
@multimedia
@networkmanager-submodules
@sound-and-video
@standard
aajohan-comfortaa-fonts
acpi
acpid
acpitool
anaconda
anaconda-install-env-deps
anaconda-live
#anaconda-webui
axel
bat
btop
#cockpit
dracut-live
#dconf
eog
epiphany
evince
eza
flatseal
gdm
glances
glibc-all-langpacks
gnome-browser-connector
gnome-clocks
gnome-disk-utility
gnome-extensions-app
gnome-firmware
gnome-initial-setup
gnome-keyring
gnome-session-wayland-session
gnome-shell-extension-blur-my-shell
gnome-shell-extension-caffeine
gnome-shell-extension-dash-to-dock
gnome-shell-extension-just-perfection
gnome-software
gnome-system-monitor
gnome-terminal
gnome-text-editor
gnome-tweaks
gnome-weather
grub2-efi-x64
grub2-efi-x64-cdboot
grub2-efi-x64-modules
grubby
htop
igt-gpu-tools
intel-media-driver
kernel
kernel-modules
kernel-modules-extra
libva-utils
livesys-scripts
mpv
nano
nautilus
nvme-cli
#nvtop
pciutils
plymouth
plymouth-theme-spinner
ripgrep
rsync
thermald
tuned
unzip
usbutils
wavemon
wget
zsh
zsh-autosuggestions
zsh-syntax-highlighting
-@dial-up
-@input-methods
-@standard
-device-mapper-multipath
-fcoe-utils
-gfs2-utils
-reiserfs-utils
-sdubby
%end
