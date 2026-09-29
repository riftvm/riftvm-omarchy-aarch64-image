#!/bin/bash

# Provision the three image tools the builder container image does not ship.
# Sourced inside the container by bin/build-image-container.
#
# The build used to run `pacman -Syu --needed` on every start, which upgraded
# the whole build environment to whatever the mirrors served that minute. The
# steps below stop at the first one that yields working tools:
#
#   1. nothing, when the tools are already installed and run;
#   2. `pacman -S --needed` against the package database baked into the
#      builder image, which installs exactly the versions that image was
#      built against;
#   3. `pacman -Sy --needed` for these packages only. A stale database points
#      at package files the mirrors no longer serve, so step 2 cannot download
#      them. Refreshing the database without upgrading is a partial upgrade,
#      which Arch does not support in general: a new tool can need a newer
#      library than the image has. It is acceptable here only because the
#      container is disposable and every tool is executed before it is
#      trusted;
#   4. the previous full `pacman -Syu --needed`, when a tool still does not
#      run.
#
# OMARCHY_IMAGE_BUILDER_FULL_UPGRADE=1 skips straight to step 4.

BUILDER_TOOL_PACKAGES=(btrfs-progs dosfstools parted)

builder_tools_work() {
  local tool

  for tool in btrfs mkfs.btrfs mkfs.fat parted; do
    command -v "$tool" >/dev/null 2>&1 || return 1
  done
  # Execute each tool so a missing or mismatched shared library is caught
  # here rather than in the middle of image assembly.
  btrfs --version >/dev/null 2>&1 || return 1
  mkfs.btrfs --version >/dev/null 2>&1 || return 1
  mkfs.fat --help >/dev/null 2>&1 || return 1
  parted --version >/dev/null 2>&1 || return 1
}

ensure_builder_tools() {
  if [[ ${OMARCHY_IMAGE_BUILDER_FULL_UPGRADE:-0} == 1 ]]; then
    pacman -Syu --needed --noconfirm "${BUILDER_TOOL_PACKAGES[@]}"
    return
  fi

  if builder_tools_work; then
    printf 'Image tools are already installed in the builder.\n'
    return 0
  fi

  if pacman -S --needed --noconfirm "${BUILDER_TOOL_PACKAGES[@]}" &&
    builder_tools_work; then
    return 0
  fi

  printf 'Refreshing the package database to install the image tools.\n' >&2
  if pacman -Sy --needed --noconfirm "${BUILDER_TOOL_PACKAGES[@]}" &&
    builder_tools_work; then
    return 0
  fi

  printf 'Image tools do not run after a partial install; upgrading the builder.\n' >&2
  pacman -Syu --needed --noconfirm "${BUILDER_TOOL_PACKAGES[@]}"
}
