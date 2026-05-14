---
name: kasm-workspaces-recovery
description: Diagnose and recover a stuck Kasm Workspaces install. Triggers when the host has been off for weeks and the web UI doesn't come up, when kasm_proxy stays "Created" forever, when kasm_guac / kasm_rdp_gateway / kasm_rdp_https_gateway are in restart-loop, or when API logs show "Expired JWT utilized on register_component" / "403 component_log". Covers orphan-container cleanup, systemd ExecStartPre hardening, and forging fresh component JWTs in-place using the kasm_api private key. Requires SSH access to the Kasm host with sudo.
---

# Kasm Workspaces — Stuck Boot & Expired-JWT Recovery

## When to use

Trigger phrases / symptoms:
- "Kasm não sobe depois que reinicio a máquina"
- Web UI on `https://<host>/` is unresponsive or hangs for many minutes after boot
- `kasm_proxy` shows `Created` (never `Up`) for > 5 min after start
- `kasm_guac`, `kasm_rdp_gateway`, `kasm_rdp_https_gateway` in `Restarting (140)` loop
- `docker logs kasm_api` shows repeated `Expired JWT utilized on register_component` / `Error, expired JWT` / `403 /api/component_log`
- `docker compose ps` errors with `KASM_UID is missing a value`
- Many "named-pet" containers (`zen_engelbart`, `amazing_mcnulty`, …) stuck in `Created`
- Host load average > 8 for > 10 min during boot
- Token in `/opt/kasm/current/conf/app/*/...app.config.yaml` has `exp` claim in the past

## Mental model

Kasm uses RS256 JWTs to authenticate its internal components (guac, rdp_gateway, rdp_https_gateway, agent) to the API. Each component has a JWT pinned in its YAML config with a fixed `exp` (default 5 months in 1.18; 3 days `api_token_lifespan_seconds` in some installs). Components renew themselves via `/api/admin/refresh_token` *while still inside the leeway window*. If the host stays off past `exp + leeway`, refresh is rejected and the component crashes — its in-place JWT is now permanently invalid because Kasm doesn't ship a CLI tool to re-issue it. There are TWO independent failure modes that compound:

1. **Boot I/O storm**: `docker compose up -d` reconciling networks/cgroups against dozens of orphaned `Created` user-session containers takes minutes per container; load climbs to 12+; healthchecks time out before `kasm_proxy` can come up.
2. **Expired JWTs**: components are in `Up but unhealthy / restarting` loop because `/api/component_log` returns 403.

Fix #1 first (system has to be responsive to fix #2).

## Phase 1 — Connect & Triage

```bash
# Replace these:
HOST=192.168.15.70
USER=calligioni
SSHPASS=...
SUDOPASS=...

# Plink (Windows) or sshpass (Linux) — examples use plink
plink -ssh -pw "$SSHPASS" $USER@$HOST "echo connected; uname -a; uptime"
```

Run the triage block (sudo password prompted via `-S`):

```bash
echo "$SUDOPASS" | sudo -S bash -c '
docker ps -a --format "table {{.Names}}\t{{.Status}}" | head -40
echo
docker top kasm_webserver_or_api_container 2>/dev/null || true
docker exec kasm_db psql -U kasmapp -d kasm -c "SELECT connection_proxy_id, connection_proxy_type, operational_status, last_reported FROM connection_proxies;"
echo
systemctl status kasm.service --no-pager -l | head -25
uptime
'
```

What you're looking for:
- Number of `Created` containers (anything > 2 is orphan accumulation)
- `kasm.service` stuck in `activating (start)` for > 5 min
- `connection_proxies` rows with `operational_status = missing`
- `last_reported` weeks/months in the past
- Load avg > 6

## Phase 2 — Kill the I/O Storm (cleanup orphans)

This is destructive only of stopped/created containers — never volumes, never config.

```bash
echo "$SUDOPASS" | sudo -S bash -c '
systemctl stop kasm.service
bash /opt/kasm/current/bin/stop                              # full compose down
docker ps -a --filter status=created -q | xargs -r docker rm -f
docker ps -a --filter status=exited -q  | xargs -r docker rm -f
docker container prune -f
docker ps -a
uptime
'
```

You should see ZERO containers and load dropping. If load is still >5 wait 1 min — it's just the 1/5/15-minute averages catching up.

## Phase 3 — Persist the cleanup as a boot hook (prevents recurrence)

This is THE fix for "não sobe depois que reinicia" — it removes orphans *before* `docker compose up -d` runs:

```bash
echo "$SUDOPASS" | sudo -S bash -c '
mkdir -p /etc/systemd/system/kasm.service.d
cat > /etc/systemd/system/kasm.service.d/cleanup.conf <<EOF
[Service]
ExecStartPre=/bin/bash -c "/usr/bin/docker ps -a --filter status=created --filter status=exited -q | xargs -r /usr/bin/docker rm -f || true"
TimeoutStartSec=900
EOF
systemctl daemon-reload
systemctl cat kasm.service | tail -8
'
```

## Phase 4 — Bring Kasm back up & wait

```bash
echo "$SUDOPASS" | sudo -S bash -c '
systemctl start kasm.service &
for i in $(seq 1 30); do sleep 20; echo "--- $((i*20))s ---"; docker ps --format "{{.Names}} {{.Status}}"; done
'
```

Expect ~9-10 min for everything to be `Up`. `kasm_proxy` is the last one. Once it's up, test:

```bash
curl -sk -o /dev/null -w "HTTP %{http_code}\n" https://localhost/
```

Should return `HTTP 200`. UI now reachable on `https://<host>/`.

**If `kasm_guac` / `kasm_rdp_gateway` / `kasm_rdp_https_gateway` are still in restart-loop after this**, you have problem #2 — go to Phase 5.

## Phase 5 — Diagnose JWT expiration

Decode the auth_token from each component config and check `exp`:

```bash
echo "$SUDOPASS" | sudo -S bash -c '
for f in /opt/kasm/current/conf/app/guac/kasmguac.app.config.yaml \
         /opt/kasm/current/conf/app/rdp_gateway/passthrough.app.config.yaml \
         /opt/kasm/current/conf/app/rdp_https_gateway/rdp_https_gateway.app.config.yaml; do
  echo "=== $f ==="
  python3 -c "
import yaml, base64, json, datetime
y = yaml.safe_load(open(\"$f\"))
tok = y[\"api\"][\"auth_token\"]
p = json.loads(base64.urlsafe_b64decode(tok.split(\".\")[1] + \"==\"))
exp = datetime.datetime.utcfromtimestamp(p[\"exp\"])
now = datetime.datetime.utcnow()
print(\"  proxy_id:\", p[\"connection_proxy_id\"])
print(\"  exp UTC :\", exp, \"(expired)\" if exp < now else \"(valid)\")
"
done
'
```

If any token is expired → **the component cannot self-recover; you must forge fresh JWTs**. Continue to Phase 6.

If logs show `Token has been expired beyond the configured refresh period` on `/api/admin/refresh_token`, the **refresh path is permanently closed for these tokens** — only forging new ones works.

## Phase 6 — Forge fresh JWTs (the real fix)

Kasm doesn't expose a CLI for this, but we can run inside the `kasm_api` container's Python interpreter, which has the in-memory access to the `api_private_key` setting (RS256 signing key, base64-stored in DB but transparently decrypted by `db.get_config_setting_value`).

Copy `assets/regen_component_jwts.py` (provided alongside this SKILL) into the host, then run:

```bash
echo "$SUDOPASS" | sudo -S docker cp /tmp/regen_component_jwts.py kasm_api:/tmp/regen_component_jwts.py
echo "$SUDOPASS" | sudo -S docker exec kasm_api python3 /tmp/regen_component_jwts.py
```

What it does, in order:
1. Imports `data.access_postgres.DataAccessPostgres` and `utils` from `/src/api_server`
2. Reads `api_private_key` and `api_token_lifespan_seconds` from `settings` (in-memory decrypted)
3. For each component YAML, decodes the existing JWT to get `connection_proxy_id`
4. Calls `utils.generate_jwt_token(...)` with the proper `JWT_AUTHORIZATION` enum (`GUAC=80`, `RDP_GATEWAY=90`)
5. Re-inserts the proxy row in DB (using the *original* id, so the YAML mapping stays consistent)
6. Writes the new token into the YAML, with `.bak` backup

Then restart the components:

```bash
echo "$SUDOPASS" | sudo -S docker restart kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway
sleep 60
echo "$SUDOPASS" | sudo -S docker logs --since 1m kasm_api 2>&1 | grep -iE 'expired|unauthorized|403' | tail
```

Zero matches in the grep = success. Validate via `connection_proxies` table:

```bash
echo "$SUDOPASS" | sudo -S docker exec kasm_db psql -U kasmapp -d kasm -c \
  "SELECT connection_proxy_type, operational_status, last_reported FROM connection_proxies;"
```

All three rows should be `running` with `last_reported` within the last 30s.

## Important notes & gotchas

- **Do NOT use the Admin UI's "Add Connection Proxy" button** to fix this. The UI's `/api/admin/create_connection_proxy` endpoint:
  - Requires `zone_id` (NOT `zone_name`) or it 500s with `null value in column "zone_id" violates not-null constraint`
  - Returns the new proxy metadata with `auth_token: null` — the UI is supposed to surface the YAML in a popup, but on some installs/versions the popup never appears, leaving you with a broken DB row and no token
  - Allocates a brand-new `connection_proxy_id`, so even if you got the YAML, you'd then have to update every YAML on disk to use the new id, defeating the point
- **The Python forge approach preserves the original `connection_proxy_id`s**, so if the components have any lingering local cache/state keyed by id, it stays consistent.
- The `api_token_lifespan_seconds` default of `259200` (3 days) on some installs is misleading — components auto-refresh inside the leeway window, so 3 days isn't really the rotation period. The rotation only fails when the host has been off for longer than `lifespan + leeway` consecutively.
- `registration_token` (in `auth` category, plain-text once decrypted) can be used as `X-Registration-Token` header to bypass the refresh-leeway check on `/api/admin/refresh_token` — but only if the `connection_proxy_id` still exists in the DB. After this skill ran (which deletes & re-inserts), it works for future renewals automatically.

## Common mistakes when running this skill

| Mistake | Symptom | Fix |
|---|---|---|
| Calling `/api/admin/create_connection_proxy` with `zone_name` instead of `zone_id` | `500 Internal Error`, DB row inserted with `zone_id=NULL` | Always pass `zone_id` (UUID with dashes) |
| Restarting Kasm without removing orphans first | Boot hangs > 15 min, load > 12 | Always run Phase 2 before `systemctl start kasm` |
| Forging JWT but skipping the DB re-insert step | Component returns `Connection Proxy by id (...) not found to look up auth_token` | The script handles this; if you adapt it, keep the `db.create_connection_proxy(...)` call |
| Passing `authorizations=[80]` (int) instead of `[JA.GUAC]` (enum) | `AttributeError: 'int' object has no attribute 'value'` | Use `utils.JWT_AUTHORIZATION.GUAC` / `RDP_GATEWAY` enum members |
| Restarting `kasm_api` after running the forge script | Possibly safe but unnecessary; the script doesn't change API state, only DB rows | Don't restart api/manager/db — just the 3 component containers |

## Files this skill produces / modifies

- `/etc/systemd/system/kasm.service.d/cleanup.conf` — new (orphan-cleanup ExecStartPre)
- `/opt/kasm/current/conf/app/guac/kasmguac.app.config.yaml` — `auth_token` updated, `.bak` saved
- `/opt/kasm/current/conf/app/rdp_gateway/passthrough.app.config.yaml` — same
- `/opt/kasm/current/conf/app/rdp_https_gateway/rdp_https_gateway.app.config.yaml` — same
- `connection_proxies` rows in `kasm_db` — re-inserted with original IDs and fresh tokens

To revert JWT changes: `cp <yaml>.bak <yaml> && docker restart <container>` — but the DB rows will still be the new ones. To fully revert, also delete the new DB rows; but you'd then be back to the broken state. The .bak files are insurance, not a typical revert path.
