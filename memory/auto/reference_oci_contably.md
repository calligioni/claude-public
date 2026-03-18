---
name: reference:oci-contably
description: OCI infrastructure credentials, OCIDs, cluster topology, kubectl auth, and CI/CD pipeline details for Contably
type: reference
---

## OCI Contably Infrastructure

Full credentials stored in `/Volumes/AI/Code/contably/.local/oci-credentials.md` (gitignored).

### Cluster Topology (IMPORTANT)

- **Production traffic is served by the STAGING cluster** — the "staging" label is misleading
- Staging cluster LB IP `137.131.156.136` = the production site (contably.ai)
- The "prod" cluster (`137.131.234.85`) is decommissioned (node pool scaled to 0)
- MySQL is in the staging VCN — only the staging cluster can reach it
- Both VCNs use `10.0.0.0/16` so VCN peering is impossible

### Active Cluster (Production)

| Resource     | Value                                                                                          |
| ------------ | ---------------------------------------------------------------------------------------------- |
| Cluster name | `contably-oke-staging`                                                                         |
| Cluster OCID | `ocid1.cluster.oc1.sa-saopaulo-1.aaaaaaaarqeang2k3wo452nek7zaw5ufjtdmaqxupo6m2zgofckxzb7tcsvq` |
| LB IP        | `137.131.156.136`                                                                              |
| VCN          | `ocid1.vcn.oc1.sa-saopaulo-1.amaaaaaa5wffhzqa3wb5s3jowo4awfwtq3xwerlleusdvozpulcpymanwboa`     |
| Nodes        | 2 (10.0.1.138, 10.0.1.140)                                                                     |

### Decommissioned Cluster (DO NOT USE)

| Resource     | Value                                                                                          |
| ------------ | ---------------------------------------------------------------------------------------------- |
| Cluster name | `contably-oke-prod`                                                                            |
| Cluster OCID | `ocid1.cluster.oc1.sa-saopaulo-1.aaaaaaaak6kfvaibonj2axticenu2qhhv7ztvk7rhfo3v2yklc3xnftms6ua` |
| LB IP        | `137.131.234.85`                                                                               |
| Node pool    | Scaled to 0                                                                                    |
| Why unused   | Different VCN from MySQL, can't reach database                                                 |

### MySQL Database

| Field          | Value                                                                      |
| -------------- | -------------------------------------------------------------------------- |
| Host           | `10.0.2.25`                                                                |
| Port           | `3306`                                                                     |
| User           | `contably`                                                                 |
| Password       | `security find-generic-password -s 'contably-mysql-staging' -w`            |
| Database       | `contably_db`                                                              |
| VCN            | Staging (same as active OKE cluster)                                       |
| CONNECTION_URL | `mysql+asyncmy://contably:<pw>@10.0.2.25:3306/contably_db?charset=utf8mb4` |

### Redis

| Field | Value                                                                  |
| ----- | ---------------------------------------------------------------------- |
| Host  | `10.0.2.150`                                                           |
| Port  | `6379`                                                                 |
| VCN   | Prod VCN (reachable from prod cluster only — NOT from staging cluster) |

**Note:** Redis is in the prod VCN. The staging cluster may not be able to reach it. The API gracefully degrades without Redis (login lockout skipped, session cache skipped).

### Credential Sources (macOS Keychain)

| Credential                      | How to retrieve                                                 |
| ------------------------------- | --------------------------------------------------------------- |
| GitHub PAT (OAuth)              | `GITHUB_TOKEN= gh auth token`                                   |
| GitHub Classic PAT (OCI DevOps) | `security find-generic-password -s 'github-classic-pat' -w`     |
| OCIR Auth Token                 | `security find-internet-password -s 'sa-saopaulo-1.ocir.io' -w` |
| OCIR Username                   | `gr5ovmlswwos/Default/p@nuvini.com.br`                          |
| MySQL Password                  | `security find-generic-password -s 'contably-mysql-staging' -w` |
| Clerk Secret Key                | In `~/.config/cloudflare/.env` as CLERK_SECRET_KEY              |
| Clerk Publishable Key           | `pk_live_Y2xlcmsuY29udGFibHkuYWkk`                              |

### kubectl Auth

Local kubectl fails with API key auth on OKE Enhanced Clusters. Use session auth:

```bash
oci session authenticate --region sa-saopaulo-1 --profile-name oke-session
# Complete browser login, then patch kubeconfig:
# Add --profile oke-session --auth security_token to exec args
```

Sessions expire in 1 hour and CANNOT be refreshed — must re-authenticate each time.

### CI/CD Pipeline

- Build pipeline: WORKING (builds 3 Docker images from OCI mirror)
- Deploy pipeline: WORKING (SHELL stages with rollout restart)
- Mirror syncs from GitHub every 15 min, or force: `oci devops repository mirror --repository-id <id>`
- Deploy specs use `kubectl set image` + `rollout restart` (no kustomize — SHELL stages have no repo checkout)
- `argument_substitution_mode = "NONE"` on command spec artifacts
- Build source URL must be OCI internal mirror URL, NOT GitHub URL

### OCI DevOps Pipeline Learnings

- Build source `repository_url` must point to OCI internal mirror URL when `connection_type=DEVOPS_CODE_REPOSITORY`
- SHELL deploy stages require `container_config` with `CONTAINER_INSTANCE_CONFIG`
- Deploy specs must use `component: command` (not `deployment`)
- OAuth tokens (`gho_`) don't work for OCI DevOps git clone — need classic PAT (`ghp_`)
- Dynamic group needs `computecontainerinstance` for SHELL stage containers
- SHELL stages need explicit `oci ce cluster create-kubeconfig --auth resource_principal`

### ESO (External Secrets Operator)

- Use `external-secrets.io/v1` API version (NOT `v1beta1`)
- Oracle provider needs `principalType: UserPrincipal` for API key auth
- Private key must be PKCS#8 (`BEGIN PRIVATE KEY`), not PKCS#1
- `~/.oci/contably_api_key.pem` has trailing `OCI_API_KEY` junk — strip before using

### DNS (Cloudflare)

All records point to staging cluster LB: `137.131.156.136`
Zone ID: `f2a2214c1188fdb922a2c638bed74442`
API token: `cat ~/.config/cloudflare/.env | grep CLOUDFLARE_API_TOKEN`
