#!/bin/bash
echo "warning, designed for arch (or arch based) won't work on anything else"
mv config .config
echo "installing dependencies"
sudo pacman -Syu
sudo pacman -S --needed dracut kexec-tools git hyprland waypaper hyprpaper hyprlock swayosd waybar hypridle imagemagick yay-git fish nvim nwg-displays kitty rofi flatpak playerctl papirus-icon-theme cantarell-fonts
yay -Syu
yay -S librewolf-bin gtk bibata-cursor-theme
echo "installing ohmyposh"
mkdir ~/.local
mkdir ~/.local/bin
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/bin
echo "installing lazy vim"
mv ~/.config/nvim{,.bak}
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
echo "importing dotfiles for hyprland waypaper waybar ohmyposh nwg-displays kitty and fish"
mv "$HOME"/.config/hypr{,.bak}
mv "$HOME"/.config/waypaper{,.bak}
mv "$HOME"/.config/waybar{,.bak}
mv "$HOME"/.config/ohmyposh{,.bak}
mv "$HOME"/.config/nwg-displays{,.bak}
mv "$HOME"/.config/kitty{,.bak}
mv "$HOME"/.config/fish{,.bak}
# theres gotta be a better way to do this
cp background "$HOME"/background
cd .config
cp -R hypr waypaper waybar ohmyposh nwg-displays kitty fish "$HOME"/.config
echo "installing gtk theme"
cp -R gtk-3.0 gtk-4.0 "$HOME"/.config
cd ../.
echo "installing others (commands)"
cd others/
sudo cp arm disarm delete nosleep /usr/bin/
sudo chmod +x /usr/bin/arm
sudo chmod +x /usr/bin/disarm
sudo chmod +x /usr/bin/delete
sudo chmod +x /usr/bin/nosleep

# Prompt for user input
read -p "install micro sd udev rule? (Yy/Nn): " answer

# Convert the answer to lowercase to make it case-insensitive
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

# Check the answer
if [[ "$answer" == "y" ]]; then
  echo "installing udev rule"
  sudo mkdir -p /usr/lib/dracut/modules.d/99ramwipe
  sudo tee /usr/lib/dracut/modules.d/99ramwipe/module-setup.sh >/dev/null <<'EOF'
#!/bin/bash
check() { return 0; }
depends() { echo bash; }
install() {
  inst_multiple dd head tail grep awk sed cat sync poweroff mount uname
  inst_hook initqueue/finished 99 "$moddir/ramwipe.sh"
}
EOF
  sudo tee /usr/lib/dracut/modules.d/99ramwipe/ramwipe.sh >/dev/null <<'EOF'
#!/bin/bash
# Dracut runs this inside the kexec'd kernel initramfs.
echo "[ramwipe] starting…" >&2

# Drop caches repeatedly, then hog memory with dd to overwrite as much as possible.
# We avoid /dev/mem (restricted) and instead allocate userspace pages to force eviction.
for pass in 1 2; do
  echo "[ramwipe] pass $pass: allocating…" >&2
  # Allocate ~95% of RAM repeatedly in chunks and overwrite with zeros.
  total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  chunk_kb=$(( total_kb / 10 ))
  used=0
  while [ $used -lt $(( total_kb * 95 / 100 )) ]; do
    dd if=/dev/zero of=/dev/shm/wipe.$RANDOM bs=1024 count=$chunk_kb status=none || break
    used=$(( used + chunk_kb ))
  done
  sync
  echo 3 > /proc/sys/vm/drop_caches
  rm -f /dev/shm/wipe.*
done

echo "[ramwipe] done; powering off." >&2
poweroff -f
EOF
  sudo chmod +x /usr/lib/dracut/modules.d/99ramwipe/module-setup.sh
  sudo chmod +x /usr/lib/dracut/modules.d/99ramwipe/ramwipe.sh
  sudo dracut --force /boot/initramfs-ramwipe.img $(uname -r)
  sudo cp 99-microsd-removed.rules /etc/udev/rules.d/99-microsd-removed.rules
  sudo cp ramwipe-kexec-load.service /etc/systemd/system/ramwipe-kexec-load.service
  sudo cp sd-removed /usr/bin/sd-removed
  sudo chmod +x /usr/bin/sd-removed
  sudo systemctl daemon-reload
  sudo systemctl enable --now ramwipe-kexec-load.service
else
  echo "skipping udev rule"
fi
cd ../.
echo "installing SDDM theme, follow instructions"
git clone https://github.com/Keyitdev/sddm-astronaut-theme.git
cd sddm-astronaut-theme
./setup.sh
cd ../.
cp background "$HOME"/background
sudo cp /etc/fstab{,.bak}
sudo echo "UUID=3139-6135	/home/mitch/microsd	exfat	nofail,x-systemd.device-timeout=5s,uid=1000,gid=1000,umask=000	0 0" >>/etc/fstab
echo "finished, probably reboot"
