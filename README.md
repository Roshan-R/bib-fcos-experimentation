# Generate FCOS disk image with BIB - experimentation

## Overview

This work aims to **identify the missing pieces** required to FCOS disk images using `bootc-image-builder` (BIB).

This is a **logical continuation** of the work done in [coreos-assembler PR #4224](https://github.com/coreos/coreos-assembler/pull/4224/), which introduced the ability to use `bootc install to-filesystem` for FCOS image generation.

## Goals

1. Identify gaps between current `bootc-image-builder` capabilities and FCOS requirements
2. Document the missing features/stages needed for full FCOS support
3. Propose solutions that can be contributed upstream to `osbuild/images` and BIB.

## Usage

```bash
# Add our configuration to base image
sudo podman build -f Containerfile -t fcos-bib

# verify the configuration
sudo podman run --rm localhost/fcos-bib bootc install print-configuration | jq

mkdir -p output
alias bib='sudo podman run --rm -it --privileged --security-opt label=type:unconfined_t -v ./output:/output -v /var/lib/containers/storage:/var/lib/containers/storage quay.io/centos-bootc/bootc-image-builder:latest'
# this image was generated from https://github.com/coreos/coreos-assembler/pull/4224/
BUILD_IMAGE=quay.io/jbtrystramtestimages/cosa:latest

# Output the manifest
bib manifest localhost/fcos-bib | grep -o '{"version".*' | jq .

# Generate the disk image and boot it with cosa
cat > config.bu <<EOF
variant: fcos
version: 1.5.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE5h253p77Ez3dboIen2BBM2r5z4QN3/bLUVRySWiJn0 jcapitao@redhat.com
EOF
bib localhost/fcos-bib --type qcow2 --build-container $BUILD_IMAGE 
cosa run -c -B config.bu --qemu-image disk.qcow2
```

## Issues

I'm using the issues section to report all the issues as it's more appropriate to discuss.

* [bootc-image-builder is missing ignition support](https://github.com/joelcapitao/bib-fcos-experimentation/issues/1)
* [coreos-gpt-setup fails to resize rootfs partition](https://github.com/joelcapitao/bib-fcos-experimentation/issues/2)
