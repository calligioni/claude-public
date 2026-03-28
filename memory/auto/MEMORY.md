# Memory Index

## Feedback

- [feedback_blackbox_vs_code_review.md](feedback_blackbox_vs_code_review.md) — Always run code-level review (/cto or /review-changes) in addition to black-box testing (/fulltest-skill) — they catch fundamentally different classes of issues
- [feedback_github_token_override.md](feedback_github_token_override.md) — Invalid GITHUB_TOKEN env var overrides valid gh keyring credential — always unset it when using gh CLI or git clone
- [feedback_memory_boost_weights.md](feedback_memory_boost_weights.md) — Boost weights for memory search ranking — feedback 3x, user 2x, reference 1.5x, project 1x, with 1.5x recency for last 7 days
- [feedback_parallel_first.md](feedback_parallel_first.md) — User wants Claude to always prefer parallel processing and swarm execution over sequential — maximize concurrent agents, tool calls, and background tasks
- [feedback_run_guardian_before_deploy.md](feedback_run_guardian_before_deploy.md) — Always run /contably-guardian before deploying Contably to staging or production — never skip it

## Projects

- [project_esocial_plan.md](project_esocial_plan.md) — Contably eSocial module activation via TecnoSpeed middleware — decisions, phases, and partner strategy

## Tech Insights

- [tech_agent_sandbox_distrust.md](tech_agent_sandbox_distrust.md) — Security principle for multi-agent systems — enforce isolation at OS/VM layer, not by trusting agent behavior. NanoClaw + Docker Sandbox as reference implementation.
- [tech_ai_platform_attack_surface.md](tech_ai_platform_attack_surface.md) — Attack chain from McKinsey Lilli breach — unauthenticated endpoints + JSON-key SQLi + system prompt write access = full AI platform compromise
- [tech_asmr_memory_retrieval.md](tech_asmr_memory_retrieval.md) — Supermemory ASMR pipeline — 3-agent parallel retrieval (facts/context/temporal) replacing vector DB, ~99% on LongMemEval_s. Open-source ~April 2026.
- [tech_browse_cli.md](tech_browse_cli.md) — gstack browse CLI binary installed at ~/.local/bin/browse — zero-MCP-overhead headless Chromium for browser automation across 10 skills
- [tech_hyperskill_skill_tree.md](tech_hyperskill_skill_tree.md) — HyperSkill auto-generates SKILL.md files from live docs; skill-tree command splits deep docs into navigable index + sub-files to avoid context bloat
- [tech_lightpanda_browser.md](tech_lightpanda_browser.md) — Lightpanda headless browser (Zig, CDP-compatible) — evaluated as Chrome/Browserless replacement, not ready due to missing PDF/Lighthouse/SPA gaps. Revisit Q3 2026.
- [tech_openclaw_rl.md](tech_openclaw_rl.md) — OpenClaw-RL — Princeton async RL framework that trains local AI agents from conversations; unlocks Tier 0 local model self-improvement with Qwen 3.5-4B/8B
- [tech_token_efficient_search.md](tech_token_efficient_search.md) — Web search token efficiency research — Brave LLM Context API has explicit token budget, Exa highlights cut 50-75% tokens, pre-search orchestrator pattern saves 60-70% redundant searches

## References

- [reference_cloudflare.md](reference_cloudflare.md) — Cloudflare API token with Zone.DNS edit for all zones, account details, zone IDs, and where credentials are stored
- [reference_oci_contably.md](reference_oci_contably.md) — OCI infrastructure credentials, OCIDs, cluster topology, kubectl auth, and CI/CD pipeline details for Contably
- [reference_paperclip_vps.md](reference_paperclip_vps.md) — Paperclip AI orchestration running on VPS with 3 companies (Nuvini, Contably, SourceRank) — hybrid claude_local + openclaw_gateway adapters, Nemotron 3 Super via Ollama for CEOs
- [reference_resend_cli.md](reference_resend_cli.md) — Resend CLI (v1.4.1) configured as transactional send channel in /agentmail skill — use for one-way sends from verified domains (contably.ai, xurman.com, agentwave.io)
- [reference_search_api_keys.md](reference_search_api_keys.md) — API keys for web search tools — Brave Search LLM Context API and Exa.ai neural search, stored in macOS Keychain and settings.json
- [tech_anthropic_harness_design.md](tech_anthropic_harness_design.md) — Planner/generator/evaluator three-agent pattern and structured handoff (no compaction) for long-running agent sessions — from Anthropic engineering post on frontend design

# currentDate
Today's date is 2026-03-27.
