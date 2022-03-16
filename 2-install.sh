echo "3 - Configurando sistema base"
TARGET=$(cat /tmp/archinstall/dispositivo)
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

echo "4 - Configurando gestor de inicio"
if [ "$TARGET" != "Rober-miniportátil" ]; then
	grub-install --target=i386-pc /dev/sda
	grub-mkconfig -o /boot/grub/grub.cfg
else
	bootctl install
	
	echo "title     Arch Linux" >> /boot/loader/entries/arch.conf
	echo "linux     /vmlinuz-linux" >> /boot/loader/entries/arch.conf
	echo "initrd    /initramfs-linux.img" >> /boot/loader/entries/arch.conf
	#configurar para amd si algún día tenemos uno...
	echo "initrd    /intel-ucode.img" >> /boot/loader/entries/arch.conf
	echo "options   root=LABEL=Sistema rw" >> /boot/loader/entries/arch.conf
	echo "cryptdevice=UUID=device-UUID:root root=/dev/mapper/root" >> /boot/loader/entries/arch.conf
	#si usamos NVIDIA
	#echo "options   nvidia-drm.modeset=1" >> /boot/loader/entries/arch.conf
	
	sudo sed "s/HOOKS.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)/g" /etc/mkinitcpio.conf
	
	rm /boot/loader/loader.conf
	cat "default arch" >> /boot/loader/loader.conf
	cat "timeout 0" >> /boot/loader/loader.conf
	
	pacman -Sy --needed --noconfirm intel-ucode
fi
mkinitcpio -p linux 
exit
