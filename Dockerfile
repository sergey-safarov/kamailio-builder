ARG base_image="centos"
ARG image_tag="8"

FROM ${base_image}:${image_tag}
ARG base_image
ARG image_tag
ARG rhel_username
ARG rhel_password

# SPEC deps install command I take from https://www.terriblecode.com/blog/extracing-rpm-build-dependencies-from-rpm-spec-files/

COPY rpm_extra_specs /rpm_extra_specs/
COPY get_build_env.sh /get_build_env.sh

RUN /get_build_env.sh
