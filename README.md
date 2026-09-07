# Omarchy AArch64 Image for RiftVM

This project builds and publishes a sparse AArch64 Omarchy disk image exclusively
for [RiftVM](https://github.com/riftvm/riftvm) and Apple's
Virtualization.framework. It does not publish a general-purpose disk image or a
bundle for another virtual-machine frontend.

The image runs natively on Apple silicon: the guest CPU architecture is ARM64,
so RiftVM virtualizes it without cross-architecture CPU emulation.

## Release pipeline

This repository is one part of a three-repository AArch64 release pipeline:

- [`riverscn/omarchy-aarch64`](https://github.com/riverscn/omarchy-aarch64)
  maintains the AArch64 runtime adaptation of Omarchy.
- [`riverscn/omarchy-pkgs-aarch64`](https://github.com/riverscn/omarchy-pkgs-aarch64)
  builds and publishes the signed stable AArch64 pacman repository.
- This repository assembles the RiftVM disk image from Arch Linux ARM and that
  signed repository.

The builder downloads the latest package Release manifest and public key on
every build. It rejects the snapshot unless:

- the manifest uses the expected stable AArch64 schema;
- its signing fingerprint matches the fingerprint pinned in `sources.env`;
- every selected package is present;
- the published `omarchy` package matches the pinned source commit; and
- pacman verifies the signed database and packages.

The installed image keeps the signed repository enabled, so Arch Linux ARM and
Omarchy update together:

```bash
sudo pacman -Syu
```

## Image contents

The RiftVM image contains:

- Arch Linux ARM's generic AArch64 root filesystem and kernel;
- a 1 GiB EFI System Partition and Btrfs root with `@`, `@home`, `@log`,
  and `@pkg` subvolumes;
- Limine, an AArch64 UKI, branded boot menu, factory snapshot, and recovery
  entries;
- VirtIO graphics, block storage, networking, entropy, input, and audio devices
  supported by Virtualization.framework;
- PipeWire audio and its PulseAudio, ALSA, JACK, and GStreamer compatibility
  layers;
- an interactive first-boot wizard for owner credentials, keyboard, Git
  identity, hostname, and timezone;
- an idempotent service that expands the root partition and Btrfs filesystem
  when the virtual disk grows; and
- a built-in Omarchy thumbnail for the RiftVM library.

The profile intentionally excludes host-specific physical hardware services and
guest components that are unavailable through RiftVM.

The distributed image is intentionally unencrypted. A reusable image cannot
safely contain a shared disk-encryption key; per-machine encryption requires a
future installer that creates a unique container during import.

## Installation status

RiftVM 0.1.0 is in development for Apple silicon and macOS 27. No public App
release or Homebrew cask is available yet. See [RiftVM](https://riftvm.github.io/)
for release availability.

The unified App creates an Omarchy workspace from an exact, signed factory
manifest. It verifies the Ed25519 signature and every image part, keeps a shared
read-only factory cache, and gives each workspace its own writable disk,
machine identity and owner credentials. Image updates apply to new workspaces;
they do not replace existing guest disks.

Factory candidates use immutable versioned URLs. Do not use `releases/latest`
for a candidate: GitHub excludes prereleases from that endpoint.

## Release assets

The canonical App factory consists of:

- `riftvm-omarchy-factory-manifest.json`, signed with the key trusted by RiftVM;
- numbered `Omarchy-Factory.asif.part-*` files;
- `RIFTVM_FACTORY_SHA256SUMS`; and
- image provenance and exact package inventories.

The Linux workflow produces the verified raw image as a draft. A macOS signing
stage converts and verifies ASIF, signs the manifest and uploads the factory
parts to that same draft. Publishing requires these factory assets and native
runtime acceptance, in addition to matching uploaded digests.

Drafts may also contain the original sparse-stream export, thumbnail and import
script for development tooling. That raw import route does not replace the
unified App's Omarchy creation flow and is not the supported first-install path.

Each part stays below GitHub's 2 GiB asset limit. The guest disk has a 64 GiB
logical capacity; sparse storage avoids allocating all of it on the host.

## Build

Image assembly executes AArch64 target commands in a chroot and requires a
native AArch64 Arch Linux ARM host. Docker, Git, and the standard image tools
are required.

Build the image:

```bash
./bin/build-image-container
```

Useful options:

```bash
./bin/build-image-container --size 80G --force
./bin/build-image-container --refresh --force
./bin/build-image-container \
  --omarchy-source ../omarchy-aarch64 \
  --omarchy-repository ../omarchy-pkgs-aarch64/pkgs.omarchy.org/stable/aarch64 \
  --force
```

The default output is:

```text
build/omarchy-aarch64-riftvm.raw
build/omarchy-aarch64-riftvm.raw.sha256
```

A successful build also emits package inventories and
`build/image-provenance.txt`, including the pinned RiftVM Guest Agent source
revision and the digest of the exact binary installed into the image.

When the operating-system and Omarchy package graph is already accepted and
only the statically linked RiftVM Guest Agent changed, the manual release workflow
also supports an integration-only rebake. Supply both `base_release_tag` and
the complete raw `base_image_sha256`. The workflow downloads every split base
asset, validates the manifest, each part, the compressed stream, and the
reconstructed raw image, then changes a copy. It replaces the Agent in the
bootable `@` subvolume, recreates the read-only `@factory` snapshot, and records
the base digest plus new source revision in image provenance. The original
release and its raw image are never modified.

This path is deliberately unavailable for kernel, boot, system package,
Omarchy, overlay, or `wl-copy` changes; those require a full image rebuild. A
rebaked candidate is still a new factory image and must pass the same fresh-VM
acceptance and publication gates as a full build.

Package a local RiftVM Release layout:

```bash
./bin/package-riftvm-release \
  --tag v4.0.1-riftvm.1 \
  --output build/release-assets
```

## Tests

Run the static contract and release-packager suite with the adapted Omarchy
source as a sibling checkout:

```bash
OMARCHY_TEST_SOURCE=../omarchy-aarch64 ./tests/run
```

The suite verifies script syntax, package boundaries, signed repository
provenance, boot configuration, sparse output invariants, RiftVM manifest and
installer behavior, split-part checksums, workflow constraints, and the absence
of removed runtime integrations.

A complete release additionally requires a native AArch64 image build, checksum
verification, RiftVM import, boot, first-run provisioning, shutdown, restart, and
forced-stop recovery testing.

See [`docs/RELEASE_VALIDATION.md`](docs/RELEASE_VALIDATION.md) for the complete
publish, public-download, recovery, and end-to-end acceptance procedure.

## License

MIT. See [LICENSE](LICENSE).
