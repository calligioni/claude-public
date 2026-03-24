---
name: tech_token_efficient_search
description: Web search token efficiency research — Brave LLM Context API has explicit token budget, Exa highlights cut 50-75% tokens, pre-search orchestrator pattern saves 60-70% redundant searches
type: tech
---

## Token-Efficient Web Search Strategy

### Tool Ranking by Token Efficiency

| Tool                                | Tokens/Query | Best For                                            |
| ----------------------------------- | ------------ | --------------------------------------------------- |
| Exa highlights (maxCharacters=1500) | 500-1,500    | Content research — query-relevant excerpts only     |
| Brave LLM Context (count=5)         | 1,500-2,000  | Discovery + content in one call with hard token cap |
| WebSearch (built-in)                | 150-400      | Titles+URLs only (must follow with fetch)           |
| Firecrawl search                    | 2,000-5,000  | Targeted page extraction, not discovery             |
| SearXNG + Crawl4AI                  | 300-3,000    | Free unlimited, self-hosted on VPS                  |

### Key Patterns

1. **Pre-search in orchestrator:** Orchestrator does 1 broad search, passes URL pool to subagents. Eliminates 60-70% redundant searches.
2. **Highlights over full text:** Exa highlights return only answer-relevant passages. 50-75% fewer tokens with 10% higher accuracy.
3. **Token budget per call:** Brave LLM Context is the ONLY API with explicit `maximum_number_of_tokens` parameter.
4. **Search once, fetch selectively:** Use metadata-only search to find URLs, then fetch only 2-3 most relevant.

### What NOT to use for search

- Tavily: No token cap, 59% more tokens than Firecrawl on same pages
- Jina Search endpoint: 10K tokens fixed cost per query (Reader/fetch endpoint is fine)
- Perplexity Sonar: Pre-synthesized — can't control sources

### Infrastructure

- SearXNG + Crawl4AI deployed on Contabo VPS at /opt/search-stack
- SearXNG: localhost:8888, Crawl4AI: localhost:11235
- Access via Tailscale from Mac

Discovered: 2026-03-17
Source: research — deep research on web search token efficiency
Applied in: deep-research skill, research skill — 2026-03-17 — HELPFUL
Use count: 1
