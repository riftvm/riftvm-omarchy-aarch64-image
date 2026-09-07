## Omarchy factory for RiftVM

This is an ARM64 Omarchy image candidate for the unified RiftVM App on Apple
silicon and macOS 27. RiftVM 0.1.0 is still in development; this image is not a
public App release or a claim that the full product has passed acceptance.

The App consumes `riftvm-omarchy-factory-manifest.json` from an exact versioned
release URL. It verifies the Ed25519 signature and image-part digests, then
creates an independent writable workspace with fresh identity and credentials.
Existing workspaces are never replaced by a newer factory.

The canonical factory assets are `Omarchy-Factory.asif.part-*` and their signed
manifest. Sparse-stream exports and their import script are development tools,
not the supported first-install path. Do not use `releases/latest` for this
candidate, and do not concatenate or import parts manually.

The native image build records package inventories and provenance. Where a
verified base is reused, provenance retains its original package graph and
records the exact integration update. Factory publication additionally requires
ASIF/raw verification, signed-manifest validation, matching uploaded digests,
and native Guest startup and integration checks.

See the [RiftVM website](https://riftvm.github.io/) for App release availability.
