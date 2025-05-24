ARG base_image="alpine:latest"

FROM ${base_image}
ARG base_image

RUN --mount=type=bind,source=get_build_env.sh,target=/get_build_env.sh \
    /get_build_env.sh
USER build
