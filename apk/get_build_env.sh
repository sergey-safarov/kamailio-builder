#!/bin/sh

OS_FILELIST=/tmp/os_filelist
set -x
set -o errexit -o nounset -o pipefail

image_filelist() {
	find / '(' -path /etc -o -path /dev -o -path /home -o -path /media -o -path /proc -o -path /mnt -o -path /root -o -path /sys -o -path /tmp -o -path /run ')' -prune -o -print
}

prepare_build_user() {
	apk --no-cache add sudo git abuild
	adduser -D build
	addgroup build abuild
	echo "%abuild ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/abuild
	sudo -inu build git config --global user.name 'Kamailio GitHub service user'
	sudo -inu build git config --global user.email 'github@kamailio.org'
	sudo -inu build abuild-keygen -a -i -q -n
}

install_build_deps() {
	cd /tmp
	wget https://raw.githubusercontent.com/kamailio/kamailio/refs/heads/master/pkg/kamailio/alpine/APKBUILD
	abuild -F deps
	rm -f APKBUILD
}

apk --no-cache upgrade
image_filelist >> ${OS_FILELIST}
prepare_build_user
install_build_deps
