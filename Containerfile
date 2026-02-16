FROM quay.io/fedora/fedora-coreos:stable

COPY 00-fcos.toml /usr/lib/bootc/install/00-fcos.toml
COPY fcos-imagetypes.yaml /usr/lib/bootc-image-builder/fcos-imagetypes.yaml
