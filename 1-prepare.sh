#!/bin/bash

continuar() {
	while true; do
		read -p "¿Continuar? (s/n) " sn
		case $sn in
			[Ss]* ) break;;
			[Nn]* ) exit;;
			* ) echo "Responde sí o no";;
		esac
	done
}

dispositivo() {
	echo "¿Qué dispositivo estás configurando?"
	select yn in "pc" "portatil" "miniportatil" "nomada" "otro"; do
		case $yn in
			"pc" ) TARGET="pc"; break;;
			"portatil" ) TARGET="portatil"; break;;
			"miniportatil" ) TARGET="miniportatil"; break;;
			"nomada" ) TARGET="nomada"; break;;
			"otro" ) TARGET="otro" break;;
		esac
	done
	echo $TARGET >> dispositivo
}

wifi() {
	if ! ping -c 1 www.github.com; then
		echo "No hay conexión, intenta conectar al Wi-Fi"
		echo "Lista de comandos necesarios:"
		echo "iwctl device list"
		echo "iwctl station DISPOSITIVO scan"
		echo "iwctl station DISPOSITIVO get-networks"
		echo "iwctl station DISPOSITIVO connect SSID"
		exit
	fi
}
	

echo "------------------------"
echo "0 - Configuración previa"
echo "------------------------"
set -e
wifi
dispositivo
timedatectl set-ntp true

# Sugerencia: Usar sfdisk para replicar setups anteriores.

echo "--------------------------"
echo "1 - Iniciando particionado"
echo "--------------------------"
fdisk -l
read -p "Introduce la unidad principal (p.e. 'sda'): " DISCO
echo "Por favor crea las siguientes particiones: boot, root"
if ! cfdisk "/dev/$DISCO"; then
	exit
fi

fdisk -l "/dev/$DISCO"
read -p "Introduce la particion de boot (p.e. 'sda1'): " BOOT
read -p "Introduce la particion de root (p.e. 'sda2'): " ROOT
mkfs.fat -F32 /dev/"$BOOT"
cryptsetup -y -v luksFormat /dev/"$ROOT"
cryptsetup config --label="Sistema" /dev/"$ROOT"
cryptsetup open /dev/"$ROOT" newroot
mkfs.ext4 /dev/mapper/newroot

echo "---------------------------"
echo "2 - Instalando sistema base"
echo "---------------------------"
mount /dev/mapper/newroot /mnt
mkdir /mnt/boot
mount /dev/"$BOOT" /mnt/boot

if [ "$TARGET" != "pc" ]; then
	dd if=/dev/zero of=/mnt/swapfile bs=1M count=8192 status=progress
	chmod 600 /mnt/swapfile
	mkswap /mnt/swapfile
	swapon /mnt/swapfile
fi

# TODO: Usar iwd con networkmanager esté listo
# https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/922
pacstrap /mnt base base-devel linux linux-firmware networkmanager
if [ "$TARGET" != "pc" ]; then
	pacstrap /mnt xf86-input-libinput
fi
if [ "$TARGET" == "miniportatil" ]; then
	pacstrap /mnt grub
fi
genfstab -U -p /mnt >> /mnt/etc/fstab
echo "tmpfs   /tmp         tmpfs   rw,nodev,nosuid,size=4G          0  0" >> /mnt/etc/fstab

cp -r ../archinstall /mnt

echo "Preparación del sistema finalizada"
echo "Para continuar al paso 2, ejecuta: /archinstall/2-install.sh"
arch-chroot /mnt
