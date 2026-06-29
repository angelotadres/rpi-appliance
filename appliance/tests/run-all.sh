#!/usr/bin/env bash
# Run every off-Pi test for the appliance-image initiative (Phases 1-7). Phase 8 is
# hardware-only and not runnable here. Requires Docker.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

tests=(
  "Phase 1  noVNC container:../sample-app/smoke-test.sh"
  "Phase 2a compose sanitize:sanitize.sh"
  "Phase 2b compose deploy:phase2-deploy.sh"
  "Phase 3a usb preflight:usb-preflight.sh"
  "Phase 3b usb store:phase3-usb.sh"
  "Phase 4  read-only root:phase4-readonly.sh"
  "Phase 5  secure access (ssh):phase5-ssh.sh"
  "Phase 6  first-boot orchestration:phase6-firstboot.sh"
  "Phase 7  image assembly:phase7-assemble.sh"
)

fails=0
for entry in "${tests[@]}"; do
  name="${entry%%:*}"; script="${entry##*:}"
  echo "============================================================"
  echo ">>> $name  ($script)"
  echo "============================================================"
  if bash "$HERE/$script" >/tmp/appliance-test.$$ 2>&1; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"; tail -20 /tmp/appliance-test.$$; fails=$((fails+1))
  fi
  rm -f /tmp/appliance-test.$$
done

echo "============================================================"
[ "$fails" -eq 0 ] && echo "ALL OFF-PI TESTS PASSED" || echo "$fails TEST GROUP(S) FAILED"
[ "$fails" -eq 0 ]
