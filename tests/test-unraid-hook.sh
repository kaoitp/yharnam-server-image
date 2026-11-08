#!/usr/bin/env bash
set -euo pipefail
image=$1
work=$(mktemp -d)
cleanup() { docker logs hook-smoke || true; docker rm -fv hook-smoke >/dev/null 2>&1 || true; rm -rf "$work"; }
trap cleanup EXIT
curl -fsSL https://raw.githubusercontent.com/unraid/webgui/master/share/docker/tailscale_container_hook -o "$work/hook"
cat > "$work/tailscale" <<'MOCK'
#!/bin/sh
if [ "$1" = status ]; then echo '{"Self":{"Online":true,"KeyExpiry":null}}'; fi
MOCK
cat > "$work/tailscaled" <<'MOCK'
#!/bin/sh
exit 0
MOCK
chmod 755 "$work" "$work/tailscale" "$work/tailscaled" "$work/hook"
docker run -d --name hook-smoke --network bridge --entrypoint /bin/sh \
  -v "$work/hook:/opt/unraid/tailscale:ro" \
  -v "$work/tailscale:/usr/bin/tailscale:ro" \
  -v "$work/tailscaled:/usr/bin/tailscaled:ro" \
  -e TAILSCALE_USERSPACE_NETWORKING=true -e TAILSCALE_STATE_DIR=/data/.tailscale_state \
  -e 'ORG_ENTRYPOINT=gosu 10001:10001 /usr/bin/tini -- /opt/shadnet/entrypoint.sh' \
  "$image" /opt/unraid/tailscale
ready=false
for i in $(seq 1 30); do
  if docker exec -u 10001:10001 hook-smoke shadnet --admin stats >/dev/null 2>&1; then ready=true; break; fi
  sleep 2
done
[[ "$ready" == true ]]
docker logs hook-smoke 2>&1 | grep -q 'Starting tailscale'
docker logs hook-smoke 2>&1 | grep -q 'Starting container'
! docker logs hook-smoke 2>&1 | grep -q 'ERROR: No root privileges'
docker top hook-smoke -eo pid,uid,comm | awk '$2 == "10001" && $3 == "shadnet" { found=1 } END { exit !found }'
