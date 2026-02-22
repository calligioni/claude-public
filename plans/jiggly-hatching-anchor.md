# NuvinIA Separation Plan — Standalone OpenClaw Instance

## Context

All 5 phases of Nuvini OS are complete: 41 skills built, dashboard deployed to Vercel, master plan finalized. Currently, Nuvini agents live inside Claudia's OpenClaw instance on the Contabo VPS (100.77.51.51). This plan separates NuvinIA into its own standalone OpenClaw instance so both systems coexist safely and independently. Pierre manages NuvinIA via Orgo.ai (web UI + VMs) or directly via Claude Code.

**Key decisions (confirmed):**

- Separate Anthropic API account: `p@nuvini.com.br`
- New dedicated Discord server for NuvinIA
- Slack `nuvini` workspace moves to NuvinIA
- Agents get new names (see table below) — arnold stays
- Same Contabo VPS, isolated via ports/databases/configs
- **No Vercel** — dashboard hosted on Contabo behind Caddy at `dashboard.nuvini.ai`
- API domain: `nuvinai-api.nuvini.ai`

### Agent Name Mapping

| Old Name  | New Name      | Role         |
| --------- | ------------- | ------------ |
| _(new)_   | **NuvinIA**   | Orchestrator |
| cris      | **aguia**     | M&A          |
| julia     | **jpm**       | Finance      |
| marco     | **atlas**     | Legal        |
| zuck      | **radar**     | Portfolio    |
| bella     | **iris**      | IR           |
| scheduler | **sentinela** | Compliance   |
| arnold    | **arnold**    | Operations   |

---

## Phase 1: VPS Infrastructure Setup

**Goal:** Stand up isolated Docker services + systemd units for NuvinIA on the same VPS.

### Docker Containers

```yaml
# /opt/nuvinai/docker-compose.yml
nuvinai-postgres:
  image: pgvector/pgvector:pg16
  ports: ["5433:5432"]
  volumes: [nuvinai-pgdata:/var/lib/postgresql/data]
  env: POSTGRES_DB=nuvinai, POSTGRES_USER=psm2

nuvinai-redis:
  image: redis:7-alpine
  ports: ["6380:6379"]
```

### Systemd Services

- `nuvinai-gateway.service` — OpenClaw gateway on port **3002**
- `nuvinai-sentinel.service` — autonomous task processor
- `nuvinai-night-shift.service` — night shift worker

### Files to Create on VPS

- `/opt/nuvinai/` — installation directory
- `/opt/nuvinai/docker-compose.yml`
- `/opt/nuvinai/.env` — API keys (Anthropic p@nuvini.com.br, Google Sheets SA, etc.)
- `/root/.nuvinai/openclaw.json` — master config (see Phase 4)
- `/root/.nuvinai/agents/` — agent identity files
- `/etc/systemd/system/nuvinai-gateway.service`
- `/etc/systemd/system/nuvinai-sentinel.service`
- `/etc/systemd/system/nuvinai-night-shift.service`

---

## Phase 2: OpenClaw Installation

**Goal:** Install a second OpenClaw instance pointed at NuvinIA's config directory.

- `npm install -g openclaw` (already installed globally)
- NuvinIA services use `OPENCLAW_HOME=/root/.nuvinai` env var to isolate config
- Gateway binds to `loopback` on port 3002 (known issue: must be `loopback` not `localhost`)
- Verify: `curl http://127.0.0.1:3002/health`

---

## Phase 3: Claudia Cleanup

**Goal:** Remove Nuvini-specific agents and channels from Claudia's config without breaking Claudia.

### Remove from `/root/.openclaw/openclaw.json`

- **Agents to remove:** cris, julia, marco, zuck, bella, scheduler, arnold
- **Channels to remove:** Slack `nuvini` workspace binding
- **Keep:** claudia, buzz, swarmy, and all non-Nuvini channels (Discord ops, Telegram, WhatsApp, Slack contably)

### Restart Claudia services

```bash
systemctl restart openclaw-gateway openclaw-sentinel night-shift-worker
```

---

## Phase 4: NuvinIA Config (`/root/.nuvinai/openclaw.json`)

**Goal:** Configure NuvinIA's agents, channels, plugins, and tools.

### Agents (8 total)

| Agent     | Role             | Model  |
| --------- | ---------------- | ------ |
| NuvinIA   | Orchestrator/CoS | opus   |
| aguia     | M&A              | sonnet |
| jpm       | Finance          | sonnet |
| atlas     | Legal            | sonnet |
| radar     | Portfolio        | sonnet |
| iris      | IR               | sonnet |
| sentinela | Compliance       | sonnet |
| arnold    | Operations       | sonnet |

### Channels

- **Discord:** New NuvinIA server (to be created)
- **Slack:** `nuvini` workspace (migrated from Claudia)

### Plugins

- `memory-postgres` — copy from Claudia's extension, point to `nuvinai-postgres:5433`
- Google Workspace MCP (Sheets, Drive, Docs, Gmail)
- Brave Search MCP

### Config keys

```json
{
  "gateway": { "port": 3002, "bind": "loopback" },
  "database": { "host": "127.0.0.1", "port": 5433, "name": "nuvinai" },
  "redis": { "host": "127.0.0.1", "port": 6380 }
}
```

---

## Phase 5: Agent Identities + Skill Assignments

**Goal:** Create SOUL.md / IDENTITY.md per agent in `/root/.nuvinai/agents/`.

### Skill mapping (41 skills)

- **NuvinIA:** orchestration, delegation, master plan awareness
- **aguia:** mna-pipeline, mna-termsheet, mna-dd-checklist, mna-dd-tracker, mna-ic-brief, mna-integration, mna-nda-gen, mna-market-scan (8)
- **jpm:** finance-closing-orchestrator, finance-consolidation, finance-budget-builder, finance-rolling-forecast, finance-cash-flow-forecast, finance-management-report, finance-earnout-tracker, finance-mutuo-calculator, finance-bank-recon, finance-scenario-modeler, finance-variance-commentary, finance-dre-generator (12)
- **atlas:** legal-compliance-calendar, legal-entity-registry, legal-contract-generator, legal-contract-reviewer, legal-20f-assistant (5)
- **radar:** portfolio-nor-ingest, portfolio-kpi-dashboard, portfolio-acquisition-onboard (3)
- **iris:** ir-capital-register, ir-deck-updater, ir-qna-draft, ir-press-release-draft, ir-earnings-release, ir-investor-tracker, ir-fund-tracker (7)
- **sentinela:** compliance-sec-filing-tracker, compliance-nasdaq-monitor, compliance-board-package, compliance-minutes-drafter, compliance-annual-report, compliance-regulatory-monitor (6)
- **arnold:** portfolio-acquisition-onboard (shared with radar), operational support

---

## Phase 6: Discord + Channel Migration

1. Create new Discord server "NuvinIA" with channels: #general, #m-and-a, #finance, #legal, #compliance, #portfolio, #ir, #ops
2. Create Discord bot application, get token
3. Add bot token to `/opt/nuvinai/.env`
4. Configure Discord channel in `/root/.nuvinai/openclaw.json`
5. Update Slack `nuvini` workspace webhook/token in NuvinIA config
6. Remove Slack `nuvini` from Claudia config (done in Phase 3)

---

## Phase 7: Caddy Reverse Proxy + Orgo.ai Integration

**Goal:** Expose NuvinIA gateway + dashboard via HTTPS on `nuvini.ai` domain.

### Caddy config

```
nuvinai-api.nuvini.ai {
    reverse_proxy 127.0.0.1:3002
}

dashboard.nuvini.ai {
    reverse_proxy 127.0.0.1:3003
}
```

- Add to existing Caddy config on VPS
- Auto-TLS via Let's Encrypt
- DNS: Add A records for `nuvinai-api.nuvini.ai` and `dashboard.nuvini.ai` → `100.77.51.51`

### Orgo.ai

- NuvinIA accessible via Orgo web UI at `nuvinai-api.nuvini.ai`
- Orgo VM tasks can call NuvinIA gateway API
- Add `ORGO_API_KEY` to `/opt/nuvinai/.env` if Orgo needs to trigger tasks

---

## Phase 8: Dashboard on Contabo

**Goal:** Host the Next.js dashboard on Contabo instead of Vercel. Run as a systemd service behind Caddy.

### Setup

- Clone `escotilha/nuvini-os-dashboard` to `/opt/nuvinai/dashboard/`
- `npm install && npm run build`
- Run `next start -p 3003` as systemd service `nuvinai-dashboard.service`
- Caddy proxies `dashboard.nuvini.ai` → `127.0.0.1:3003`

### Connect live data

- `src/lib/data.ts` — replace mock returns with Google Sheets API calls
- `src/app/api/` — add API routes that proxy to NuvinIA gateway at `127.0.0.1:3002`
- `.env` — add Google Sheets service account key, NuvinIA gateway URL

### Data flow

```
Browser → dashboard.nuvini.ai → Caddy → Next.js (:3003) → NuvinIA Gateway (:3002) → Agent skills → Google Sheets
```

---

## Phase 9: Watchdog + Backups + Verification

### Watchdog

- Cron job every 5 min: check `curl http://127.0.0.1:3002/health`
- Alert to Discord #ops if down
- Auto-restart via systemd `Restart=always`

### Backups

- Daily pg_dump of `nuvinai` database → `/opt/nuvinai/backups/`
- Rotate: keep 7 days
- Cron: `0 3 * * * pg_dump -h 127.0.0.1 -p 5433 -U psm2 nuvinai | gzip > /opt/nuvinai/backups/nuvinai-$(date +\%Y\%m\%d).sql.gz`

### Verification Checklist

- [ ] NuvinIA gateway responds on port 3002
- [ ] Dashboard loads at `dashboard.nuvini.ai`
- [ ] Claudia gateway still responds on port 3001 (no Nuvini agents)
- [ ] All 8 NuvinIA agents respond to messages (NuvinIA, aguia, jpm, atlas, radar, iris, sentinela, arnold)
- [ ] Discord bot active in new NuvinIA server
- [ ] Slack nuvini messages route to NuvinIA (not Claudia)
- [ ] Skills execute correctly (test one per agent)
- [ ] Memory plugin stores/retrieves entities in nuvinai-postgres
- [ ] Dashboard shows live data from NuvinIA
- [ ] Orgo web UI can reach `nuvinai-api.nuvini.ai`
- [ ] Backup cron runs and produces valid dumps
- [ ] Claudia continues to function independently

---

## Execution Order

| Step | Phase                         | Swarm Parallelism   |
| ---- | ----------------------------- | ------------------- |
| 1    | Phase 1: Docker + systemd     | Single              |
| 2    | Phase 2: OpenClaw install     | Single              |
| 3    | Phase 3: Claudia cleanup      | Single              |
| 4    | Phase 4: NuvinIA config       | Single              |
| 5    | Phase 5: Agent identities     | Parallel (8 agents) |
| 6    | Phase 6: Discord + channels   | Parallel with 5     |
| 7    | Phase 7: Caddy + Orgo + DNS   | Parallel with 5-6   |
| 8    | Phase 8: Dashboard on Contabo | Single              |
| 9    | Phase 9: Watchdog + verify    | Single              |

Steps 1-4 are sequential (dependencies). Steps 5-7 can be parallelized. Step 8 depends on 1-4 + 7. Step 9 is last.

---

## Repos Involved

- `escotilha/nuvini-os-master-plan` — update status to reflect separation
- `escotilha/nuvini-os-dashboard` — cloned to Contabo, live data wiring
- Skills remain in `~/Library/Mobile Documents/com~apple~CloudDocs/claude-setup/skills/` (shared via iCloud, copied to VPS)

## DNS Records Needed (nuvini.ai)

- `nuvinai-api.nuvini.ai` → A → `100.77.51.51`
- `dashboard.nuvini.ai` → A → `100.77.51.51`
