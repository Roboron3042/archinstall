
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
if [ "$TARGET" = "Rober-miniportátil" ]; then
	grub-install --target=i386-pc /dev/sda
	grub-mkconfig -o /boot/grub/grub.cfg
else
	bootctl install
	
	rm /boot/loader/entries/arch.conf
	echo "title     Arch Linux" >> /boot/loader/entries/arch.conf
	echo "linux     /vmlinuz-linux" >> /boot/loader/entries/arch.conf
	echo "initrd    /initramfs-linux.img" >> /boot/loader/entries/arch.conf
	#configurar para amd si algún día tenemos uno...
	echo "initrd    /intel-ucode.img" >> /boot/loader/entries/arch.conf
	echo "options   root=LABEL=Sistema rw" >> /boot/loader/entries/arch.conf
	echo "cryptdevice=LABEL=Sistema:root root=/dev/mapper/root" >> /boot/loader/entries/arch.conf
	#si usamos NVIDIA
	#echo "options   nvidia-drm.modeset=1" >> /boot/loader/entries/arch.conf
	
	sudo sed "s/HOOKS.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)/g" /etc/mkinitcpio.conf
	
	rm /boot/loader/loader.conf
	echo "default arch" >> /boot/loader/loader.conf
	echo "timeout 0" >> /boot/loader/loader.conf
fi
mkinitcpio -p linux 

echo "---------------------------------------------------------"
echo "5 - Actualizando sistema e instalando paquetes esenciales"
echo "---------------------------------------------------------"
echo 'Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
echo 'Server = https://mirror.cloroformo.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
echo 'Server = https://mirror.librelabucm.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
pacman -Syu --noconfirm --needed pipewire pipewire-pulse pipewire-alsa pipewire-jack pipewire-media-session gst-plugin-pipewire pacman-contrib git mesa

if [ "$TARGET" != "Rober-miniportátil" ]; then
	pacman -S --needed --noconfirm intel-ucode
fi
if [ "$TARGET" != "Rober-pc" ]; then
	pacman -S --needed --noconfirm xf86-video-intel vulkan-intel
else

echo "Instalación base completada." 
echo "Para continuar al paso 3, reinicia y ejecuta /archinstall/3-config.sh para continuar"
exit