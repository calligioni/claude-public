# Web Search Token Efficiency Rules

## Tool Selection Priority

When performing web search, use the most token-efficient tool available:

| Need                  | Best Tool                                                                        | Token Budget        | Fallback  |
| --------------------- | -------------------------------------------------------------------------------- | ------------------- | --------- |
| Quick factual lookup  | Brave Search (`mcp__brave-search__*`) with `count=5`                             | ~1,500-2,000 tokens | WebSearch |
| Content research      | Exa highlights (`mcp__exa__search`) with `highlights=true`, `maxCharacters=1500` | ~500-1,500 tokens   | Firecrawl |
| Discovery (URLs only) | WebSearch (built-in)                                                             | ~150-400 tokens     | Brave     |
| Full page extraction  | Firecrawl scrape with `onlyMainContent=true`                                     | ~3,400 tokens       | WebFetch  |
| High-volume / free    | SearXNG on VPS (localhost:8888 via Tailscale)                                    | ~300-800 tokens     | WebSearch |
| Anti-bot / blocked    | Scrapling → browse CLI                                                           | Variable            | WebFetch  |

## Mandatory Patterns

1. **Always set token limits** when the tool supports it:
   - Brave: `count=5` (discovery) or `count=10` (deep research)
   - Exa: `maxCharacters=1500` (highlights) or `maxCharacters=3000` (deep content)
   - Firecrawl: `onlyMainContent=true` always

2. **Prefer highlights over full text** — Exa highlights return 50-75% fewer tokens with higher accuracy

3. **Search once, fetch selectively** — get URLs first, then fetch only 2-3 most relevant

4. **Pre-search in orchestrator** — when spawning subagents, do broad search first, pass URL pool to subagents to avoid redundant searches

## Fallback Chain

```
Search: Brave → Exa → WebSearch → SearXNG (VPS)
Content: Exa highlights → Firecrawl scrape → WebFetch → Scrapling → browse CLI
Always works: WebSearch + WebFetch (built-in)
```
