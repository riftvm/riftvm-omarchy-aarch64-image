# The image builder installs both agents. Keep this target-side step tolerant so
# the runtime can also be used with another hypervisor or a deliberately minimal
# package set.
if systemctl list-unit-files qemu-guest-agent.service >/dev/null 2>&1; then
  systemctl enable qemu-guest-agent.service
fi

if systemctl list-unit-files spice-vdagentd.service >/dev/null 2>&1; then
  systemctl enable spice-vdagentd.service
fi
