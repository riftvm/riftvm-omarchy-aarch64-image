# Display watcher idle query reduction

The watcher still checks DRM status/mode files every second: virtio-gpu host
resizes can change the existing connector's preferred mode without a Hyprland
monitor-added event. Replacing that check with compositor events would miss
those resizes.

Only the expensive compositor reconciliation is throttled. Startup and changed
DRM signatures reconcile immediately (after the existing 200 ms settling delay
for changes). A mode request remains pending until a subsequent query confirms
acceptance, so failures and unavailable sessions retry every poll. Stable modes
are audited every ten polls, approximately ten seconds with the default interval.
This also repairs compositor reloads that change the current mode without changing
DRM. Such repairs may now take ten seconds instead of one. Custom
`OMARCHY_RIFTVM_POLL_INTERVAL` values scale both intervals.

## Validation

`bash tests/test-frame-scheduling` exercises the scheduling function against fake
DRM files and a fake compositor. Sixty stable ticks plus startup issue seven
monitor queries, compared with 61 previously; steady-state query frequency drops
90%. Tests also cover resize during the idle countdown, unconfirmed requests,
compositor acceptance, reload repair, and unavailable sessions. VFR remains
untouched. This is a deterministic IPC count, not a measured CPU/energy result.

The full source suite requires Linux utilities: on macOS it reaches the package
resolution checks, then stops at a GNU `sed` invocation. The PR's ARM64 Linux CI
runs the complete suite. Before a factory release, validate live resize and
compositor reload recovery in a disposable Guest. Existing installations need a
new paired integration package; changing the Host app alone does not install
this watcher. Overlay changes require a full image rebuild.

## Background repaint after a mode change

A virtio-gpu mode change replaces the compositor's output surfaces, and
Omarchy's background layer can come back without its committed buffer. The
wallpaper is static, so nothing redraws it by itself: the desktop keeps the bar
and the dock but stays bare until an unrelated window resize forces a repaint.
Omarchy cannot repair this either, because its background-repair IPC
deliberately does nothing while the wallpaper path is unchanged.

After the compositor confirms a new mode, the watcher waits one more poll and
then pushes the active theme through the one IPC entry point that forces a
redraw (`background themeTransition` with the current background and theme
payloads). Re-applying the theme that is already active keeps the desktop
appearance identical while the layer commits a fresh buffer. The repaint is
issued once per settled mode change, not on the periodic audit, so a stable
session never flickers. `OMARCHY_RIFTVM_REPAINT_TICKS` adjusts the delay and
`OMARCHY_RIFTVM_SHELL_IPC` overrides the shell command.

`tests/run` covers this with a fake shell IPC and a stateful fake Hyprland: it
asserts the exact repaint payload, exactly one repaint for a settled mode
change, and no repaint while the mode is unchanged. Live first-boot
qualification in a disposable Guest is still pending.

## Holding the mode while the host alternates

A host that is still laying out its window publishes a size and replaces it a
moment later. Every offer the guest acts on makes Hyprland destroy and rebuild
all of its outputs, which the user sees as the desktop flashing, and the
background layer loses its committed buffer in the process. Two guards keep the
guest out of that:

- After the DRM mode list changes, the watcher waits `OMARCHY_RIFTVM_SETTLE_TICKS`
  polls (default 2) with the list unchanged before it touches the compositor, so a
  size that is already being replaced never reaches DRM.
- The watcher counts the mode switches it has made inside
  `OMARCHY_RIFTVM_MODE_SWITCH_WINDOW` seconds (default 30). Once it reaches
  `OMARCHY_RIFTVM_MODE_SWITCH_LIMIT` (default 4) it holds the mode the compositor
  already has, logs `holding <output> at <mode>`, and lets the periodic audit try
  again later. An alternating host therefore costs a few switches instead of an
  endless stream.

The background repaint is part of the same budget: it re-runs a short reveal, so
`OMARCHY_RIFTVM_REPAINT_MIN_INTERVAL` (default 5 seconds) keeps a burst of mode
changes from turning into a burst of repaints.

`tests/run` covers the settle, the repaint payload, exactly one repaint for a
settled change, and the hold: with a compositor that never accepts a request, an
alternating host produces at most `MODE_SWITCH_LIMIT` switches and one
`holding` line.

## Remaining performance work assessment

| Work | Feasibility and next evidence |
| --- | --- |
| Sustained 3D / final frame / latency | Medium: workload harness plus live Guest runs; fixture tests cannot close this. |
| Physical hot-plug and Host sleep/wake | Requires actual hardware interaction and recovery observation. |
| Longer controlled idle A/B and energy | Feasible measurement work; requires stable visibility/lock state and separate energy data. |
| Broad GPU/application compatibility | Ongoing matrix, not a single bounded fix. |
| Refresh-aware presentation and 120 Hz | Requires display support and measured input-to-photon latency before design changes. |
| Watcher polling overhead | This PR reduces idle compositor queries; one-second DRM polling remains. Live qualification is pending. |
| Matched Try Omarchy comparison | Requires both environments with matched resources, resolution and workloads. |

## Native follow-up qualification

On 2026-09-13 the exact candidate watcher was installed in a disposable
4-CPU/8-GiB Guest. A 65-second real Hyprland trace repaired an injected 1280x720
mode back to the DRM preferred 1024x656. VFR stayed enabled. A cold start then
passed file import, text/PNG clipboard, 1024x656-to-880x528 resize and six
size/focus cycles across two displays. Keyboard output and the final blue frame
were observed after the cycles. The Guest was stopped. These checks qualify
resize/recovery correctness; they do not measure energy or 120 FPS throughput.
