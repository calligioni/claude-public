#!/bin/bash
# kasm_orphan_cleanup.sh
# Stop Kasm, remove all orphaned/stopped containers (NOT volumes/configs),
# and bring it back up. Use when:
#   - kasm.service is stuck in "activating (start)" for > 5 min
#   - Many "Created" containers (zen_engelbart, amazing_mcnulty, ...) accumulated
#   - Host load average > 8 during boot
#
# Run on the Kasm host as root (or via sudo).

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Must run as root. Try: sudo bash $0"
  exit 1
fi

echo "== STOP KASM =="
systemctl stop kasm.service || true
bash /opt/kasm/current/bin/stop || true

echo
echo "== REMOVE STOPPED CONTAINERS (created/exited) =="
docker ps -a --filter status=created -q | xargs -r docker rm -f
docker ps -a --filter status=exited  -q | xargs -r docker rm -f
docker container prune -f

echo
echo "== AFTER CLEANUP =="
docker ps -a --format "table {{.Names}}\t{{.Status}}"
uptime

echo
echo "== INSTALL ExecStartPre HOOK (idempotent) =="
mkdir -p /etc/systemd/system/kasm.service.d
cat > /etc/systemd/system/kasm.service.d/cleanup.conf <<'EOF'
[Service]
ExecStartPre=/bin/bash -c "/usr/bin/docker ps -a --filter status=created --filter status=exited -q | xargs -r /usr/bin/docker rm -f || true"
TimeoutStartSec=900
EOF
systemctl daemon-reload

echo
echo "== START KASM =="
systemctl start kasm.service &

echo "Watching for ~5 min..."
for i in $(seq 1 15); do
  sleep 20
  echo "--- $((i*20))s ---"
  uptime
  docker ps --format "{{.Names}} {{.Status}}" 2>/dev/null
done

echo
echo "== HTTP TEST =="
curl -sk -o /dev/null -w "HTTP %{http_code} time=%{time_total}s\n" https://localhost/

echo
echo "Done. If kasm_guac / kasm_rdp_gateway / kasm_rdp_https_gateway are still"
echo "in restart-loop with 403/expired-JWT errors, run regen_component_jwts.py."
