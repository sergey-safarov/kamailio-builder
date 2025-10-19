#!/bin/sh

OS_FILELIST=/tmp/os_filelist
set -x
set -o errexit -o nounset -o pipefail

image_filelist() {
	find / '(' -path /etc -o -path /dev -o -path /home -o -path /media -o -path /proc -o -path /mnt -o -path /root -o -path /sys -o -path /tmp -o -path /run ')' -prune -o -print
}

package_dumpcap() {
	apkArch="$(apk --print-arch)"

	case "${apkArch}" in
	armhf)
		echo "armhf arch does not have  wireshark-common package, skiping"
		;;
	*)
		apk --no-cache add wireshark-common
		addgroup build wireshark
		;;
	esac
}

install_common_deps() {
	apk --no-cache add build-base git doas abuild tcpdump coreutils sudo
}

prepare_build_user() {
	adduser -D build
	addgroup build abuild
	echo "permit nopass :abuild as root" > /etc/doas.d/doas.conf
	echo '%abuild ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/abulid.conf
	su - build -c "git config --global user.name 'Kamailio GitHub service user'"
	su - build -c "git config --global user.email 'github@kamailio.org'"
	su - build -c "abuild-keygen -a -i -n"
}

install_build_deps() {
	cd /tmp
	wget https://raw.githubusercontent.com/sergey-safarov/kamailio/refs/heads/master/pkg/kamailio/alpine/APKBUILD
	if grep -q edge /etc/os-release; then
		echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
		export use_testing=true
	fi
	export use_community=true
	abuild -F deps
	rm -f APKBUILD
}

apk --no-cache upgrade
image_filelist >> ${OS_FILELIST}
install_common_deps
prepare_build_user
install_build_deps
package_dumpcap
