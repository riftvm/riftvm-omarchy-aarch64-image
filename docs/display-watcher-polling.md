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
