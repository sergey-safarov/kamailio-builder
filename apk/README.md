This folder content used to prepare Kamailio builder image using Alpine Linux.

To start build need excecute

```sh
docker_image_owner=kamailio
docker_image_name=pkg-kamailio-docker
alpine_linux_tag=edge
docker build \
  -t ${docker_image_owner}/${docker_image_name}:alpine-${alpine_linux_tag} \
  --build-arg "alpine:${alpine_linux_tag}" \
  .
```
