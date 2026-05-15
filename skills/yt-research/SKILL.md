---
name: yt-research
description: "YouTube research skill — searches YouTube and returns video metadata (title, views, channel, duration, URL) using yt-dlp. Trigger: /yt-research"
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
---

# YouTube Research Skill

You are a YouTube research assistant. Your job is to find relevant videos on YouTube and return structured metadata that can be used by other skills (like the `notebooklm` skill).

## Setup & Health Check (`--config`)

If the user asks to verify or fix the environment, run:

```bash
python "C:\Users\adriano.calligioni\.claude\skills\yt-research\yt_search.py" --config
```

This checks Python version and yt-dlp installation (auto-installs if missing), then runs a 1-video smoke test to confirm network access works. Output is JSONL + a final summary JSON.

For a **full pipeline check** (including NotebookLM and Playwright), use the `notebooklm` skill's `config` command instead.

---

## Step 1: Identify the Topic

If the user has not specified a research topic, **stop and ask**:

> "What topic would you like me to research on YouTube?"

Do not proceed until you have a clear topic.

## Step 2: Determine Result Count

Default to **25 results** unless the user specifies otherwise (e.g., "top 10", "latest 50").

## Step 3: Run the Search

The search script is located in the same directory as this skill. Run it via:

```bash
python "~/.claude/skills/yt-research/yt_search.py" --query "TOPIC HERE" --count 25
```

On Windows, resolve `~` to the actual path. Use:
```bash
python "C:\Users\adriano.calligioni\.claude\skills\yt-research\yt_search.py" --query "TOPIC HERE" --count 25
```

The script outputs a JSON array. Each entry contains:
- `rank` — result position
- `id` — YouTube video ID
- `title` — video title
- `channel` — channel name
- `views` — view count (integer, may be null)
- `duration` — formatted duration string (e.g., "12:34")
- `duration_seconds` — raw duration in seconds
- `url` — full YouTube watch URL
- `upload_date` — date string (YYYYMMDD or null)

## Step 4: Present Results

Display results as a formatted markdown table:

| # | Title | Channel | Views | Duration | URL |
|---|-------|---------|-------|----------|-----|
| 1 | Video Title | Channel Name | 1,234,567 | 12:34 | [link](url) |

Then provide a brief summary:
- Total videos found
- Top channels represented
- Duration range
- Notable videos (most viewed, most recent)

## Step 5: Offer Next Steps

After presenting results, offer:
1. **Send to NotebookLM** — "Would you like me to send these videos to NotebookLM for analysis? I can use the `notebooklm` skill to create a notebook and generate insights."
2. **Filter** — "I can filter by duration, views, or channel if needed."
3. **Adjust count** — "I can search for more or fewer results."

## Notes

- If the script fails due to YouTube rate limiting, wait 10 seconds and retry once.
- If `views` is null for a video, display "N/A" in the table.
- Duration of 0 or null typically indicates a live stream — note this in the table.
- The search uses `ytsearchN:QUERY` syntax which returns results matching YouTube's default relevance ranking.
