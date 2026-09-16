#!/usr/bin/env bash
# android-device — enroll and verify a physical Android test device.
#
# This is the canonical source of the helper packaged by
# `harbor-android.lib.mkAndroidDeviceTools` (lib/android-device.nix reads this
# file). Device definitions are local runtime JSON, never Nix inputs: no
# serial enters the Nix store through this helper.
#
#   android-device enroll --serial SERIAL --out FILE [--product PRODUCT] [--adb ADB]
#   android-device verify --definition FILE [--adb ADB]
#
# enroll writes {schemaVersion, adbSerial, product, model} with mode 0600 and
# refuses to overwrite an existing file. verify checks the definition against
# the currently connected USB device and prints the serial on stdout.
# Authorization (which user/profile may be touched) is always the caller's
# decision, never part of the definition.
set -euo pipefail
adb="${ADB:-adb}"

usage() {
  echo "usage: android-device enroll --serial SERIAL --out FILE [--product PRODUCT] [--adb ADB]" >&2
  echo "       android-device verify --definition FILE [--adb ADB]" >&2
  exit 2
}

device_line() { # serial -> prints the `adb devices -l` line or fails
  local serial="$1" line count
  line="$("$adb" devices -l | awk -v s="$serial" 'NR>1 && $1==s {print}')"
  count="$(printf '%s\n' "$line" | grep -c . || true)"
  [[ "$count" == "1" ]] || { echo "android-device: refusing: serial $serial is not uniquely connected" >&2; return 1; }
  [[ "$line" == *" device "* || "$line" == *" device" ]] || { echo "android-device: refusing: serial $serial is not authorized/online" >&2; return 1; }
  [[ "$line" == *"usb:"* ]] || { echo "android-device: refusing: serial $serial is not a USB device" >&2; return 1; }
  printf '%s\n' "$line"
}

getprop() { # serial key -> value without carriage returns
  "$adb" -s "$1" shell getprop "$2" | tr -d '\r'
}

cmd_enroll() {
  local serial="" out="" product=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --serial) serial="${2:-}"; shift 2 ;;
      --out) out="${2:-}"; shift 2 ;;
      --product) product="${2:-}"; shift 2 ;;
      --adb) adb="${2:-}"; shift 2 ;;
      *) usage ;;
    esac
  done
  [[ -n "$serial" ]] || { echo "android-device: refusing: --serial is required" >&2; exit 1; }
  [[ -n "$out" ]] || { echo "android-device: refusing: --out is required" >&2; exit 1; }
  [[ ! -e "$out" ]] || { echo "android-device: refusing: $out exists (remove it explicitly to re-enroll)" >&2; exit 1; }
  device_line "$serial" >/dev/null
  local observed_product model
  observed_product="$(getprop "$serial" ro.product.device)"
  [[ -n "$observed_product" ]] || { echo "android-device: refusing: empty product for $serial" >&2; exit 1; }
  if [[ -n "$product" && "$product" != "$observed_product" ]]; then
    echo "android-device: refusing: product $observed_product does not match --product $product" >&2
    exit 1
  fi
  model="$(getprop "$serial" ro.product.model)"
  umask 077
  printf '{"schemaVersion":1,"adbSerial":%s,"product":%s,"model":%s}\n' \
    "$(jq -Rn --arg v "$serial" '$v')" \
    "$(jq -Rn --arg v "$observed_product" '$v')" \
    "$(jq -Rn --arg v "$model" '$v')" >"$out"
  chmod 0600 "$out"
  echo "android-device: enrolled $observed_product (${model:-unknown model}) as $serial" >&2
}

cmd_verify() {
  local def=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --definition) def="${2:-}"; shift 2 ;;
      --adb) adb="${2:-}"; shift 2 ;;
      *) usage ;;
    esac
  done
  [[ -n "$def" && -f "$def" ]] || { echo "android-device: refusing: definition not found: ${def:-}" >&2; exit 1; }
  local schema serial product
  schema="$(jq -r '.schemaVersion' "$def" 2>/dev/null)" \
    || { echo "android-device: refusing: $def is not valid JSON" >&2; exit 1; }
  [[ "$schema" == "1" ]] || { echo "android-device: refusing: unsupported schemaVersion $schema" >&2; exit 1; }
  serial="$(jq -r '.adbSerial' "$def")"
  product="$(jq -r '.product' "$def")"
  [[ -n "$serial" && "$serial" != "null" ]] || { echo "android-device: refusing: empty adbSerial" >&2; exit 1; }
  [[ -n "$product" && "$product" != "null" ]] || { echo "android-device: refusing: empty product" >&2; exit 1; }
  device_line "$serial" >/dev/null
  local observed
  observed="$(getprop "$serial" ro.product.device)"
  [[ "$observed" == "$product" ]] || {
    echo "android-device: refusing: connected product ${observed:-unknown} does not match definition $product" >&2
    exit 1
  }
  printf '%s\n' "$serial"
}

[[ "${1:-}" == "enroll" ]] && { shift; cmd_enroll "$@"; exit 0; }
[[ "${1:-}" == "verify" ]] && { shift; cmd_verify "$@"; exit 0; }
usage
