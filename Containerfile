FROM quay.io/fedora/fedora-coreos:stable

COPY 00-fcos.toml /usr/lib/bootc/install/00-fcos.toml
COPY disk.yaml /usr/lib/bootc-image-builder/disk.yaml
# We copy the bootc binary from our cosa image that contains
# all the fixes of https://github.com/coreos/coreos-assembler/pull/4224/
# to our target image
COPY --from=quay.io/jbtrystramtestimages/cosa:latest /usr/bin/bootc /usr/bin/bootc
