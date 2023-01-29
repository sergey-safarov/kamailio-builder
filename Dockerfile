ARG base_image="centos"
ARG image_tag="8"

FROM ${base_image}:${image_tag}
ARG base_image
ARG image_tag
ARG rhel_username
ARG rhel_password

# SPEC deps install command I take from https://www.terriblecode.com/blog/extracing-rpm-build-dependencies-from-rpm-spec-files/

COPY rpm_extra_specs /rpm_extra_specs/

RUN set -e; \
    set -x; \
    echo "Preparing kamailio builder using '${base_image}:${image_tag}' image"; \
    pkg_manager="yum -y"; \
    if zypper --version &>/dev/null; then \
        pkg_manager="zypper -n"; \
    elif dnf --version &>/dev/null; then \
        pkg_manager="dnf -y"; \
    fi; \
    if [ "${base_image}" == "registry.redhat.io/ubi7" -o "${base_image}" == "registry.redhat.io/ubi8" ]; then \
        subscription-manager register --username="${rhel_username}" --password="${rhel_password}"; \
        subscription-manager attach; \
    fi; \
    if [ "${base_image}" == "registry.redhat.io/ubi8" ]; then \
        dnf config-manager --set-enabled codeready-builder-for-rhel-8-x86_64-rpms; \
        dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
        rpm_extra_builds="libphonenumber"; \
    fi; \
    if [ "${base_image}" == "registry.redhat.io/ubi7" ]; then \
        yum-config-manager --enable rhel-7-server-optional-rpms; \
        yum-config-manager --enable rhel-7-server-devtools-rpms; \
        yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; \
        rpm_extra_builds="libphonenumber"; \
    fi; \
    if [ "${base_image}" == "safarov/centos" ]; then \
        # Need enable additional repos \
        dnf -y install 'dnf-command(config-manager)'; \
        extra_packages="epel-release"; \
        rpm_extra_builds="libnats"; \
        dnf -y install wget rpm-build epel-release; \
        wget --no-verbose https://dl.fedoraproject.org/pub/fedora/linux/releases/37/Everything/source/tree/Packages/l/libphonenumber-8.12.11-15.fc37.src.rpm; \
        if [ "${image_tag}" == "8" ]; then \
                dnf config-manager --set-enabled powertools; \
                dnf -y builddep libphonenumber-*.src.rpm; \
                rpmbuild --define "debug_package %{nil}" --rebuild libphonenumber-*.src.rpm; \
        else \
                dnf config-manager --set-enabled crb; \
                dnf -y builddep libphonenumber-*.src.rpm; \
                rpmbuild --rebuild libphonenumber-*.src.rpm; \
                wget --no-verbose https://dl.fedoraproject.org/pub/fedora/linux/releases/37/Everything/source/tree/Packages/f/freeradius-client-1.1.7-26.fc37.src.rpm; \
                dnf -y builddep freeradius-client-*.src.rpm; \
                rpmbuild --rebuild freeradius-client-*.src.rpm; \
                wget --no-verbose https://dl.fedoraproject.org/pub/fedora/linux/releases/37/Everything/source/tree/Packages/g/GeoIP-GeoLite-data-2018.06-10.fc37.src.rpm; \
                dnf -y builddep GeoIP-GeoLite-data-*.src.rpm; \
                rpmbuild --rebuild GeoIP-GeoLite-data-*.src.rpm; \
                dnf install -y ~/rpmbuild/RPMS/noarch/GeoIP-GeoLite-data-*.noarch.rpm; \
                rm -f GeoIP-*.src.rpm; \
                wget --no-verbose https://dl.fedoraproject.org/pub/fedora/linux/releases/37/Everything/source/tree/Packages/g/GeoIP-1.6.12-12.fc37.src.rpm; \
                dnf -y builddep GeoIP-*.src.rpm; \
                rpmbuild --rebuild GeoIP-*.src.rpm; \
                rm -f *.rpm; \
                dnf -y remove GeoIP-GeoLite-data*; \
        fi; \
        rm -f *.rpm; \
    fi; \
    if [ "${base_image}" == "centos" -a "${image_tag}" == "7" ]; then \
        yum install -y centos-release-scl; \
        extra_packages="epel-release"; \
        rpm_extra_builds="libphonenumber"; \
    fi; \
    if [ "${base_image}" == "centos" -a "${image_tag}" == "6" ]; then \
        extra_packages="epel-release"; \
        sed -i \
          -e '/mirrorlist/d' \
          -e 's/^#baseurl/baseurl/' \
          -e 's|http://mirror.centos.org/centos|https://vault.centos.org|' \
          -e 's/$releasever/6.10/' \
          /etc/yum.repos.d/*; \
    fi; \
    if [ "${base_image}" == "fedora" ]; then \
        mkdir -p ~/rpmbuild/SOURCES; \
        rpm_extra_builds="libnats"; \
    fi; \
    if [ "${base_image}" == "opensuse/tumbleweed" -a "${image_tag}" == "latest"  ]; then \
        extra_packages="system-group-hardware"; \
    fi; \
    ${pkg_manager} update; \
    ${pkg_manager} install rpm-build gcc gcc-c++ make wget bison flex which git ${extra_packages}; \
    if [ ! -z "${rpm_extra_builds}" ]; then \
        echo "Building extra deps RPM packages"; \
        for i in ${rpm_extra_builds}; do ${pkg_manager} install $(rpmspec -P rpm_extra_specs/${i}.spec | grep BuildRequires | sed -r -e 's/BuildRequires:\s+//' -e 's/,//g' | xargs); done; \
        for i in ${rpm_extra_builds}; do rpmbuild --undefine _disable_source_fetch --nocheck -ba rpm_extra_specs/${i}.spec; done \
    fi; \
    if [ ! -z "${rpm_extra_builds}" ]; then \
        echo "Installing extra RPM deps"; \
        rpm -i $(find ~/rpmbuild/RPMS -type f \( -name "*.rpm" -not -name "*.src.rpm" \) | xargs); \
        mkdir /deps; \
        mv ~/rpmbuild/RPMS /deps; \
        mv ~/rpmbuild/SRPMS /deps; \
        rm -Rf ~/rpmbuild; \
    fi; \
    wget https://raw.githubusercontent.com/kamailio/kamailio/master/pkg/kamailio/obs/kamailio.spec; \
    for i in ${rpm_extra_builds}; do ${pkg_manager} install $(rpmspec -P rpm_extra_specs/${i}.spec | grep BuildRequires | sed -r -e 's/BuildRequires:\s+//' -e 's/,//g' | xargs); done; \
    if [ "${base_image}" == "centos" -a "${image_tag}" == "6" ]; then \
        sed -i -e 's/systemd-mini/systemd/' kamailio.spec; \
        yum -y install yum-utils; \
        yum-builddep -y kamailio.spec; \
    else \
        ${pkg_manager} install $(rpmspec -P kamailio.spec | grep BuildRequires | sed -r -e 's/BuildRequires:\s+//' -e 's/,//g' -e 's/systemd-mini/systemd/' | xargs); \
    fi; \
    if [ "${base_image}" == "registry.redhat.io/ubi7" -o "${base_image}" == "registry.redhat.io/ubi8" ]; then \
        subscription-manager remove --all; \
        subscription-manager unregister; \
    fi; \
    rm -Rf /var/cache/dnf/* /var/cache/yum/* /var/cache/zypp/*; \
    rm -f kamailio.spec
