# RiftVM image migration

Source baseline: `everettjf/omarchy-aarch64-image` integration commit
`6aa7490b3cafa417dbb269e524d886fc4bfca29d`. This includes the first-owner
consumer, stdin-safe clipboard frontend, Session Agent, and verified draft
release pipeline. The older local integration checkout did not include all
of these changes and is not the migration baseline.

The new repository uses RiftVM names, the `rift-agent`/`rift-session-agent`
services, `com.riftvm.preinstalled-image` metadata, and a minimum App version
of 0.1.0. `sources.env` pins the reusable Agent from the new main repository.

Local macOS validation passed shell syntax, owner request validation,
first-boot form handling, sparse packaging/checksums, package-resolution and
release-workflow checks using GNU Bash/coreutils/sed. The final display-watcher
checks require Linux `/bin/bash` and `flock`, so complete tests run on the
native ARM64 Ubuntu CI runner; do not report the partial Mac run as a full pass.

First full image builds must remain draft releases until App/factory acceptance
is complete. These raw image assets still require the Mac-side verified ASIF
conversion and signed factory manifest consumed by RiftVM's Omarchy onboarding.
