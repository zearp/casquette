# Casquette
![logo](https://github.com/zearp/casquette/assets/63272687/db2c3091-b286-4f00-b087-302f235f3ae7)

My spin on Fedora Linux. Nothing fancy. Bare bones with only the things I need and want. The aim of this repo is to have my stuff easily available to myself and anyone interested. It is essentially a kickstart file that can be modified to suit your needs and build an iso with. Compared to a normal Fedora Linux dark mode is enabled by default, third party repo's been added and a different (minimal) selection of packages is used. Kickstarts are a great way to customise Fedora Linux. The iso can be installed without an active internet connection.
<details>
  <summary>Packages:</summary>
  
  - GUI Stuff:
    - Cockpit, manage stuff (remotely) from your browser
    - Eye of Gnome image viewer
    - Evince document viewer
    - Flatseal to manage Flatpak permissions
    - gedit, simple text editor
    - Gnome disk utility
    - Gnome font vieuwer
    - Gnome schreenshot tool
    - Gnome software centre
    - Gnome system monitor
    - Gnome terminal
    - Gnome tweaks
    - Nautilus file manager
    - Plymouth spinner boot theme
  - Shell utils:
    - bat 🦀
    - btop
    - eza 🦀
    - grubby
    - htop
    - nano
    - nvme-cli
    - pciutils
    - pfetch 🦀
    - usbutils
    - ripgrep 🦀
    - rsync
    - wget
    - zsh
    - and many others!
  - Extra repo's:
    - RPM Fusion
    - Flatpaks via the Gnome software centre

</details>

#### Contents:
* [Installation](#installation)
* [Post install](#post-install)
* [Updating](#updating)

### Installation
1. Disable SELinux:
   ```sh
   sudo setenforce 0
   ```
2. Install required packages:
   ```sh
   sudo dnf -y --refresh update && sudo dnf -y install mock mock-rpmfusion-free mock-rpmfusion-nonfree
   ```
3. Add yourself to the mock group and logout:
   ```sh
   sudo usermod -a -G mock $USER && exit
   ```
4. Log back in and create ```/etc/mock/casquette.cfg``` and paste in the following:
   ```sh
   include('fedora-40-x86_64-rpmfusion_nonfree.cfg')
   config_opts['root'] = "casquette-40-{{ target_arch }}"
   config_opts['description'] = 'Casquette 40'
   ```
5. Initialise and enter the mock environment:
   ```sh
   mock -r casquette --init --nobest
   mock -r casquette --install lorax-lmc-novirt nano pykickstart git
   mock -r casquette --shell --isolation=simple --enable-network
   ```
   <sup>The --nobest option is not strickly needed, just sometimes its fails to initialise and this option prevents/fixes it.</sup>
   
6. From inside the mock enviroment download the kickstart file and edit, then flatten it:
   ```sh
   git clone https://github.com/zearp/casquette && cd casquette/kickstart
   nano casquette.ks && ksflatten -c casquette.ks -o flat.ks
   ```
7. Generate the iso with the following command:
   ```sh
   livemedia-creator --ks flat.ks --no-virt --resultdir /var/lmc --project="Casquette" --make-iso \
   --volid Casquette-40 --iso-only --iso-name Casquette-40-x86_64.iso --releasever=40 --macboot && exit
   ```
8. When it's done we'll move the iso file to the current directory and clean up:
   ```sh
   sudo mv /var/lib/mock/casquette-40-x86_64/root/var/lmc/Casquette-40-x86_64.iso .
   sudo chown $USER:$USER Casquette-40-x86_64.iso
   mock -r casquette --scrub=all
   ```
9. Re-enable SELinux:
   ```sh
   sudo setenforce 1
   ```
That's all, you can now use the iso file to install.

# Post install
Some (hopefully) useful post install stuff.

### Remove left overs.
```
sudo dnf -y remove anaconda\*
sudo dnf clean all
```
Optionally if you just want to use ```dnf``` remove flatpak, flatseal and gnome-software.
```
sudo dnf -y remove flatpak\* flatseal gnome-software
```
On AMD iGPU/GPU systems the Intel driver can be removed too:
```
sudo dnf -y remove intel-media-driver
```

### Verify SELinux
Security is paramount so let's make sure SELinux is running in ```enforcement``` mode. run the following command to check the current enforcement status:
```
sudo getenforce
```
If it shows ```Enforcing``` we don't need to do anything. If it shows ```Permissive``` run the following command, reboot and check the enforcement status again:
```
sudo fixfiles onboot
```
For more information please refer to [this](https://docs.rockylinux.org/guides/security/learning_selinux) page.

### Check for and install firmware updates
Run these commands one by one and only update if you want to. If everything is workign fine it might not be needed to update anything. Refer to the release notes and change logs for each firmware update.
```
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
## make sure you need/want these updates!
sudo fwupdmgr update
```
### Cockpit
Cockpit is a nice web frontend to do basic monitoring and managements tasks. I suggest using it not only on servers but anywhere and also when you need to troubleshoot issues. It has some great utilities and access to log files and services and so on. The default location is ```http://localhost:9090```. For more information please read [this](https://www.redhat.com/sysadmin/intro-cockpit) page.

### Firefox
For hardware encoding set ```media.ffmpeg.vaapi.enabled``` and ```gfx.webrender.all``` to true in ```about:config``` and restart Firefox. To test check cpu/gpu usage in ```nvtop``` or ```intel_gpu_top```.

It is recommended to block unsupported codecs using [this](https://addons.mozilla.org/en-US/firefox/addon/enhanced-h264ify) add-on. For example, my NUC 8 does not support AV1 but does support VP8/9 and h264. Setting the add-on to only block AV1 tries to makes it so videos are being decoded by the gpu. To see which codecs are supported you can use the ```vainfo``` command.

You will see entries like ```VAProfileH264``` and so on. Disable any you don't have but are listed in the ```enhanced-h264ify``` add-on. This way Firefox won't be rendering videos ususing the cpu (as much). If you run into a video that doesn't play disabling the add-on and refreshing the page should fix it and let Firefox use the cpu to render the video.

While we're at it let's install [uBlock Origin](https://addons.mozilla.org/en-GB/firefox/addon/ublock-origin) to block some ads and trackers.

### Misc.
- Change shell to zsh:
  ```sh
  sudo usermod --shell /usr/bin/zsh $USER
  ```
- Less flickering when booting and old school network interface names:
  ```sh
  grubby --update-kernel=ALL --args="loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 biosdevname=0 net.ifnames=0"
  ```
- Sort apps alphabetically, logout and in to apply, don't use sudo here:
  ```sh
  gsettings set org.gnome.shell app-picker-layout "[]"
  ```
- Sync login screen settings (gdm):
  ```sh
  sudo cp ~/.config/monitors.xml /var/lib/gdm/.config/
  ```
- Remove brightness slider (when applicable):
  ```sh
  sudo grubby --update-kernel ALL --args acpi_backlight=none
  ```
- Compiling kernel modules:
  ```sh
  sudo dnf -y install kernel-devel dkms
  ```
- Disable sleep/suspend completely, disable it in Gnome settings first or else you get false positive notifications about impending suspends. Re-run with ```unmask``` to re-enable:
  ```sh
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
  ```
- The firewall (```firewalld```) is enabled and allowing; cockpit and ssh. For some basics on opening ports/services and more information please refer to [this](https://docs.rockylinux.org/guides/security/firewalld-beginners) page.

# Updating
Easy mode!
```
sudo dnf --refresh update
```
