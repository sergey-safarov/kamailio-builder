ARG base_image="centos"
ARG image_tag="8"

FROM ${base_image}:${image_tag}
ARG base_image
ARG image_tag

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
    if [ "${base_image}" == "centos" ]; then \
        extra_packages="epel-release"; \
    fi; \
    if [ "${base_image}" == "centos" -a "${image_tag}" != "6" ]; then \
        rpm_extra_builds="libphonenumber"; \
    fi; \
    if [ "${base_image}" == "fedora" ]; then \
        rpm_extra_builds="libphonenumber"; \
    fi; \
    ${pkg_manager} update; \
    ${pkg_manager} install rpm-build gcc make wget bison flex which git ${extra_packages}; \
    wget https://raw.githubusercontent.com/kamailio/kamailio/master/pkg/kamailio/obs/kamailio.spec; \
    for i in ${rpm_extra_builds}; do ${pkg_manager} install $(rpmspec -P rpm_extra_specs/${i}.spec | grep BuildRequires | sed -r -e 's/BuildRequires:\s+//' -e 's/,//g' | xargs); done; \
    if [ "${base_image}" == "centos" -a "${image_tag}" == "6" ]; then \
        sed -i -e '/libphonenumber-devel/d' -e 's/systemd-mini/systemd/' kamailio.spec; \
        yum -y install yum-utils; \
        yum-builddep -y kamailio.spec; \
    else \
        ${pkg_manager} install $(rpmspec -P kamailio.spec | grep BuildRequires | sed -r -e 's/BuildRequires:\s+//' -e 's/,//g' -e '/libphonenumber-devel/d' -e 's/systemd-mini/systemd/' | xargs); \
    fi; \
    rm -Rf /var/cache/dnf/* /var/cache/yum/* /var/cache/zypp/*; \
    rm -f kamailio.spec

RUN if [ ! -z "${rpm_extra_builds}" ]; then \
        echo "Building extra deps RPM packages"; \
        for i in ${rpm_extra_builds}; do rpmbuild --nocheck -ba rpm_extra_specs/${i}.spec; done \
    fi

RUN if [ ! -z "${rpm_extra_builds}" ]; then \
        echo "Installing extra RPM deps"; \
        rpm -i $(find ~/rpmbuild/RPMS -type f \( -name "*.rpm" -not -name "*.src.rpm" \) | xargs); \
        mkdir /deps; \
        mv ~/rpmbuild/RPMS /deps; \
        mv ~/rpmbuild/SRPMS /deps; \
        rm -Rf ~/rpmbuild; \
    fi
