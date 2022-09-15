#!bin/bash

LOCALE_PATH=/etc/locale.gen
LOCALE02=/etc/env.d/02locale
MAKE_PATH=/etc/portage/make.conf

setting_portage(){
	
	echo "установка снимка репозитория ebuild-файлов Gentoo"

	emerge-websync
	emerge --sync
	emerge --sync --quiet

}

profile_select(){

	echo "выбор профиля"
	eselect profile set 7

}

world_update(){

	echo "обновление набора @world "
	emerge --ask --verbose --update --deep --newuse @world

	echo "установка timezone для Екатеринбурга"
	echo "USE='-gtk -gnome qt5 kde dvd alsa cdr'" >> $MAKE_PATH
	echo "ACCEPT_LICENSE='*'" >> $MAKE_PATH
	echo "Asia/Yekaterinburg" > /etc/timezone

	emerge --config sys-libs/timezone-data

}

locale_update(){
	
	echo "смена локали на русский"
	echo "en_US ISO-8859-1" >> $LOCALE_PATH
	echo "en_US.UTF-8 UTF-8" >> $LOCALE_PATH
	echo "ru_RU.UTF-8 UTF-8" >> $LOCALE_PATH

	locale-gen

	echo "LANG='ru_RU.UTF-8'" >$LOCALE02
	echo "LC_COLLATE='C.UTF-8'" >>$LOCALE02

	emerge --ask sys-kernel/gentoo-sources
	env-update && source /etc/profile && export PS1="(chroot) $PS1"

}

error_exit(){
	
	#echo "обработка ошибок"
	echo "Erorr: $1"
	exit 1

}

	setting_portage || error_exit "portage error"
	profile_select || error_exit "profile error"
	world_update || error_exit "world error"
	locale_update || error_exit "locale error" 
