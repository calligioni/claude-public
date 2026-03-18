---
name: reference:oci-contably
description: OCI infrastructure credentials, OCIDs, and kubectl auth workaround for Contably OKE clusters
type: reference
---

## OCI Contably Infrastructure

Credentials and OCIDs stored in `/Volumes/AI/Code/contably/.local/oci-credentials.md` (gitignored).

### Key Facts

- **Two OKE clusters**: `contably-oke-prod` (use this) and `contably-oke-staging`
- **Prod cluster OCID**: `ocid1.cluster.oc1.sa-saopaulo-1.aaaaaaaak6kfvaibonj2axticenu2qhhv7ztvk7rhfo3v2yklc3xnftms6ua`
- **OCIR username**: `gr5ovmlswwos/Default/p@nuvini.com.br`
- **OCIR auth token**: macOS Keychain → `security find-internet-password -s 'sa-saopaulo-1.ocir.io' -w`
- **GitHub PAT (OAuth, gh CLI)**: `GITHUB_TOKEN= gh auth token` — works for GitHub API, NOT for OCI DevOps
- **GitHub Classic PAT (OCI DevOps)**: `security find-generic-password -s 'github-classic-pat' -w` — required for OCI DevOps git clone
- **Vault secret update command**: `oci vault secret update-base64` (NOT `update-secret-content`)
- **OCI CLI flag**: Use `--environment-id` (NOT `--deploy-environment-id`)

### kubectl Auth Issue

Local kubectl fails with 401 on OKE Enhanced Clusters (API key auth). OCI Cloud Shell works (session auth).
Workaround: Run kubectl commands via OCI Cloud Shell, or use `oci session authenticate` + `--auth security_token`.
Cloud Shell setup script at: `/Volumes/AI/Code/contably/.local/cloud-shell-setup.sh`

### Script Fixes Applied (complete-oci-setup.sh)

- Changed cluster query to filter by name `contably-oke-prod` (was picking staging as first result)
- Changed DevOps project query to use `data.items[0].id` (project has no display-name)
- Changed `--deploy-environment-id` → `--environment-id` (OCI CLI version difference)
- Changed `oci vault secret update-secret-content` → `oci vault secret update-base64`

### OCI DevOps Pipeline Learnings

- Build source `repository_url` must point to OCI internal mirror URL (not GitHub) when `connection_type=DEVOPS_CODE_REPOSITORY`
- SHELL deploy stages require `container_config` block with `CONTAINER_INSTANCE_CONFIG` shape and network
- Deploy specs must use `component: command` (not `deployment`)
- Deploy specs must use single-step format — multi-step with `${VAR}` in env causes failures
- Set `argument_substitution_mode = "NONE"` on COMMAND_SPEC artifacts to prevent OCI treating `$VAR` as pipeline params
- SHELL stages have NO repo checkout — use `kubectl set image` instead of `kustomize`
- SHELL stages need explicit `oci ce cluster create-kubeconfig --auth resource_principal`
- Dynamic group needs `computecontainerinstance` type for SHELL stage containers
- Force mirror sync: `oci devops repository mirror --repository-id <id>`
- OAuth tokens (`gho_`) don't work for OCI DevOps git clone — need classic PAT (`ghp_`)

### ESO (External Secrets Operator) Learnings

- Use `external-secrets.io/v1` API version (NOT `v1beta1`)
- Oracle provider needs `principalType: UserPrincipal` for API key auth
- Private key must be **PKCS#8** (`BEGIN PRIVATE KEY`), not PKCS#1 — convert with `openssl pkcs8 -topk8 -nocrypt`
- `~/.oci/contably_api_key.pem` has trailing `OCI_API_KEY` junk — strip before using
- Cloud Shell setup gist: https://gist.github.com/escotilha/0746df720cf0eeafba1c287fd30a70a8
