# SPDX-License-Identifier: GPL-2.0+
#
# Upstream builds this as obj-$(CONFIG_SND_VIRTIO). Arch Linux ARM ships its
# kernel with CONFIG_SND_VIRTIO unset, so DKMS builds the same sources as an
# out-of-tree module instead. The object list is upstream's, unchanged.

obj-m += virtio_snd.o

virtio_snd-y := \
	virtio_card.o \
	virtio_chmap.o \
	virtio_ctl_msg.o \
	virtio_jack.o \
	virtio_kctl.o \
	virtio_pcm.o \
	virtio_pcm_msg.o \
	virtio_pcm_ops.o
