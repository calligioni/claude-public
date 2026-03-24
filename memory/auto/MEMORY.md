# Memory Index

## Feedback

- [feedback_blackbox_vs_code_review.md](feedback_blackbox_vs_code_review.md) — Always run code-level review (/cto or /review-changes) in addition to black-box testing (/fulltest-skill) — they catch fundamentally different classes of issues
- [feedback_memory_boost_weights.md](feedback_memory_boost_weights.md) — Boost weights for memory search ranking — feedback 3x, user 2x, reference 1.5x, project 1x, with 1.5x recency for last 7 days
- [feedback_run_guardian_before_deploy.md](feedback_run_guardian_before_deploy.md) — Always run /contably-guardian before deploying Contably to staging or production — never skip it
- [feedback_github_token_override.md](feedback_github_token_override.md) — Invalid GITHUB_TOKEN env var overrides valid gh keyring credential — use `GITHUB_TOKEN= gh ...` to bypass
- [feedback_parallel_first.md](feedback_parallel_first.md) — Always prefer parallel processing and swarms over sequential — maximize concurrent agents, tool calls, and background tasks

## Projects

- [project_esocial_plan.md](project_esocial_plan.md) — Contably eSocial module activation via TecnoSpeed middleware — decisions, phases, and partner strategy

## References

- [reference_cloudflare.md](reference_cloudflare.md) — Cloudflare API token with Zone.DNS edit for all zones, account details, zone IDs, and where credentials are stored
- [reference_resend_cli.md](reference_resend_cli.md) — Resend CLI (v1.4.1) configured as transactional send channel in /agentmail skill — use for one-way sends from verified domains (contably.ai, xurman.com, agentwave.io)
- [tech_agent_sandbox_distrust.md](tech_agent_sandbox_distrust.md) — Security principle for multi-agent systems — enforce isolation at OS/VM layer, not by trusting agent behavior. NanoClaw + Docker Sandbox as reference implementation.
- [tech_ai_platform_attack_surface.md](tech_ai_platform_attack_surface.md) — Attack chain from McKinsey Lilli breach — unauthenticated endpoints + JSON-key SQLi + system prompt write access = full AI platform compromise
- [tech_browse_cli.md](tech_browse_cli.md) — gstack browse CLI binary installed at ~/.local/bin/browse — zero-MCP-overhead headless Chromium for browser automation across 10 skills
- [tech_openclaw_rl.md](tech_openclaw_rl.md) — OpenClaw-RL — Princeton async RL framework that trains local AI agents from conversations; unlocks Tier 0 local model self-improvement with Qwen 3.5-4B/8B
- [tech_hyperskill_skill_tree.md](tech_hyperskill_skill_tree.md) — HyperSkill by Hyperbrowser: auto-generates SKILL.md from live docs + /skill-tree command splits deep-knowledge into navigable hierarchies to avoid context bloat
- [reference_search_api_keys.md](reference_search_api_keys.md) — Brave Search + Exa.ai API keys stored in macOS Keychain (cross-device) and settings.json
- [tech_token_efficient_search.md](tech_token_efficient_search.md) — Web search token efficiency findings: Brave LLM Context (token-budgeted), Exa highlights (50-75% fewer tokens), pre-search orchestrator pattern, SearXNG+Crawl4AI on VPS
- [reference_paperclip_vps.md](reference_paperclip_vps.md) — Paperclip AI orchestration on VPS with 3 companies (Nuvini, Contably, SourceRank) connected to OpenClaw gateway — ports, company IDs, agent roster, architecture
- [reference_oci_contably.md](reference_oci_contably.md) — OCI infrastructure credentials, OCIDs, kubectl auth workaround, and OCIR details for Contably OKE clusters
- [tech_lightpanda_browser.md](tech_lightpanda_browser.md) — Lightpanda headless browser (Zig, CDP) — not ready as Chrome replacement, revisit Q3 2026
- [tech_asmr_memory_retrieval.md](tech_asmr_memory_retrieval.md) — ASMR by Supermemory — 3-agent parallel retrieval (facts/context/temporal) replacing vector DB, ~99% LongMemEval_s. Open-source ~April 2026. Applied to /consolidate, /meditate, /cto.

# currentDate

Today's date is 2026-03-21.
