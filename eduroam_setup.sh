#!/usr/bin/env bash

set -euo pipefail

IWD_DIR="/var/lib/iwd"
PROFILE_NAME="eduroam"
OUT_PATH="${IWD_DIR}/${PROFILE_NAME}.8021x"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CERT_PATH_DEFAULT="${SCRIPT_DIR}/network/eduroam_ca_cert.pem"

REALM="chalmers.se"
SERVER_DOMAIN_MASK="eduroam.chalmers.se"

usage() {
  cat <<'USAGE'
Usage: eduroam_setup.sh [--dry-run]

Options:
  --dry-run   Print the generated profile to stdout; do not write /var/lib/iwd/
  -h, --help  Show this help
USAGE
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "Must run as root (try: sudo $0)"
  fi
}

prompt() {
  # prompt <varname> <message> [default]
  local __varname="$1"
  local __msg="$2"
  local __default="${3-}"
  local __val

  if [[ -n "$__default" ]]; then
    read -r -p "$__msg [$__default]: " __val
    __val="${__val:-$__default}"
  else
    read -r -p "$__msg: " __val
  fi

  printf -v "$__varname" '%s' "$__val"
}

prompt_secret() {
  # prompt_secret <varname> <message>
  local __varname="$1"
  local __msg="$2"
  local __val

  read -r -s -p "$__msg: " __val
  printf '\n'
  printf -v "$__varname" '%s' "$__val"
}

assert_single_line() {
  local label="$1"
  local val="$2"
  if [[ "$val" == *$'\n'* || "$val" == *$'\r'* ]]; then
    die "$label must be a single line"
  fi
}

main() {
  local dry_run
  dry_run="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run="yes"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1 (try --help)"
        ;;
    esac
  done

  if [[ "$dry_run" != "yes" ]]; then
    require_root
  fi

  local cid store_password password cert_path

  if [[ "$dry_run" == "yes" ]]; then
    printf '%s\n' "Dry-run: printing iwd 802.1X profile to stdout"
    printf '%s\n\n' "Password is always omitted in dry-run output."
  else
    printf '%s\n' "This writes an iwd 802.1X profile to: $OUT_PATH"
    printf '%s\n\n' "You will be prompted for your Chalmers CID and (optionally) password."
  fi

  cert_path="$CERT_PATH_DEFAULT"
  [[ -r "$cert_path" ]] || die "CA certificate not found/readable: $cert_path"

  prompt cid "Chalmers CID (e.g. abcd12)" ""
  [[ -n "$cid" ]] || die "CID is required"
  assert_single_line "CID" "$cid"
  if [[ "$cid" == *[[:space:]]* ]]; then
    die "CID must not contain spaces"
  fi

  if [[ "$dry_run" == "yes" ]]; then
    store_password="no"
    password=""
  else
    prompt store_password "Store password in profile? (yes/no)" "no"
    assert_single_line "Store password choice" "$store_password"
    case "$store_password" in
      y|Y|yes|YES)
        store_password="yes"
        prompt_secret password "Eduroam password (will be written to disk)"
        [[ -n "$password" ]] || die "Password cannot be empty when storing"
        assert_single_line "Password" "$password"
        ;;
      n|N|no|NO)
        store_password="no"
        password=""
        ;;
      *)
        die "Invalid choice: $store_password (expected yes/no)"
        ;;
    esac
  fi

  if [[ "$dry_run" != "yes" ]]; then
    install -d -m 700 "$IWD_DIR"
  fi

  if [[ "$dry_run" == "yes" ]]; then
    {
      printf '[Security]\n'
      printf 'EAP-Method=PEAP\n'
      printf 'EAP-Identity=%s@%s\n' "$cid" "$REALM"
      printf 'EAP-PEAP-CACert=embed:eduroam_ca_cert\n'
      printf 'EAP-PEAP-ServerDomainMask=%s\n' "$SERVER_DOMAIN_MASK"
      printf 'EAP-PEAP-Phase2-Method=MSCHAPV2\n'
      printf 'EAP-PEAP-Phase2-Identity=%s@%s\n' "$cid" "$REALM"
      printf '\n[Settings]\n'
      printf 'AutoConnect=true\n'
      printf 'AddressRandomization=disabled\n'
      printf '\n[@pem@eduroam_ca_cert]\n'
      cat "$cert_path"
    }
    return 0
  fi

  local tmp
  umask 077
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT

  {
    printf '[Security]\n'
    printf 'EAP-Method=PEAP\n'
    printf 'EAP-Identity=%s@%s\n' "$cid" "$REALM"
    printf 'EAP-PEAP-CACert=embed:eduroam_ca_cert\n'
    printf 'EAP-PEAP-ServerDomainMask=%s\n' "$SERVER_DOMAIN_MASK"
    printf 'EAP-PEAP-Phase2-Method=MSCHAPV2\n'
    printf 'EAP-PEAP-Phase2-Identity=%s@%s\n' "$cid" "$REALM"
    if [[ "$store_password" == "yes" ]]; then
      printf 'EAP-PEAP-Phase2-Password=%s\n' "$password"
    fi
    printf '\n[Settings]\n'
    printf 'AutoConnect=true\n'
    printf 'AddressRandomization=disabled\n'
    printf '\n[@pem@eduroam_ca_cert]\n'
    cat "$cert_path"
  } >"$tmp"

  install -o root -g root -m 600 "$tmp" "$OUT_PATH"

  printf '\nWrote %s (root:root, 0600)\n' "$OUT_PATH"
  if [[ "$store_password" == "yes" ]]; then
    printf '%s\n' "Password stored in profile."
  else
    printf '%s\n' "Password not stored in profile (iwd should prompt via an agent when needed)."
  fi
  printf '%s\n' "If needed: systemctl restart iwd"
}

main "$@"
