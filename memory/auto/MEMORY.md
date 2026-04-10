# Memory Index

## Feedback

- [feedback_blackbox_vs_code_review.md](feedback_blackbox_vs_code_review.md) — Always run code-level review (/cto or /review-changes) in addition to black-box testing (/fulltest-skill) — they catch fundamentally different classes of issues
- [feedback_claudia_vps_only.md](feedback_claudia_vps_only.md) — Any mention of Claudia means VPS — always SSH to /opt/claudia, never check local repo for state
- [feedback_contably_uses_woodpecker.md](feedback_contably_uses_woodpecker.md) — Contably has DUAL CI/CD — both Woodpecker (ci.contably.ai) AND GitHub Actions are active and deploying
- [feedback_github_token_override.md](feedback_github_token_override.md) — Invalid GITHUB_TOKEN env var overrides valid gh keyring credential — always unset it when using gh CLI or git clone
- [feedback_memory_boost_weights.md](feedback_memory_boost_weights.md) — Boost weights for memory search ranking — feedback 3x, user 2x, reference 1.5x, project 1x, with 1.5x recency for last 7 days
- [feedback_nuvini_ir_css_classes.md](feedback_nuvini_ir_css_classes.md) — nuvini-ir site uses section-label/section-title/section-description for styled headers — content-\* variants are unstyled
- [feedback_oke_session_auth.md](feedback_oke_session_auth.md) — OKE kubectl doesn't work with API key auth (Unauthorized) despite correct IAM policies — use Woodpecker CI for all cluster operations
- [feedback_parallel_first.md](feedback_parallel_first.md) — User wants Claude to always prefer parallel processing and swarm execution over sequential — maximize concurrent agents, tool calls, and background tasks
- [feedback_run_guardian_before_deploy.md](feedback_run_guardian_before_deploy.md) — Always run /contably-guardian before deploying Contably to staging or production — never skip it
- [feedback_use_browser_tools.md](feedback_use_browser_tools.md) — Don't ask the user for screenshots — use available browser/fetch tools to check visual state of deployed sites before asking
- [mistake_benchmark_selfdestruct.md](mistake_benchmark_selfdestruct.md) — Claudia benchmark safety-refuse-destructive test literally sent rm -rf /opt/claudia to Agent SDK running as root — nuked the deployment twice

## Projects

- [project_agentwave_deploy.md](project_agentwave_deploy.md) — AgentWave deploys to Contabo VPS via SSH, not Railway
- [project_benchmark_loop_scaleup.md](project_benchmark_loop_scaleup.md) — RESOLVED: Benchmark loop removed (2026-04-09) — too dangerous for autonomous execution (sent rm -rf /opt/claudia twice); compound-review (observe-only) kept
- [project_claudia_memory_v2.md](project_claudia_memory_v2.md) — Claudia Memory v2 — 5-layer composite memory system with nudge, consolidation, and complexity-aware skill generation (ALL PHASES COMPLETE)
- [project_claudia_migration_complete.md](project_claudia_migration_complete.md) — Claudia fully replaced OpenClaw — all features migrated including voice, TTS, STT, proactive scheduler, media support
- [project_claudia_router.md](project_claudia_router.md) — Claudia — TypeScript multi-channel AI agent router on VPS, 10 agents, 6 channels, 4-tier inference, 5-layer memory, 20+ scheduled tasks, dashboard, dispatch queue
- [project_claudia_voice_pipecat.md](project_claudia_voice_pipecat.md) — Claudia voice pipeline migrated from Twilio to Pipecat + Telnyx + Deepgram + Cartesia — real-time streaming voice
- [project_contably_ops.md](project_contably_ops.md) — Contably-ops repo and deal data structure for accounting firm acquisitions — skills, directories, workflow
- [project_esocial_plan.md](project_esocial_plan.md) — Contably eSocial module activation via TecnoSpeed middleware — decisions, phases, and partner strategy
- [project_heartbeat_followup.md](project_heartbeat_followup.md) — RESOLVED: Heartbeat validated and improved (2026-04-09) — state tracking added (heartbeat-state.json), routed to #tech-ops, quiet hours 22:30-04:30 BRT, no split needed
- [project_nuvini_ir_deploy.md](project_nuvini_ir_deploy.md) — nuvini-ir deploys via Cloudflare Pages (wrangler) — build with eleventy, deploy \_site folder, not auto-deployed from git
- [project_woodpecker_ci.md](project_woodpecker_ci.md) — Woodpecker CI running on OKE cluster at ci.contably.ai — replaces OCI DevOps for Contably CI/CD
- [tech_glasswing_vuln_hunting.md](tech_glasswing_vuln_hunting.md) — Anthropic Project Glasswing — $100M+ AI vulnerability initiative using Claude Mythos Preview (83.1% CyberGym repro rate). Glasswing-style prompting added to /cto security analyst.

## Tech Insights

- [tech_agent_sandbox_distrust.md](tech_agent_sandbox_distrust.md) — Security principle for multi-agent systems — enforce isolation at OS/VM layer, not by trusting agent behavior. NanoClaw + Docker Sandbox as reference implementation.
- [tech_ai_platform_attack_surface.md](tech_ai_platform_attack_surface.md) — Attack chain from McKinsey Lilli breach — unauthenticated endpoints + JSON-key SQLi + system prompt write access = full AI platform compromise
- [tech_asmr_memory_retrieval.md](tech_asmr_memory_retrieval.md) — Supermemory ASMR pipeline — 3-agent parallel retrieval (facts/context/temporal) replacing vector DB, ~99% on LongMemEval_s. Open-source ~April 2026.
- [tech_browse_cli.md](tech_browse_cli.md) — gstack browse CLI binary installed at ~/.local/bin/browse — zero-MCP-overhead headless Chromium for browser automation across 10 skills
- [tech_hyperskill_skill_tree.md](tech_hyperskill_skill_tree.md) — HyperSkill auto-generates SKILL.md files from live docs; skill-tree command splits deep docs into navigable index + sub-files to avoid context bloat
- [tech_lightpanda_browser.md](tech_lightpanda_browser.md) — Lightpanda headless browser (Zig, CDP-compatible) — evaluated as Chrome/Browserless replacement, not ready due to missing PDF/Lighthouse/SPA gaps. Revisit Q3 2026.
- [tech_openclaw_rl.md](tech_openclaw_rl.md) — OpenClaw-RL — Princeton async RL framework that trains local AI agents from conversations; unlocks Tier 0 local model self-improvement with Qwen 3.5-4B/8B
- [tech_claude_managed_agents.md](tech_claude_managed_agents.md) — Claude Managed Agents public beta (2026-04-08) — Anthropic's managed agent harness + cloud infra: Agent/Environment/Session/Events model, built-in Bash/file/web/MCP tools, $0.08/session-hour, replaces DIY agent loops
- [tech_managed_agents_test.md](tech_managed_agents_test.md) — Live Managed Agents test (2026-04-09): $0.25, 90s active, works but no win over Agent SDK — don't enable yet, revisit when threads GA + native MCP
- [tech_token_efficient_search.md](tech_token_efficient_search.md) — Web search token efficiency research — Brave LLM Context API has explicit token budget, Exa highlights cut 50-75% tokens, pre-search orchestrator pattern saves 60-70% redundant searches
- [tech_advisor_strategy.md](tech_advisor_strategy.md) — Claude Platform advisor strategy (Sonnet executor + Opus advisor) for cost-efficient agentic sessions

## References

- [reference_cloudflare.md](reference_cloudflare.md) — Cloudflare API token with Zone.DNS edit for all zones, account details, zone IDs, and where credentials are stored
- [reference_cloudflare_nuvini.md](reference_cloudflare_nuvini.md) — Cloudflare API token for nuvini.ai domain DNS — separate account (P@nuvini.co) from main (p@nove.co)
- [reference_oci_contably.md](reference_oci_contably.md) — OCI infrastructure credentials, OCIDs, cluster topology, kubectl auth, and CI/CD pipeline details for Contably
- [reference_openrouter_api.md](reference_openrouter_api.md) — OpenRouter API key for Qwen 3.6 Plus and other models — stored in macOS Keychain and Claudia VPS .env
- [reference_paperclip_vps.md](reference_paperclip_vps.md) — Paperclip AI orchestration running on VPS with 3 companies (Nuvini, Contably, SourceRank) — hybrid claude_local + openclaw_gateway adapters, Nemotron 3 Super via Ollama for CEOs
- [reference_resend_cli.md](reference_resend_cli.md) — Resend CLI (v1.4.1) configured as transactional send channel in /agentmail skill — use for one-way sends from verified domains (contably.ai, xurman.com, agentwave.io)
- [reference_search_api_keys.md](reference_search_api_keys.md) — API keys for web search tools — Brave Search LLM Context API and Exa.ai neural search, stored in macOS Keychain and settings.json
- [reference_telnyx_voice.md](reference_telnyx_voice.md) — Telnyx voice infrastructure — API key in Keychain, Claudia's phone number, connection details
- [reference_vps_connection.md](reference_vps_connection.md) — How to reach the Contabo VPS (Claudia, Paperclip) — Tailscale IP, SSH user, hostname, ports
- [tech_anthropic_harness_design.md](tech_anthropic_harness_design.md) — Planner/generator/evaluator three-agent pattern and structured handoff (no compaction) for long-running agent sessions — from Anthropic engineering post on frontend design
- [tech_hermes_subconscious_pattern.md](tech_hermes_subconscious_pattern.md) — Hermes agent patterns implemented in Claudia — periodic nudge, auto-skill generation, session consolidation, skill self-patch policy

# currentDate

Today's date is 2026-04-10.
