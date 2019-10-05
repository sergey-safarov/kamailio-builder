To build image need to define environement variables `repo_owner`, `base_image`, `image_tag` and then start build image like

```sh
export repo_owner=safarov
export base_image=fedora
export image_tag=31
docker build \
    --build-arg base_image=${base_image} \
    --build-arg image_tag=${image_tag} \
    -t ${repo_owner}/kamilio-builder:${base_image}-${image_tag} .
```
