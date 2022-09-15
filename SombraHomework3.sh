#!/bin/bash

MAKE_PATH=/etc/portage/make.conf
FSTAB=/etc/fstab
KEYMAPS=/etc/conf.d/keymaps

core_install(){

	echo "подготовка к настройки ядра"
	emerge --ask sys-kernel/gentoo-sources
	emerge --ask sys-kernel/genkernel

	sed -i "s/LABEL=boot	\/boot	ext4	noauto,noatime	1 2/LABEL=boot	\/boot	ext4	defaults	0 2/g" /etc/fstab
	
	echo "настройка ядра"
	genkernel all

	ls /boot/vmlinu* /boot/initramfs*
	echo "hostname='Sombra'"> /etc/conf.d/hostname

	emerge -q networkmanager
	rc-update add networkmanager boot

	emerge sys-fs/dosfstools
	emerge sys-fs/btrfs-progs
	emerge sys-fs/e2fsprogs

}

error_exit(){
	
	#echo "обработка ошибок"
	echo "Error: $1"
	exit 1

}

installer(){

	echo "настройка загузчика"
	echo "/dev/sda1		/boot		ntfs	defaults, noatime 0 2" >>$FSTAB
	echo "/dev/sda2		/		ext4	noatime 	  0 0" >>$FSTAB
	echo "/dev/cdrom	/mnt/cdrom	auto	noauto,user	  0 0" >>$FSTAB


	echo  'GRUB_PLATFORMS="pc"' >> $MAKE_PATH

	emerge --ask sys-boot/grub:2
	emerge --ask --update --newuse --verbose sys-boot/grub:2
	grub-install /dev/sda
	grub-install --target=x86_64-efi --efi-directory=/boot 

	grub-mkconfig -o /boot/grub/grub.cfg

	exit
	cd

	umount -l /mnt/gentoo/dev{/shm,/pts,}
	umount -R /mnt/gentoo

	echo "keymap='us'" >> $KEYMAPS
	echo "windowkeys='YES'" >> $KEYMAPS
	echo "extended_keymaps=''" >> $KEYMAPS
	echo "dumpkeys_charset=''" >> $KEYMAPS

	emerge --ask --app-admin/sysklogd
	rc-update add sysklogd default
	emerge --ask sys-fs/e2fsprogs


	poweroff

}

	core_install || error_exit "core error"
	installer || error_exit "installer error"
