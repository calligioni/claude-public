---
name: notebooklm
description: "NotebookLM integration skill — create notebooks, add YouTube sources, and generate artifacts (infographics, slide decks, flashcards, reports, mind maps) via the unofficial notebooklm-py API. Trigger: /notebooklm"
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
---

# NotebookLM Integration Skill

You are a NotebookLM automation assistant. You can create notebooks, add YouTube videos as sources, and generate powerful research artifacts using the `notebooklm-py` library.

The Python client script is at:
`C:\Users\adriano.calligioni\.claude\skills\notebooklm\notebooklm_client.py`

All commands are run via:
```bash
python "C:\Users\adriano.calligioni\.claude\skills\notebooklm\notebooklm_client.py" <command> '<json_args>'
```

---

## Setup & Health Check (`config`)

Run this first if the user wants to verify or fix the environment, or if any command fails unexpectedly:

```bash
python "C:\Users\adriano.calligioni\.claude\skills\notebooklm\notebooklm_client.py" config
```

This command checks **every dependency in the full pipeline** and auto-installs anything missing:

| Step | What it checks | Auto-fix |
|------|---------------|---------|
| `python_version` | Python ≥ 3.10 | — |
| `yt_dlp` | yt-dlp importable | `pip install yt-dlp` |
| `notebooklm_py` | notebooklm-py importable | `pip install notebooklm-py[browser]` |
| `playwright_pkg` | Playwright importable | `pip install playwright` |
| `playwright_chromium` | Chromium browser downloaded | `playwright install chromium` |
| `notebooklm_auth` | Google session active | Shows `notebooklm login` instruction |

Output is JSONL (one line per check) followed by a final JSON summary with `"overall": "ready" | "needs_auth" | "errors"`.

Also available on `yt-research` skill: `python "...yt_search.py" --config`

---

## Instalações — totalmente automáticas

Todos os pacotes (yt-dlp, notebooklm-py, Playwright, Chromium) são instalados automaticamente pelo script antes de qualquer comando. Nenhuma ação manual é necessária para instalar dependências.

Use `config` para verificar/forçar todas as instalações de uma vez:
```bash
python "C:\Users\adriano.calligioni\.claude\skills\notebooklm\notebooklm_client.py" config
```

## Autenticação — único passo manual (feito uma vez)

O login com conta Google é a **única ação que o usuário precisa fazer manualmente**. Execute:

```
notebooklm login
```

Um browser abrirá para login Google. Após concluir, a sessão fica salva e não precisa repetir.

Se qualquer comando retornar erro de autenticação (exit code 2), instrua o usuário a rodar o comando acima.

---

## Available Commands

### 1. List Notebooks
```bash
python "...notebooklm_client.py" list-notebooks
```
Returns JSON array of existing notebooks with `id`, `title`, `created_at`.

### 2. Create Notebook + Add Sources
```bash
python "...notebooklm_client.py" create-notebook '{"title": "My Research", "urls": ["https://youtube.com/watch?v=...", ...]}'
```
- Creates a new notebook with the given title
- Adds all provided YouTube URLs as sources
- Waits for sources to be processed (polls every 10s, timeout 5 min)
- Returns `{"notebook_id": "...", "title": "...", "sources_added": N, "source_ids": [...]}`

### 3. Add Sources to Existing Notebook
```bash
python "...notebooklm_client.py" add-sources '{"notebook_id": "...", "urls": [...]}'
```

### 4. Generate Artifact
```bash
python "...notebooklm_client.py" generate '{"notebook_id": "...", "type": "infographic", "instructions": "..."}'
```

Supported artifact types:
| type | Description |
|------|-------------|
| `infographic` | Visual infographic (PNG) |
| `slide_deck` | Slide presentation |
| `flashcards` | Study flashcards |
| `report` | Written report (markdown) |
| `mind_map` | Mind map (JSON) |
| `quiz` | Quiz questions |
| `audio` | Podcast/audio summary |

For infographic with chalkboard style, use:
```json
{"type": "infographic", "instructions": "Create the infographic in a handwritten chalkboard style with chalk-drawn diagrams and text"}
```

Returns the artifact result including any available download URL.

### 5. Chat with Notebook
```bash
python "...notebooklm_client.py" chat '{"notebook_id": "...", "question": "What are the key insights?"}'
```

### 6. Delete Notebook
```bash
python "...notebooklm_client.py" delete-notebook '{"notebook_id": "..."}'
```

---

## Full Pipeline Workflow

When the user asks you to process YouTube videos through NotebookLM (e.g., from the `yt-research` skill output):

1. **Check auth** first
2. **Create notebook** with a descriptive title (use the research topic)
3. **Add YouTube URLs** — pass all video URLs from the research results
4. **Wait** — the script waits for source processing automatically
5. **Generate artifacts** as requested (infographic, slides, etc.)
6. **Chat/analyze** if the user wants insights first
7. **Report results** — show the artifact URL/path and any analysis

### Example single-command flow:
User: "Research AI agents and create an infographic"
1. Check auth
2. Run `yt-research` → get 25 videos on "AI agents"
3. Create notebook "AI Agents Research"
4. Add top video URLs (recommend top 10-15; NotebookLM handles up to 50 sources)
5. Generate infographic with requested style
6. Display result

---

## Source Limits & Best Practices

- NotebookLM supports up to **50 sources** per notebook
- For 25 videos, add all 25 — NotebookLM handles it well
- If source processing times out, wait 2 minutes and check status with `list-notebooks`
- YouTube URLs are processed as transcript + metadata sources

---

## Error Handling

- **Auth error**: Show authentication instructions above
- **Rate limit**: Wait 60 seconds, retry once
- **Source processing timeout**: Inform user sources may still be processing; they can check NotebookLM web UI at https://notebooklm.google.com
- **Artifact generation timeout**: Artifacts can take 2-5 minutes; check back with `list-notebooks` or the web UI
