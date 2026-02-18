FROM quay.io/fedora/fedora-coreos:stable

COPY 00-fcos.toml /usr/lib/bootc/install/00-fcos.toml
COPY disk.yaml /usr/lib/bootc-image-builder/disk.yaml
