# virtio_snd for Arch Linux ARM

Apple's Virtualization.framework gives the machine a virtio sound device, and
RiftVM configures one. Arch Linux ARM builds its `linux-aarch64` kernel with

    # CONFIG_SND_VIRTIO is not set

so nothing can drive it: `/proc/asound/cards` reports no soundcard and PipeWire
falls back to a null sink, which is silence in every application.

These are the unmodified `sound/virtio` sources from Linux **7.2.6**
(`linux-7.2.6.tar.xz`, sha256
`039aef84f2b0994aeda3f4fcfc3d02ec9d7a9bbb9020ea264c43f446c860f606`), which is
the kernel this image ships. Only the `Makefile` differs from upstream, because
an out-of-tree build cannot use `obj-$(CONFIG_SND_VIRTIO)`. They are
GPL-2.0-or-later, like the kernel.

DKMS builds them against whatever kernel is installed and rebuilds after a
kernel update. The module carries the usual virtio modalias, so udev loads it
on its own once `depmod` has seen it — there is no modules-load entry to keep
in step.

If a future kernel changes the ALSA or virtio interfaces these sources use, the
DKMS build fails and the machine has no sound again. That is visible in
`dkms status` and in the pacman hook's output. The durable fix is Arch Linux ARM
enabling `CONFIG_SND_VIRTIO`, which would make this directory unnecessary.
