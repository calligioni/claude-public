---
name: feedback_oke_session_auth
description: OKE kubectl requires session auth with specific profile — API key auth doesn't have cluster RBAC, deploy pipeline now runs migrations automatically
type: feedback
---

OKE kubectl access requires `oke-session` profile with security_token auth. The DEFAULT API key profile doesn't have cluster RBAC permissions. Session tokens expire after 1 hour.

**Why:** The OKE cluster was set up with session-based auth. The API key user needs an IAM policy (`Allow user ... to manage clusters in compartment ...`) to use API key auth permanently. This hasn't been configured yet.

**How to apply:**

- Don't rely on local kubectl for production operations — use CI/CD pipeline instead
- The GitHub Actions deploy pipeline now runs `alembic upgrade head` automatically before each deploy (added 2026-04-07)
- If kubectl is needed: `oci session authenticate --profile oke-session --region sa-saopaulo-1`, then regenerate kubeconfig
- Future fix: add OCI IAM policy for API key user to get permanent kubectl access
