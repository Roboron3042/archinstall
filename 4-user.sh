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
gsettings set org.gnome.desktop.interface gtk-theme "materia-cyberpunk-neon"
cd ~/Documentos
git clone git@github.com:Roboron3042/Cyberpunk-Neon.git
cd Cyberpunk-Neon/icons

#Weechat
mkdir -p ~/.local/share/weechat/python/autoload
ln -s /usr/share/weechat/python/weechat-matrix.py -t ~/.local/share/weechat/python/autoload
