# Demand-driven Omarchy rendering

The display watcher must reconcile DRM modes without overriding Hyprland's
`debug:vfr` option. Earlier images disabled VFR both here and in Rift Agent to
work around delayed visible updates. Removing only one override leaves the
other able to turn VFR off again after startup or configuration changes.

This change accompanies the RiftVM `perf/omarchy-demand-rendering` branch:

- The Host retains damage received during drawable acquisition/render and drains
  the last pending frame without requiring another Guest update.
- The Host removes the normal periodic presentation timer and uses bounded
  one-shot retries for failed presentations.
- The new Rift Agent no longer changes compositor frame scheduling.
- This image watcher still applies changed preferred modes, but no longer
  queries or changes VFR on its one-second reconciliation loop.

Ship these changes together. A newly built factory must consume the updated
Rift Agent as well as this overlay, and must be qualified with the corresponding
Host. This PR does not publish a factory or migrate existing user disks. An
existing Guest retains its installed watcher and Agent until explicitly updated;
a Host-only update does not deliver the complete idle improvement.

The companion Host report contains real-VM results and limitations:
https://github.com/riftvm/riftvm/tree/perf/omarchy-demand-rendering/docs/validation/omarchy-demand-rendering-2026-09-13

`bash tests/test-frame-scheduling` verifies that stable mode reconciliation does
not change compositor options and that a real preferred-mode change still
reconfigures the display.
