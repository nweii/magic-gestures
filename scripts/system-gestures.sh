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
# A setting can be enabled and still not answer the motion a binding uses, so an
# entry may carry gates. A prerequisite must itself be non-zero before the claim
# applies, and a disqualifier being non-zero means the setting moved to a
# different motion. A gate that is off makes the entry claimed=no; a gate macOS
# has never written makes it claimed=default, because the answer is unproven.
# Gated lines carry a gate= field naming the key that decided it.
#
# src/SystemGestureClaims.m holds the same table for the warnings Trickpad shows
# when it loads a configuration. scripts/check.sh keeps the two identical.

MOUSE_DOMAINS="com.apple.AppleMultitouchMouse"
TRACKPAD_DOMAINS="com.apple.driver.AppleBluetoothMultitouch.trackpad,com.apple.AppleMultitouchTrackpad"

# device:domains:key:slug[,slug...][:prerequisite[:disqualifier]]  Each key names
# a trigger; the slugs are the Trickpad gestures that trigger overlaps. Use "-"
# for a gate an entry does not need but that a later field requires.
ENTRIES=(
  "mouse:$MOUSE_DOMAINS:MouseOneFingerDoubleTapGesture:one-finger-tap"
  "mouse:$MOUSE_DOMAINS:MouseTwoFingerDoubleTapGesture:two-finger-tap"
  "mouse:$MOUSE_DOMAINS:MouseTwoFingerHorizSwipeGesture:two-finger-swipe-left,two-finger-swipe-right"
  "mouse:$MOUSE_DOMAINS:MouseHorizontalScroll:one-finger-swipe-left,one-finger-swipe-right"
  "trackpad:$TRACKPAD_DOMAINS:TrackpadTwoFingerDoubleTapGesture:two-finger-tap"
  # Secondary click answers a two-finger press whether or not tap to click is
  # on, and it stays enabled while moving to a corner, so neither condition on
  # its own means a two-finger tap reaches it.
  "trackpad:$TRACKPAD_DOMAINS:TrackpadRightClick:two-finger-tap:Clicking:TrackpadCornerSecondaryClick"
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

# Echoes "yes", "no", or "default" for one preference value. A value that is not
# a number answers a question this table does not ask: MouseButtonMode holds
# "OneButton" or "TwoButton", and reading either as non-zero would claim every
# motion the key touches. Trickpad reads the same value as unproven, so both
# report the same thing.
claim_for_value() {
  case "$1" in
    -) echo "default" ;;
    0) echo "no" ;;
    <->) echo "yes" ;;
    *) echo "default" ;;
  esac
}

for entry in "${ENTRIES[@]}"; do
  fields=(${(s.:.)entry})
  device="$fields[1]"
  domains="$fields[2]"
  key="$fields[3]"
  slugs="$fields[4]"
  prerequisite="${fields[5]:--}"
  disqualifier="${fields[6]:--}"
  read -r domain value <<< "$(read_preference "$key" "$domains")"
  claimed="$(claim_for_value "$value")"
  gate=""
  # A gate can only take a claim away. An entry macOS has already answered with
  # zero is free whatever its gates say.
  if [[ "$claimed" != "no" && "$prerequisite" != "-" ]]; then
    read -r _ gate_value <<< "$(read_preference "$prerequisite" "$domains")"
    case "$(claim_for_value "$gate_value")" in
      no) claimed="no"; gate="$prerequisite=$gate_value" ;;
      default) claimed="default"; gate="$prerequisite=absent" ;;
    esac
  fi
  # A disqualifier only removes a claim it can prove has moved elsewhere. An
  # absent one proves nothing, so the claim stands.
  if [[ "$claimed" != "no" && "$disqualifier" != "-" ]]; then
    read -r _ gate_value <<< "$(read_preference "$disqualifier" "$domains")"
    if [[ "$(claim_for_value "$gate_value")" == "yes" ]]; then
      claimed="no"
      gate="$disqualifier=$gate_value"
    fi
  fi
  for slug in ${(s.,.)slugs}; do
    line="device=$device slug=$slug claimed=$claimed key=$key value=$value domain=$domain"
    [[ -n "$gate" ]] && line="$line gate=$gate"
    echo "$line"
  done
done
