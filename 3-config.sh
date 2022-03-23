systemctl enable --now dhcpcd
systemctl enable --now NetworkManager
if ! ping -c 1 www.github.com; then
	echo "No hay conexión, intenta conectar al Wi-Fi"
	echo "nmcli dev wifi connect SSID password CONTRASEÑA"
	exit
fi

echo "Creando usuario rober"
useradd -m -g users -G audio,lp,optical,storage,video,wheel,games,power,scanner -s /bin/bash rober
passwd rober
pacman -S --needed --noconfirm xdg-user-dirs
xdg-user-dirs-update

sed -i "s/# %wheel ALL=(ALL:ALL) NOPASSWD/%wheel ALL=(ALL:ALL) NOPASSWD/"

echo "Instalando trizen"
cd temp
git clone https://aur.archlinux.org/trizen.git
cd trizen
makepkg -si --noconfirm

echo "Instalando herramientas de CLI"

# Keyring
trizen -S --noconfirm --needed libsecret seahorse libgnome-keyring
# Calendario y contactos
trizen -S --noconfirm --needed khard khal vdirsyncer
# Otros
trizen -S --noconfirm --needed aerc awk delta duf fzf htop lsd mpd mpc newsboat openssh nano ncdu neofetch neovim neovim-symlinks pandoc rsync svn texlive-core tldr tmux weechat yt-dlp
systemctl enable --now sshd mpd

echo "Instalando aplicaciones esenciales"
trizen -S --noconfirm --needed nerd-fonts-hack numlockx systemd-numlockontty
systemctl enable numLockOnTty 
# Repositorio oficial
trizen -S --noconfirm --needed cantata firefox gimp keepassxc mpv nextcloud-client pavucontrol-qt qbittorrent streamlink telegram-desktop zim 
# Zim
trizen -S --noconfirm --needed zim gtkspell3 gtksourceview3 aspell
# Repositorio de usuarios
trizen -S --noconfirm --needed crow-translate-git

if [ "$TARGET" != "Miniportatil" ]; then
	# KDE Apps
	trizen -S --noconfirm --needed ark gvfs dolphin gwenview okular tellico
else
	# Alternativas ligeras
	trizen -S --noconfirm --needed lxqt-archiver gvfs pcmanfm-qt feh zathura
fi

# Wifi-UMA
if [ "$TARGET" != "PC" ]; then
	trizen -S --noconfirm --needed python-distro
fi

echo "Instalando sway"
trizen -S --noconfirm --needed  sway waybar grimshot wl-clipboard wf-recorder mako xdg-desktop-portal-wlr
# Repositorio de usuarios
trizen -S --noconfirm --needed wlsunset

echo "Instalando ZSH"
trizen -S --noconfirm --needed zsh zsh-autosuggestions fzf zsh-syntax-highlighting zsh-theme-powerlevel10k
# Repositorio de usuarios
trizen -S --needed zsh oh-my-zsh-git 

echo "Instalación lista. Para terminar de configurar tu usuario:"
echo "1. Copia tus claves SSH desde otra sesión"
echo "   ssh-copy-id -i ~/.ssh/id_rsa rober@$(ip address | grep 192 | sed "s/\/.*//g" | sed "s/^.*192/192/g")"
echo "2. Inicia sesión"
echo "3. Ejecuta /archinstall/4-user.sh"
