# Generate FCOS disk image with BIB - experimentation

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
bib localhost/fcos-bib --type qcow2 --build-container $BUILD_IMAGE 
cosa run -c -B butane.bu --qemu-image disk.qcow2
```

## Issues

### 1. Missing ignition support in b-i-b

We should be able to specify something like:

```
image_types:
  "raw":
    ignition: true
```

in the `imagetypes.yaml` file and b-i-b would add the osbuild stage creating the file `ignition.firstboot` in `/boot`.
