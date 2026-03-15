---
name: Cloudflare DNS access
description: Cloudflare API token with Zone.DNS edit for all zones, account details, zone IDs, and where credentials are stored
type: reference
---

## Cloudflare Account

- **Email:** p@nove.co
- **Account ID:** b886a80921ef41357eedbf9ff10f4d01
- **Account Name:** P@nove.co's Account
- **Plan:** Free

## API Tokens

### Edit zone DNS (Zone.DNS - All zones)

- **Token name:** "Edit zone DNS" (third token in dashboard)
- **Permissions:** Zone.DNS
- **Resources:** All zones
- **Where stored:**
  - macOS Keychain (local): `security find-generic-password -s "cloudflare-dns-api-token" -w`
  - Local file: `~/.config/cloudflare/.env`
  - Mac Mini file: `~/.config/cloudflare/.env`
  - VPS: `/root/.openclaw/.env` (as CLOUDFLARE_API_TOKEN)
  - GitHub secret: `escotilha/xurmann-investments` → `CLOUDFLARE_API_TOKEN`

### Wrangler OAuth (Workers/Pages)

- **Scopes:** account:read, zone:read, workers:write, pages:write, ssl_certs:write (NO DNS)
- **Where stored:** `~/Library/Preferences/.wrangler/config/default.toml` (both Mac and Mini)
- **Refresh:** Use offline_access refresh_token with `https://dash.cloudflare.com/oauth2/token`
- **Note:** Does NOT have DNS permissions — use the Edit zone DNS token for DNS operations

### Other tokens (visible in dashboard)

- "Cloudflare Agent (auto-generated)" — Account.Access, Account.Acce... — All accounts
- "Edit zone DNS" — Account.Cloudflare Pages, Account.W... — All accounts (broader)

## Zone IDs

| Domain      | Zone ID                          |
| ----------- | -------------------------------- |
| contably.ai | f2a2214c1188fdb922a2c638bed74442 |

## DNS Management

To add/modify DNS records:

```bash
# Source the token
source ~/.config/cloudflare/.env

# List records
curl -s "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID_CONTABLY/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | python3 -m json.tool

# Add A record
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID_CONTABLY/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"A","name":"subdomain","content":"1.2.3.4","proxied":true,"ttl":1}'
```
