## Omarchy factory for RiftVM

This is the ARM64 Omarchy factory image used by the RiftVM app.
**Requires macOS 27 or later and an Apple silicon Mac.**

Install the app with `brew install --cask riftvm/tap/riftvm`, or download it
from [RiftVM Releases](https://github.com/riftvm/riftvm/releases/latest).
Choose **Create Omarchy Workspace** in the app; it downloads and verifies the
signed factory manifest and image parts, then creates a separate writable disk
and guides you through owner setup.

Existing workspaces keep their disks. A new factory image does not replace or
update an existing guest.

The canonical assets are `Omarchy-Factory.asif.part-*`,
`riftvm-omarchy-factory-manifest.json`, and `RIFTVM_FACTORY_SHA256SUMS`.
The app pins an exact release URL. Sparse-stream exports are for developer
import tools; users do not need to concatenate or import parts manually.

Package inventories and image provenance are included for reproducibility.
See the [website](https://riftvm.com) for installation and requirements.
