notify_update() {
  # A fresh factory can already be current. Notify only after a successful
  # package check actually lists updates; offline/error results are not updates.
  local updates status
  if updates=$(timeout 90 checkupdates --nocolor 2>/dev/null); then
    [[ -n $updates ]] || return 0
  else
    status=$?
    if [[ $status != 2 ]]; then
      printf 'RiftVM first-run update check failed (status %s)\n' "$status" >&2
    fi
    return 0
  fi
  omarchy-notification-send -u critical -g  "Update System" "Click to update the system." \
    --exec omarchy-launch-floating-terminal-with-presentation omarchy-update
}

notify_wifi() {
  omarchy-notification-send -u critical -g 󰖩 "Setup Wi-Fi" "Click to configure the wireless network." \
    --exec omarchy-shell shell toggle omarchy.network
}

announce_network() {
  # Ethernet is still negotiating DHCP when the session starts, so probing
  # right away calls a working machine offline. NetworkManager reports startup
  # complete once it has tried every connection it could auto-activate, which
  # is the first moment the answer means anything.
  nm-online -q -s -t 30

  # -x takes that answer as it stands rather than waiting out the timeout, so
  # a laptop with nothing to connect to gets prompted immediately.
  if ! nm-online -q -x -t 30; then
    notify_wifi
    # Nothing to update against until a link lands, so hold that prompt.
    nm-online -q -t 3600 || return
  fi

  notify_update
}

# Detached, so a slow or absent connection never holds up the rest of first run.
announce_network &
