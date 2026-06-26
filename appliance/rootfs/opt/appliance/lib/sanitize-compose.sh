#!/usr/bin/env bash
# sanitize-compose.sh <input-compose.yml>  ->  sanitized compose on stdout
#
# Enforces the appliance's loopback invariant on a user-supplied compose:
#   - strip EVERY service's published `ports` (nothing reaches the host/LAN), then
#   - republish ONLY the GUI service as 127.0.0.1:${WEB_PORT}:5800.
# Everything else (devices, group_add, privileged, volumes, environment) passes
# through untouched, so USB passthrough is honored for free.
#
# GUI service selection: the service labelled `appliance.gui: "true"`; if none is
# labelled and there is exactly one service, that one; otherwise it is an error.
set -euo pipefail

WEB_PORT="${WEB_PORT:-5800}"
GUI_INTERNAL_PORT=5800

in="${1:-/dev/stdin}"
src="$(cat "$in")"

[[ "$WEB_PORT" =~ ^[0-9]+$ ]] || { echo "sanitize: WEB_PORT must be numeric" >&2; exit 2; }

# Resolve a yq: prefer host binary, fall back to a dockerized one so dev hosts and
# CI need no install. (The image bakes yq in Phase 7.)
run_yq() {
  if [ -n "${YQ_BIN:-}" ]; then "$YQ_BIN" "$@"
  elif command -v yq >/dev/null 2>&1; then yq "$@"
  else docker run --rm -i mikefarah/yq "$@"
  fi
}

# Must have a services map.
if [ "$(printf '%s' "$src" | run_yq '.services | type')" != "!!map" ]; then
  echo "sanitize: compose has no 'services' map" >&2; exit 2
fi

# GUI service name. (Avoid `mapfile`; macOS ships bash 3.2 for off-Pi tests.)
labeled=()
while IFS= read -r line; do [ -n "$line" ] && labeled+=("$line"); done < <(printf '%s' "$src" | run_yq \
  '.services | to_entries | map(select(.value.labels."appliance.gui" == "true")) | .[].key')
all=()
while IFS= read -r line; do [ -n "$line" ] && all+=("$line"); done < <(printf '%s' "$src" | run_yq '.services | keys | .[]')

if [ "${#labeled[@]}" -gt 1 ]; then
  echo "sanitize: more than one service labelled appliance.gui=true" >&2; exit 2
elif [ "${#labeled[@]}" -eq 1 ]; then
  gui="${labeled[0]}"
elif [ "${#all[@]}" -eq 1 ]; then
  gui="${all[0]}"
else
  echo "sanitize: ${#all[@]} services and none labelled appliance.gui=true; cannot pick the GUI service" >&2
  exit 2
fi

# Compose service names are [a-zA-Z0-9._-]; validate before interpolating into yq.
[[ "$gui" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "sanitize: unsafe service name '$gui'" >&2; exit 2; }

printf '%s' "$src" | run_yq \
  "del(.services[].ports) | .services.\"${gui}\".ports = [\"127.0.0.1:${WEB_PORT}:${GUI_INTERNAL_PORT}\"]"
