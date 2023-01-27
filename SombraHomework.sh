#!/bin/bash


set -x

MAKE_PATH=/mnt/gentoo/etc/portage/make.conf

#STAGE3_FILE=$(curl -s http://mirror.yandex.ru/gentoo-distfiles/releases/amd64/autobuilds/latest-stage3-amd64-desktop-systemd.txt | grep -v '#' | awk '{print $1}')

STAGE3_FILE=$(curl -s http://mirror.yandex.ru/gentoo-distfiles/releases/amd64/autobuilds/latest-stage3-amd64-desktop-openrc.txt | grep -v '#' | awk '{print $1}')


STAGE3_URL=http://mirror.yandex.ru/gentoo-distfiles/releases/amd64/autobuilds

echo "установка времени"
ntpd -q -g

#password() {
#	echo "придумайте пароль для root"
#	passwd
#}


partition() {
	cd
	DISK=$1
	P_CHECK=$(lsblk -o NAME,FSTYPE -dSn | grep -o $DISK)
	if [ "$P_CHECK" == "$DISK" ] ; then
		ANSWER=$(whiptail --title "Answer window" --yesno "Disk with name $DISK exist. Do you want create new partition?" 10 60)
		if [ "$?" == "0" ] ; then
			echo "разметка диска"
			sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<- EOF | fdisk /dev/$DISK
			o # clear the in memory partition table
			n # new partition
			p # primary partition
			1 # partition number 1
			# default - start at beginning of disk
			+1GB
			n # new partition
			p # primary partition
			2 # partion number 2
			# default, start immediately after preceding partition
			# default, extend partition to end of disk
			a # make a partition bootable
			1 # bootable partition is partition 1 -- /dev/sda1
			p # print the in-memory partition table
			w # write the partition table
			q # and we're done
			EOF
		else
			echo "goodbuy" ; exit 0
		fi
	fi
	cd
}

make_fsys() {
	#echo "создание файловой системы"
	whiptail --title  "Info Message Box" --msgbox  "Create file sys. Choose Ok to continue." 10 60

	mkfs.ext4 /dev/sda1
	mkfs.ext4 /dev/sda2
	mkdir /mnt/gentoo/boot
	mount /dev/sda2 /mnt/gentoo
	mount /dev/sda1 /mnt/gentoo/boot

}

stage3_install() {
	cd
	#echo "скачивание и распаковка stage3 архива"
	whiptail --title  "Info Message Box" --msgbox  "setup and unzip stage3. Choose Ok to continue." 10 60
	cd /mnt/gentoo
        
      	wget $STAGE3_URL/$STAGE3_FILE
	tar xpvf ${STAGE3_FILE:17}
	cd
	#mkdir /mnt/gentoo/boot
	#mount /dev/sda1 /mnt/gentoo/boot
}

compiling_setting() {
	#echo "изменения настроек make.conf"
	whiptail --title  "Info Message Box" --msgbox  "made changes in make.conf. Choose Ok to continue." 10 60

	sed -i "s/COMMON_FLAGS='-O2 -pipe'/COMMON_FLAGS='-march=native -O2 -pipe'/g" $MAKE_PATH

	echo "MAKEOPTS='-j2'" >> $MAKE_PATH
}

make_chroot() {

	#echo "монтирование файловых систем и переход в изолированное окружение"
	whiptail --title  "Info Message Box" --msgbox  "Mount file sys and start chroot. Choose Ok to continue." 10 60

	cp --dereference /etc/resolv.conf /mnt/gentoo/etc

	mount --types proc /proc /mnt/gentoo/proc
	mount --rbind /sys /mnt/gentoo/sys
	mount --make-rslave /mnt/gentoo/sys
	mount --rbind /dev /mnt/gentoo/dev
	mount --make-rslave /mnt/gentoo/dev
	mount --bind /run /mnt/gentoo/run
	mount --make-slave /mnt/gentoo/run

	chroot /mnt/gentoo /bin/bash
	source /etc/profile
	export PS1="(chroot) ${PS1}"
}

error_exit(){

	#echo "обработка ошибок"
	#echo "Error: $1"
	whiptail --title  "Error Message Box" --msgbox  "Error in ${1}. Choose Ok to continue." 10 60
	exit 1

}


#password || error_exit "password error"
#echo "укажите диск для разметки"
DISK=$(whiptail --title "Enter disk name window" --inputbox "enter disk name for partition" 10 60 sda 3>&1 1>&2 2>&3)
partition $DISK || error_exit "partition error"
make_fsys || error_exit "make_fsys  error"
stage3_install || error_exit "stage3_install error"
compiling_setting || error_exit "compiling_setting error"
make_chroot || error_exit "make_chroot error"
