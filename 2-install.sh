
TARGET=$(cat /archinstall/dispositivo)
set -e

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
if [ "$TARGET" = "miniportatil" ]; then
	grub-install --target=i386-pc /dev/sda
	sed -i 's/GRUB_TIMEOUT=./GRUB_TIMEOUT=0/g' /etc/default/grub
	sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=LABEL=Sistema:root root=\/dev\/mapper\/root quiet"/g' /etc/default/grub
	grub-mkconfig -o /boot/grub/grub.cfg
else
	bootctl install
	
	echo "title     Arch Linux" >> /boot/loader/entries/arch.conf
	echo "linux     /vmlinuz-linux" >> /boot/loader/entries/arch.conf
	echo "initrd    /initramfs-linux.img" >> /boot/loader/entries/arch.conf
	if [ "$TARGET" == "pc" ]; then
		echo "initrd    /amd-ucode.img" >> /boot/loader/entries/arch.conf
	else
		echo "initrd    /intel-ucode.img" >> /boot/loader/entries/arch.conf
	fi
	echo "options cryptdevice=LABEL=Sistema:root root=/dev/mapper/root quiet rw" >> /boot/loader/entries/arch.conf
	if [ "$TARGET" == "nomada"]; then
		echo "options   nvidia-drm.modeset=1" >> /boot/loader/entries/arch.conf
	fi
	echo "default arch" >> /boot/loader/loader.conf
	echo "timeout 0" >> /boot/loader/loader.conf
fi

if [ "$TARGET" == "nomada" ]; then
	sed -i "s/HOOKS.*/HOOKS=(base udev keyboard block autodetect keymap modconf encrypt filesystems fsck)/g" /etc/mkinitcpio.conf
else
	sed -i "s/HOOKS.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/g" /etc/mkinitcpio.conf
fi
mkinitcpio -p linux 

echo "---------------------------------------------------------"
echo "5 - Actualizando sistema e instalando paquetes esenciales"
echo "---------------------------------------------------------"

echo 'Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
echo 'Server = https://mirror.cloroformo.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
echo 'Server = https://mirror.librelabucm.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

# Habilita multilib (para Steam)
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

pacman -Syu --noconfirm --needed pipewire pipewire-pulse pipewire-alsa pipewire-jack pipewire-media-session gst-plugin-pipewire pacman-contrib mesa mesa-vdpau libva-mesa-driver git

if [ "$TARGET" == "pc" ]; then
	pacman -S --needed --noconfirm vulkan-radeon vulkan-mesa-layers amd-ucode
else
	pacman -S --needed --noconfirm vulkan-intel intel-ucode
fi

echo "Creando usuario rober"
useradd -m -g users -G audio,lp,optical,storage,video,wheel,games,power,scanner -s /bin/bash rober
passwd rober
sed -i "s/# %wheel ALL=(ALL:ALL) NOPASSWD/%wheel ALL=(ALL:ALL) NOPASSWD/" /etc/sudoers
pacman -S --needed --noconfirm xdg-user-dirs openssh ntp
systemctl enable NetworkManager sshd ntpd
xdg-user-dirs-update
# ntpd Arregla la hora tras volver de la suspensión
# Por si hacemos dual-boot con Windows
timedatectl set-local-rtc 1 --adjust-system-clock

if [ "$TARGET" == "nomada" ]; then
	# Ajusta la ventilación de CPU (¿Solo Intel?)
	pacman -S --needed --noconfirm thermald
	systemctl enable thermald
fi

echo "Instalación base completada." 
echo "Para continuar al paso 3, reinicia, inicia sesión con rober y ejecuta /archinstall/3-config.sh"
exit
