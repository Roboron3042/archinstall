#!/bin/bash

continuar() {
	while true; do
		read -p "¿Continuar? (s/n)" sn
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
	echo $TARGET >> dispositivo
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
read -p "Introduce la unidad principal (p.e. 'sda'): " sdx
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

echo $TARGET >> dispositivo
cp * /mnt/temp/archinstall

arch-chroot /mnt "sh /tmp/archinstall/2-install.sh"


