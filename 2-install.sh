
TARGET=$(cat /archinstall/dispositivo)

echo "-----------------------------"
echo "3 - Configurando sistema base"
echo "-----------------------------"
echo "$TARGET" >> /etc/hostname
ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc
echo "LANG=es_ES.UTF-8" >> /etc/locale.conf
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "KEYMAP=es" >> /etc/vconsole.conf
echo "Escribe la contraseña de administración"
passwd

echo "---------------------------------"
echo "4 - Configurando gestor de inicio"
echo "---------------------------------"
if [ "$TARGET" = "Miniportatil" ]; then
	grub-install --target=i386-pc /dev/sda
	sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=LABEL=Sistema:root root=\/dev\/mapper\/root quiet"/g' /etc/default/grub
	grub-mkconfig -o /boot/grub/grub.cfg
else
	bootctl install
	
	echo "title     Arch Linux" >> /boot/loader/entries/arch.conf
	echo "linux     /vmlinuz-linux" >> /boot/loader/entries/arch.conf
	echo "initrd    /initramfs-linux.img" >> /boot/loader/entries/arch.conf
	#configurar para amd si algún día tenemos uno...
	echo "initrd    /intel-ucode.img" >> /boot/loader/entries/arch.conf
	echo "options   root=LABEL=Sistema rw" >> /boot/loader/entries/arch.conf
	echo "cryptdevice=LABEL=Sistema:root root=/dev/mapper/root" >> /boot/loader/entries/arch.conf
	#si usamos NVIDIA
	#echo "options   nvidia-drm.modeset=1" >> /boot/loader/entries/arch.conf
	
	echo "default arch" >> /boot/loader/loader.conf
	echo "timeout 0" >> /boot/loader/loader.conf
fi
sed -i "s/HOOKS.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)/g" /etc/mkinitcpio.conf
mkinitcpio -p linux 

echo "---------------------------------------------------------"
echo "5 - Actualizando sistema e instalando paquetes esenciales"
echo "---------------------------------------------------------"
echo 'Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
echo 'Server = https://mirror.cloroformo.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
echo 'Server = https://mirror.librelabucm.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
pacman -Syu --noconfirm --needed pipewire pipewire-pulse pipewire-alsa pipewire-jack pipewire-media-session gst-plugin-pipewire pacman-contrib mesa intel-ucode git

if [ "$TARGET" != "PC" ]; then
	pacman -S --needed --noconfirm xf86-video-intel vulkan-intel
fi

echo "Instalación base completada." 
echo "Para continuar al paso 3, reinicia y ejecuta /archinstall/3-config.sh"
exit
