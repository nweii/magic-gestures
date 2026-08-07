#!/bin/zsh
set -euo pipefail

# Reports which multi-touch triggers macOS has already claimed, named by the
# Trickpad gesture slug each claim endangers. A claimed trigger still fires its
# system action when a Trickpad binding sits on the same trigger, so both run.
#
# macOS assigns touch gestures in more than one preference domain, and the
# Trackpad settings pane is not the only place a trackpad gesture is turned on,
# so each entry carries the domain that answers for it.
#
# One line per endangered slug:
#   device=trackpad slug=three-finger-tap claimed=yes key=... value=1 domain=...
#
# claimed=yes   the preference is set to a non-zero value
# claimed=no    the preference is set to zero
# claimed=default  the preference is absent, so the macOS default applies and
#                  this script cannot tell whether the trigger is claimed
#
# src/SystemGestureClaims.m holds the same table for the warnings Trickpad shows
# when it loads a configuration. scripts/check.sh keeps the two identical.

MOUSE_DOMAINS="com.apple.AppleMultitouchMouse"
TRACKPAD_DOMAINS="com.apple.driver.AppleBluetoothMultitouch.trackpad,com.apple.AppleMultitouchTrackpad"

# device:domains:key:slug[,slug...]  Each key names a trigger; the slugs are the
# Trickpad gestures that trigger overlaps.
ENTRIES=(
  "mouse:$MOUSE_DOMAINS:MouseOneFingerDoubleTapGesture:one-finger-tap"
  "mouse:$MOUSE_DOMAINS:MouseTwoFingerDoubleTapGesture:two-finger-tap"
  "mouse:$MOUSE_DOMAINS:MouseTwoFingerHorizSwipeGesture:two-finger-swipe-left,two-finger-swipe-right"
  "mouse:$MOUSE_DOMAINS:MouseHorizontalScroll:one-finger-swipe-left,one-finger-swipe-right"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadTwoFingerDoubleTapGesture:two-finger-tap"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadRightClick:two-finger-tap"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadThreeFingerTapGesture:three-finger-tap"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadThreeFingerHorizSwipeGesture:three-finger-swipe-left,three-finger-swipe-right"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadThreeFingerVertSwipeGesture:three-finger-swipe-up,three-finger-swipe-down"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadFourFingerHorizSwipeGesture:four-finger-swipe-left,four-finger-swipe-right"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadFourFingerVertSwipeGesture:four-finger-swipe-up,four-finger-swipe-down"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadThreeFingerDrag:three-finger-swipe-left,three-finger-swipe-right,three-finger-swipe-up,three-finger-swipe-down"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadFourFingerPinchGesture:index-to-pinky,pinky-to-index"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadFiveFingerPinchGesture:index-to-pinky,pinky-to-index"
  "trackpad:com.apple.universalaccess:closeViewTrackpadGestureZoomEnabled:three-finger-tap"
)

# Echoes "domain value", or "- -" when no domain carries the key.
read_preference() {
  local key="$1" domains="$2" domain value
  for domain in ${(s.,.)domains}; do
    if value="$(defaults read "$domain" "$key" 2>/dev/null)"; then
      echo "$domain $value"
      return
    fi
  done
  echo "- -"
}

for entry in "${ENTRIES[@]}"; do
  device="${entry%%:*}"
  rest="${entry#*:}"
  domains="${rest%%:*}"
  rest="${rest#*:}"
  key="${rest%%:*}"
  slugs="${rest#*:}"
  read -r domain value <<< "$(read_preference "$key" "$domains")"
  if [[ "$value" == "-" ]]; then
    claimed="default"
  elif [[ "$value" == "0" ]]; then
    claimed="no"
  else
    claimed="yes"
  fi
  for slug in ${(s.,.)slugs}; do
    echo "device=$device slug=$slug claimed=$claimed key=$key value=$value domain=$domain"
  done
done
