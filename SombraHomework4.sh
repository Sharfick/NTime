#!/bin/bash

MAKE_PATH=/etc/make.conf


driver_install(){

	echo "установка обновление драйверов"
	echo "имя нового пользователя:"
	read NAME

	useradd -m -G wheel,audio,video $NAME
	echo "пароль для $NAME"

	passwd $NAME

	echo "VIDEO_CARDS='amdgpu radeon radensi'" >>$MAKE_PATH
	echo "INPUT_DEVICES='synaptics libinput'" >>$MAKE_PATH

	emerge --pretend --verbose x11-base/xorg-drivers
	emerge --ask x11-base/xorg-server

}

graphic_install(){

	echo "установка графического интерфейса GNOME"
	eselect profile set default/linux/amd64/17.1/desktop/gnome/systemd

	emerge --ask gnome-base/gnome

	env-update && sourse /etc/profile
	getent group plugdev

	gpasswd -a $NAME plugdev

}

error_exit(){

	#echo "обработка ошибок"
	echo"Error: $1"
	exit 1

}

	driver_install || error_exit "driver error"
	graphic_install || error_exit "graphic_install error"
