# Proxmox VE x86_64 artifact

Build a plain FCOS rawhide QCOW2 for import into Proxmox VE. No OCI or OVA
packaging is needed; Tekton integration is not included.

## Build

Requires x86_64 Linux, rootful Podman, Python 3.11+, `yq`, `guestfish`, and
`qemu-img`. Run from the repository root:

```bash
python3 .github/merge-blueprints.py --generate-all
sudo bash scripts/build-proxmoxve.sh
```

Output: `output/proxmoxve/fedora-coreos-proxmoxve.qcow2`, alongside the build
log and manifest. The CLI and builder references come from
`image-builder-config.yaml`; the source and paths are fixed. Existing disk
artifacts block rebuilding, including an interrupted conversion's
`.uncompressed.qcow2`; move them before retrying. Pin the source digest too
for reproducible builds.

The privileged builder shares rootful Podman storage at
`/var/lib/containers/storage`; only use trusted images. After pulling, the
script uses `localhost/bib-proxmoxve-{source,builder}:local` aliases to avoid
multi-architecture local manifest lookups. The completed QCOW2 is owned by
the invoking user.

## Disk preparation

The pinned CLI defaults to a 10 GiB virtual disk. The helper preserves the
blueprint's kernel console order by disabling inherited kernel arguments
(`rw` is explicit), repairs the misplaced GRUB drop-in with guestfish, and
uses `qemu-img convert` without `-c` to disable internal compression while
retaining QCOW2 compat 1.1. Build logs/manifests precede these modifications;
calculate checksums from the final disk. Never prepare a running VM's disk.

These settings follow coreos-assembler's
[Proxmox definition](https://github.com/coreos/coreos-assembler/blob/main/src/osbuild-manifests/platform.proxmoxve.ipp.yaml)
and FCOS
[platform console settings](https://github.com/coreos/fedora-coreos-config/blob/testing-devel/platforms.yaml).
On x86_64, QEMU uses the same disk format and consoles; the important
difference is `ignition.platform.id=proxmoxve`.

## Provisioning

FCOS uses **Ignition, not cloud-init**. Proxmox's configuration drive can
deliver an Ignition JSON file as a **vendor-data snippet** using
`cicustom vendor=STORAGE:snippets/config.ign`. Follow the upstream
[FCOS Proxmox provisioning guide](https://github.com/coreos/fedora-coreos-docs/blob/main/modules/ROOT/pages/provisioning-proxmoxve.adoc),
substituting this local QCOW2 for the downloaded image. Do not rely on
cloud-init user-data or network settings to configure FCOS.

Native Proxmox VE boot testing has not been performed. Deployment and test
utilities are intentionally kept outside this repository.
