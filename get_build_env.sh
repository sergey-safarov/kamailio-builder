#!/bin/sh

dist_id=""
dist_version_id=""

set -x
set -o errexit -o nounset -o pipefail

set_global_vars() {
	dist_id=$(grep "^ID=" /etc/os-release | sed -e 's/^ID=//' -e 's/"//g')
	dist_version_id=$(grep "^VERSION_ID=" /etc/os-release | sed -e 's/^VERSION_ID=//' -e 's/"//g')
}

build_prep_fedora() {
	# Do not required
	dnf -y install 'dnf-command(builddep)' wget rpm-build gcc gcc-c++
}

build_prep_centos() {
	# Do not required
	case ${dist_version_id} in
	8)
		sed -i \
		  -e 's/mirrorlist/#mirrorlist/g' \
		  -e 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' \
		  /etc/yum.repos.d/CentOS-*
		;;
	esac

	# mandatory packages
	dnf -y install 'dnf-command(builddep)' wget rpm-build epel-release

	case ${dist_version_id} in
	8)
		dnf config-manager --set-enabled powertools
		# Packages for old branch build
		dnf -y install pcre-devel
		;;
	9)
		dnf config-manager --set-enabled crb
		# Packages for old branch build
		dnf -y install pcre-devel
		;;
	10)
		dnf config-manager --set-enabled crb
		;;
	esac
}

build_prep_rhel() {
	# we need to use only first index for version id
	dist_version_id=$(echo ${dist_version_id} | sed -e 's/\.[0-9]\+//')
	subscription-manager register --username="${rhel_username}" --password="${rhel_password}"
	subscription-manager attach
	# mandatory packages
	dnf -y install wget rpm-build
	# Packages for old branch build
	case ${dist_version_id} in
	8)
		dnf -y install pcre-devel
		;;
	9)
		dnf -y install pcre-devel
		;;
	10)
		dnf -y install java-devel
		;;
	esac
	dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${dist_version_id}.noarch.rpm
	dnf config-manager --set-enabled codeready-builder-for-rhel-${dist_version_id}-${HOSTTYPE}-rpms
}

get_build_deps() {
	local spec_or_srpm=$1
	case ${dist_id} in
	*)
		dnf -y builddep ${spec_or_srpm}
		;;
	esac
}

install_rpms() {
	case ${dist_id} in
	*)
		dnf install -y $@
		;;
	esac
}

build_locally_freeradius_client() {
	wget --no-verbose --continue https://dl.fedoraproject.org/pub/fedora/linux/releases/40/Everything/source/tree/Packages/f/freeradius-client-1.1.7-31.fc40.src.rpm
	get_build_deps freeradius-client-*.src.rpm
	rpmbuild --rebuild --nocheck freeradius-client-*.src.rpm
	install_rpms ~/rpmbuild/RPMS/*/*
	rm -f freeradius-client-*.src.rpm
}

build_locally_libjwt() {
	wget --no-verbose --continue https://dl.fedoraproject.org/pub/fedora/linux/releases/41/Everything/source/tree/Packages/l/libjwt-1.12.1-17.fc41.src.rpm
	get_build_deps libjwt-*.src.rpm
	rpmbuild --rebuild --nocheck libjwt-*.src.rpm
	install_rpms ~/rpmbuild/RPMS/*/*
	rm -f libjwt-*.src.rpm
}

build_locally_libphonenumber() {
	wget --no-verbose --continue https://dl.fedoraproject.org/pub/fedora/linux/releases/40/Everything/source/tree/Packages/l/libphonenumber-8.13.30-1.fc40.src.rpm
	get_build_deps libphonenumber-*.src.rpm
	rpmbuild --rebuild --nocheck libphonenumber-*.src.rpm
	install_rpms ~/rpmbuild/RPMS/*/*
	rm -f libphonenumber-*.src.rpm
}

build_locally_libnats() {
	get_build_deps rpm_extra_specs/libnats.spec
	mkdir -p ~/rpmbuild/SOURCES/
	rpmbuild -ba --undefine=_disable_source_fetch --nocheck rpm_extra_specs/libnats.spec
	install_rpms ~/rpmbuild/RPMS/*/*
}

build_locally_geoip() {
	wget --no-verbose --continue https://dl.fedoraproject.org/pub/fedora/linux/releases/40/Everything/source/tree/Packages/g/GeoIP-1.6.12-18.fc40.src.rpm
	get_build_deps GeoIP-*.src.rpm
	rpmbuild --rebuild --nocheck GeoIP-*.src.rpm
	install_rpms ~/rpmbuild/RPMS/*/*
	rm -f GeoIP-*.src.rpm
}

build_locally_geoip_data() {
	wget --no-verbose --continue https://dl.fedoraproject.org/pub/fedora/linux/releases/40/Everything/source/tree/Packages/g/GeoIP-GeoLite-data-2018.06-16.fc40.src.rpm
	get_build_deps GeoIP-GeoLite-data-*.src.rpm
	rpmbuild --rebuild --nocheck GeoIP-GeoLite-data-*.src.rpm
	install_rpms ~/rpmbuild/RPMS/*/*
	rm -f GeoIP-GeoLite-data-*.src.rpm
}

build_locally_wolfssl() {
	get_build_deps rpm_extra_specs/wolfssl.spec
	mkdir -p ~/rpmbuild/SOURCES/
	rpmbuild -ba --undefine=_disable_source_fetch --nocheck rpm_extra_specs/wolfssl.spec
	install_rpms ~/rpmbuild/RPMS/*/*
}

get_locally_build_list_centos() {
	case ${dist_version_id} in
	8)
		echo "libphonenumber libnats wolfssl geoip_data geoip"
		;;
	9)
		echo "libphonenumber libnats freeradius_client wolfssl geoip_data geoip"
		;;
	10)
		echo "libphonenumber libnats freeradius_client wolfssl libjwt geoip_data geoip"
		;;
	esac
}

get_locally_build_list_rhel() {
	case ${dist_version_id} in
	8)
		echo "libphonenumber libnats wolfssl geoip_data geoip"
		;;
	9)
		echo "libphonenumber libnats freeradius_client wolfssl geoip_data geoip"
		;;
	10)
		echo "libphonenumber libnats freeradius_client wolfssl libjwt geoip_data geoip"
		;;
	esac
}

get_locally_build_list_fedora() {
	echo "libnats wolfssl"
}

build_locally() {
	local build_list=$(get_locally_build_list_${dist_id})
	for package in ${build_list}; do
		build_locally_${package}
	done
}

install_kamailio_deps() {
	wget --no-verbose --continue https://raw.githubusercontent.com/kamailio/kamailio/master/pkg/kamailio/obs/kamailio.spec
	get_build_deps kamailio.spec
	rm -f kamailio.spec
}

cleanup_fedora() {
	rm -Rf ~/rpmbuild/
	rm -Rf /var/cache/dnf/*
}

cleanup_centos() {
	rm -Rf ~/rpmbuild/
	rm -Rf /var/cache/dnf/*
}

cleanup_rhel() {
	subscription-manager remove --all	
	subscription-manager unregister
	rm -Rf ~/rpmbuild/
	rm -Rf /var/cache/dnf/*
}

cleanup_xxx() {
        rm -Rf /var/cache/dnf/* /var/cache/yum/* /var/cache/zypp/*
}

set_global_vars
build_prep_${dist_id}
build_locally
install_kamailio_deps
cleanup_${dist_id}