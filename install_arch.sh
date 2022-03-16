#!/bin/bash

continuar() {
	while true; do
		read -p "¿Continuar?" sn
		case $sn in
			[Ss]* ) break;;
			[Nn]* ) ;;
			* ) echo "Responde sí o no";;
		esac
	done
}

dispositivo() {
	echo "¿Qué dispositivo estás configurando?"
	select yn in "Rober-PC" "Mariola" "Rober-miniportátil" "Otro"; do
		case $yn in
			"Rober-PC" ) TARGET="Rober-PC"; break;;
			"Mariola" ) TARGET="Mariola"; break;;
			"Rober-miniportátil" ) TARGET="Rober-miniportátil"; break;;
			"Otro" ) TARGET="Otro" break;;
		esac
	done
}

wifi() {
	while ! ping -c 1 www.google.es; do
		read -p "¿Necesitas wifi?" sn
		case $sn in
			[Ss]* ) wifi-menu; break;;
			[Nn]* ) echo "No puede procederse sin conexión"; exit;;
			* ) echo "Responde sí o no";;
		esac
	done
}
	
# Sugerencia: Usar sfdisk para replicar setups anteriores.

echo "0 - Configuración previa"
dispositivo
wifi
timedatectl set-ntp true

echo "1 - Iniciando particionado"
echo "Por favor crea las siguientes particiones"
echo "Boot: /dev/sda1"
echo "Root: /dev/sda2"
continuar
cfdisk
fdisk -l
read -p "Introduce la unidad principal (p.e. 'sda')" sdx
mkfs.fat -F32 /dev/"$sdx"1
cryptsetup -y -v luksFormat /dev/"$sdx"2
cryptsetup config --label="Sistema" /dev/"$sdx"2
cryptsetup open /dev/"$sdx"2 root
mkfs.ext4 /dev/mapper/root

echo "2 - Instalando sistema base"
mount /dev/mapper/root /mnt
mkdir /mnt/boot
mount /dev/"$sdx"1 /mnt/boot

dd if=/dev/zero of=/mnt/swapfile bs=1M count=8192 status=progress
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

pacstrap /mnt base base-devel
pacstrap /mnt networkmanager
if [ "$TARGET" != "Rober-PC" ]; then
	pacstrap /mnt xf86-input-libinput
fi
if [ "$TARGET" = "Rober-miniportátil" ]; then
	pacstrap /mnt grub
fi
genfstab -U -p /mnt >> /mnt/etc/fstab


echo "3 - Configurando sistema base"
arch-chroot /mnt
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
	grub-install --target=i386-pc /dev/$sdx
	grub-mkconfig -o /boot/grub/grub.cfg
else
	bootctl install
	e2label /dev/"$sdx"2 "Sistema"
	
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
	
	pacman -S --needed --noconfirm intel-ucode
fi
mkinitcpio -p linux

