To build image for RHEL-7, RHEL-8 need define variables `repo_owner`, `base_image`, `image_tag`, `rhel_username`, `rhel_password` and
then start build image like

```sh
export repo_owner=safarov
export base_image=rhel
export image_tag=8
export rhel_username=${your_username}
export rhel_password=${your_password}
export platform=x86_64
docker buildx build \
    --platform linux/${platform} \
    --build-arg base_image=registry.redhat.io/ubi${image_tag} \
    --build-arg image_tag=latest \
    --build-arg rhel_username=${rhel_username} \
    --build-arg rhel_password=${rhel_password} \
    -t ${repo_owner}/kamailio-builder:${base_image}-${image_tag} .
```

To build image for OpenSUSEneed define variables `repo_owner`, `base_image`, `image_tag` and then start build image like

```
export repo_owner=safarov
export base_image=opensuse/leap
export image_tag=15
export platform=x86_64
docker buildx build \
    --platform linux/${platform} \
    --no-cache \
    --build-arg base_image=${base_image} \
    --build-arg image_tag=${image_tag} \
    --build-arg image_tag=latest \
    -t ${repo_owner}/kamailio-builder:opensuse-${image_tag} .
```

To build image need to define environement variables `repo_owner`, `base_image`, `image_tag` and then start build image like

```sh
export repo_owner=safarov
export base_image=fedora
export image_tag=31
export platform=x86_64
docker buildx build \
    --platform linux/${platform} \
    --build-arg base_image=${base_image} \
    --build-arg image_tag=${image_tag} \
    -t ${repo_owner}/kamailio-builder:${base_image}-${image_tag} .
```

To build for CentOS Stream
```sh
export repo_owner=safarov
export base_image=centos
export image_tag=10
export platform=x86_64
docker buildx build \
    --platform linux/${platform} \
    --build-arg base_image=quay.io/centos/centos \
    --build-arg image_tag=${image_tag} \
    -t ${repo_owner}/kamailio-builder:${base_image}-${image_tag} .
```

Suported dist

| dist                | version |
|---------------------|---------|
| rhel                | 8       |
| rhel                | 7       |
| centos              | 8       |
| centos              | 7       |
| fedora              | 35      |
| fedora              | 34      |
| fedora              | 33      |
| fedora              | 32      |
| opensuse/leap       | 15      |
| opensuse/tumbleweed | latest  |
