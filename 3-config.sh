if ! ping -c 1 www.github.com; then
	echo "No hay conexión, intenta conectar al Wi-Fi"
	echo "nmcli dev wifi connect SSID password CONTRASEÑA"
	exit
fi

if ! [ -f "$HOME/.ssh/id_rsa" ]; then
	echo "Para continuar, copia tus claves SSH desde otra sesión"
	echo "ssh-copy-id -i ~/.ssh/id_rsa rober@$(ip address | grep 192 | sed "s/\/.*//g" | sed "s/^.*192/192/g")"
	echo "ssh-copy-id -i ~/.ssh/id_rsa.pub rober@$(ip address | grep 192 | sed "s/\/.*//g" | sed "s/^.*192/192/g")"
	exit
fi

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
trizen -S --noconfirm --needed aerc dante w3m awk delta duf fzf htop lsd mpd mpc newsboat nano ncdu neofetch neovim neovim-symlinks openssh pandoc rsync svn texlive-core thefuck tldr tmux weechat weechat-matrix wget yt-dlp
systemctl enable --now sshd mpd

echo "Instalando aplicaciones esenciales"
trizen -S --noconfirm --needed nerd-fonts-hack numlockx systemd-numlockontty
# Fuentes asiáticas
trizen -S --noconfirm --needed noto-fonts-cjk
systemctl enable numLockOnTty 
# Repositorio oficial
trizen -S --noconfirm --needed cantata falkon firefox gimp keepassxc mpv nextcloud-client pavucontrol-qt qbittorrent streamlink telegram-desktop zim 
# Zim
trizen -S --noconfirm --needed zim gtkspell3 gtksourceview3 aspell
# Repositorio de usuarios
trizen -S --needed bar-protonmail crow-translate-git lagrange protonmail-bridge

if [ "$TARGET" != "miniportatil" ]; then
	# KDE Apps
	trizen -S --noconfirm --needed ark gvfs dolphin gwenview okular tellico
else
	# Alternativas ligeras
	trizen -S --noconfirm --needed lxqt-archiver gvfs pcmanfm-qt feh zathura
fi

# Wifi-UMA
if [ "$TARGET" != "pc" ]; then
	trizen -S --noconfirm --needed python-distro network-manager-applet
fi

echo "Instalando sway"
trizen -S --noconfirm --needed  alacritty sway waybar grimshot wl-clipboard wf-recorder mako xdg-desktop-portal-wlr qt6-wayland
# Repositorio de usuarios
trizen -S --noconfirm --needed wlsunset
if [ "$TARGET" == "miniportatil" ]; then
	# El miniportátil necesita un driver diferente (temporalmente)
	# https://gitlab.freedesktop.org/wlroots/wlroots/-/issues/2506
	# https://gitlab.freedesktop.org/mesa/mesa/-/issues/5418
	# TODO: Actualizar versión en importar las claves necesarias
	trizen -S --needed mesa-i915
fi

echo "Instalando ZSH"
trizen -S --noconfirm --needed zsh zsh-autosuggestions fzf zsh-syntax-highlighting zsh-theme-powerlevel10k
# Repositorio de usuarios
trizen -S --needed oh-my-zsh-git

echo "Descargando y aplicando configuración"

cd ~/Documentos
git clone git@github.com:Roboron3042/dotfiles.git
cd dotfiles
./deploy.sh

chsh -s /bin/zsh rober

systemctl enable --now --user mpd
vdirsyncer discover calendario
vdirsyncer discover contactos

# Neovim
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Aplicar estilos cyberpunk-neon por primera vez
cd ~/Documentos
git clone git@github.com:Roboron3042/Cyberpunk-Neon.git
cd Cyberpunk-Neon/gtk
tar xzf theme-cyberpunk-neon.zip -C ~/.local/share/themes/
gsettings set org.gnome.desktop.interface gtk-theme "materia-cyberpunk-neon"

# Weechat
mkdir -p ~/.local/share/weechat/python/autoload
ln -s /usr/share/weechat/python/weechat-matrix.py -t ~/.local/share/weechat/python/autoload
 
# Correo
echo "Inicia sesión en tu cuenta de Proton Mail para activar el indicador"
bar-protonmail auth
