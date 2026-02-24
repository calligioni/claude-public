---
description: Build project user manual (MkDocs) with optional Word export
argument-hint: [format: html|word|screenshots [url]]
allowed-tools: Bash, Read, Glob, Write, mcp__chrome-devtools__*
---

## Argument Syntax
- `$0` - First argument
- `$1` - Second argument
- `$ARGUMENTS` - Full argument string
- `$ARGUMENTS[0]` - Indexed access

Build the user manual for the current project.

## Arguments

- `$1` (optional): Output format or command
  - `html` or empty: Build MkDocs site
  - `word`: Build and convert to Word document
  - `screenshots [base_url]`: Capture screenshots from running application

## Instructions

### Step 1: Detect Manual Configuration

Look for manual configuration in the current directory:

1. Check for `mkdocs-manual.yml` (preferred)
2. Check for `mkdocs.yml` with `docs_dir: manual`
3. Check for a `manual/` directory with markdown files
4. Check for a `Makefile` with a `manual` target

```bash
# Check what's available
ls -la mkdocs*.yml 2>/dev/null
ls -la Makefile 2>/dev/null
ls -la manual/ 2>/dev/null | head -10
```

### Step 2: Build HTML Documentation

If a Makefile with `manual` target exists:

```bash
make manual
```

Otherwise, build directly with mkdocs:

```bash
python3 -m mkdocs build -f mkdocs-manual.yml --strict
```

Or if only `mkdocs.yml` exists:

```bash
python3 -m mkdocs build --strict
```

### Step 3: Word Export (if requested)

If the user requested `word` format:

a. Ensure pandoc is installed:

```bash
which pandoc || brew install pandoc
```

b. Read the MkDocs config to extract navigation and metadata:

```bash
# Read the mkdocs config file
cat mkdocs-manual.yml 2>/dev/null || cat mkdocs.yml
```

c. Extract key info from the config:

- `docs_dir`: Source directory for markdown files (default: `docs` or `manual`)
- `site_name`: Used as document title
- `site_author`: Used as document author
- `nav`: Navigation structure defines file order

d. Build the list of markdown files in navigation order from the `nav:` section.

- Parse each entry under `nav:`
- For entries like `- Section: file.md`, extract `file.md`
- For nested entries, extract all `.md` files recursively
- Prefix each file with the `docs_dir` path

e. Combine and convert:

```bash
# Example (adapt based on actual nav structure):
cd <docs_dir> && cat \
  file1.md \
  section/file2.md \
  ... \
  > /tmp/manual_combined.md && \
pandoc /tmp/manual_combined.md \
  -o "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads/manual/Manual_<ProjectName>.docx" \
  --toc \
  --toc-depth=3 \
  -f markdown \
  -t docx \
  --metadata title="<site_name>" \
  --metadata author="<site_author>"
```

### Step 4: Report Results

For HTML:

- Report the output directory (from `site_dir` in config, default: `./site/` or `./site-manual/`)
- Mention preview command: `make serve-manual` or `mkdocs serve -f <config>`

For Word:

- Report the Word document path: `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads/manual/Manual_<ProjectName>.docx`
- Ensure the output directory exists before writing

## Configuration Detection

The command auto-detects project configuration:

| Config File         | docs_dir | site_dir    | Notes                      |
| ------------------- | -------- | ----------- | -------------------------- |
| `mkdocs-manual.yml` | manual   | site-manual | Preferred for user manuals |
| `mkdocs.yml`        | docs     | site        | Standard MkDocs            |
| `manual/` dir only  | manual   | site-manual | Fallback                   |

---

## Screenshot Quick Start

For the fastest path to screenshots:

1. **Start your app locally** (e.g., `npm run dev`)

2. **Add directives to your docs** where you want screenshots:
   ```markdown
   <!-- screenshot: dashboard path=/dashboard -->
   ```

3. **Run the capture**:
   ```
   /manual screenshots http://localhost:3000
   ```

4. **Build the manual**:
   ```
   /manual
   ```

The skill will capture screenshots and embed them automatically.

---

### Step 5: Screenshot Capture (if requested)

If the user requested `screenshots [base_url]`:

#### 5a. Setup Screenshot Configuration

1. Determine the base URL (default: `http://localhost:3000`)
2. Find the docs directory (from mkdocs config or default to `manual/`)
3. Create images directory if needed:

```bash
DOCS_DIR="manual"  # or from mkdocs config
mkdir -p "$DOCS_DIR/images/screenshots"
```

4. Look for a `screenshots.yml` or `manual-screenshots.yml` config file:

```yaml
# manual-screenshots.yml (example)
base_url: http://localhost:3000
auth:
  type: cookie  # or 'none', 'basic', 'token'
  login_url: /login
  credentials:
    email: test@example.com
    password: test123

screens:
  - id: dashboard
    path: /dashboard
    description: Main dashboard view
    doc_file: getting-started/dashboard.md
    actions:
      - wait: 2000  # Wait for data to load

  - id: agent-list
    path: /agents
    description: Agent listing page
    doc_file: agents/index.md
    viewport: { width: 1280, height: 800 }

  - id: agent-create-modal
    path: /agents
    description: Agent creation modal
    doc_file: agents/creating.md
    actions:
      - click: "[data-testid='create-agent-btn']"
      - wait: 500

  - id: interview-flow
    path: /interviews/new
    description: Interview flow start
    doc_file: interviews/starting.md
    fullPage: true

  - id: mobile-nav
    path: /dashboard
    description: Mobile navigation
    doc_file: getting-started/dashboard.md
    section: mobile-navigation
    viewport: { width: 375, height: 667 }  # iPhone SE
```

If no config exists, scan the markdown files for `<!-- screenshot: ... -->` directives.

#### 5b. Authentication (if required)

If auth is configured, login first:

```
# Navigate to login page
mcp__chrome-devtools__navigate_page({ type: "url", url: "<base_url>/login" })

# Take snapshot to find form elements
mcp__chrome-devtools__take_snapshot({})

# Fill login form
mcp__chrome-devtools__fill_form({
  elements: [
    { uid: "<email_field_uid>", value: "<email>" },
    { uid: "<password_field_uid>", value: "<password>" }
  ]
})

# Click login button
mcp__chrome-devtools__click({ uid: "<login_btn_uid>" })

# Wait for redirect
mcp__chrome-devtools__wait_for({ text: "Dashboard", timeout: 10000 })
```

#### 5c. Capture Screenshots Loop

For each screen in the config:

```
# 1. Navigate to the page
mcp__chrome-devtools__navigate_page({ type: "url", url: "<base_url><path>" })

# 2. Set viewport if specified
mcp__chrome-devtools__resize_page({ width: <width>, height: <height> })

# 3. Execute any pre-screenshot actions
# For wait:
# Just pause (use a short action sequence)

# For click:
mcp__chrome-devtools__take_snapshot({})  # Get current elements
mcp__chrome-devtools__click({ uid: "<element_uid>" })

# For fill:
mcp__chrome-devtools__fill({ uid: "<element_uid>", value: "<value>" })

# For hover (to show tooltips/dropdowns):
mcp__chrome-devtools__hover({ uid: "<element_uid>" })

# 4. Take the screenshot
mcp__chrome-devtools__take_screenshot({
  filePath: "<docs_dir>/images/screenshots/<id>.png",
  fullPage: <fullPage_if_true>
})
```

#### 5d. Embed Screenshots in Documentation

After capturing screenshots, update the markdown files to include them.

**Option A: Using screenshot directives**

Scan markdown files for directives and replace them:

```markdown
<!-- screenshot: dashboard -->
```

Replace with:

```markdown
![Dashboard](../images/screenshots/dashboard.png)
*Figure: Main dashboard view*
```

**Option B: Append to specific sections**

If `section` is specified in config, find that section in the doc file and add the image after it:

```markdown
### Mobile Navigation

On mobile devices (screen width < 1024px)...

![Mobile Navigation](../images/screenshots/mobile-nav.png)
*Figure: Mobile navigation on iPhone SE*
```

**Option C: Create a screenshots index**

Generate a `screenshots.md` file listing all captured screenshots:

```markdown
# Screenshots Reference

## Dashboard
![Dashboard](./images/screenshots/dashboard.png)
Path: `/dashboard`

## Agent List
![Agent List](./images/screenshots/agent-list.png)
Path: `/agents`

...
```

#### 5e. Screenshot Manifest

Create/update `manual/images/screenshots/manifest.json`:

```json
{
  "capturedAt": "2025-01-25T10:30:00Z",
  "baseUrl": "http://localhost:3000",
  "screenshots": [
    {
      "id": "dashboard",
      "path": "/dashboard",
      "file": "dashboard.png",
      "viewport": { "width": 1280, "height": 800 },
      "docFile": "getting-started/dashboard.md"
    }
  ]
}
```

This allows re-running screenshot capture selectively.

#### 5f. Report Results

After capturing:

```
Screenshot capture complete!

Captured: 8 screenshots
Location: manual/images/screenshots/

Files updated:
- getting-started/dashboard.md (2 screenshots added)
- agents/index.md (1 screenshot added)
- interviews/starting.md (1 screenshot added)

Manifest: manual/images/screenshots/manifest.json

To preview: mkdocs serve -f mkdocs-manual.yml
```

---

## Screenshot Directive Format

You can add screenshot directives directly in markdown files:

```markdown
<!-- screenshot: <id> [options] -->
```

Options (space-separated):

- `path=/some/path` - Override URL path
- `viewport=375x667` - Set viewport size
- `fullpage` - Capture full page
- `click=#selector` - Click element before capture
- `wait=2000` - Wait milliseconds before capture

Examples:

```markdown
<!-- screenshot: dashboard -->

<!-- screenshot: mobile-view viewport=375x667 -->

<!-- screenshot: modal-open click=[data-testid=open-modal] wait=500 -->

<!-- screenshot: full-page path=/settings fullpage -->
```

---

## Screenshot Best Practices

### Naming Convention

Use descriptive, kebab-case IDs:

- `dashboard-overview` not `img1`
- `agent-create-modal` not `screenshot3`
- `mobile-nav-expanded` not `mobile`

### Viewport Sizes

Common sizes to use:

| Name | Width | Height | Use Case |
|------|-------|--------|----------|
| Desktop | 1280 | 800 | Standard desktop |
| Desktop Wide | 1920 | 1080 | Full HD |
| Tablet | 768 | 1024 | iPad portrait |
| Mobile | 375 | 667 | iPhone SE |
| Mobile Large | 414 | 896 | iPhone 11 Pro Max |

### Actions Before Screenshot

Use sparingly - screenshots should show natural state. Valid uses:

- Opening modals/dropdowns that are documentation targets
- Showing hover states for UI documentation
- Demonstrating multi-step flows

### Image Optimization

After capture, optionally optimize images:

```bash
# Using ImageOptim CLI (if installed)
imageoptim manual/images/screenshots/*.png

# Or using pngquant
pngquant --force --ext .png manual/images/screenshots/*.png
```

---

## Examples

**Project with Makefile:**

```
/manual → make manual
/manual word → make manual + pandoc export
/manual screenshots http://localhost:3000 → capture screenshots from running app
```

**Project without Makefile:**

```
/manual → mkdocs build -f mkdocs-manual.yml
/manual word → mkdocs build + pandoc export
/manual screenshots → capture screenshots (uses default localhost:3000)
```

**Screenshot-specific examples:**

```
# Capture all screenshots defined in manual-screenshots.yml
/manual screenshots

# Capture from a specific URL
/manual screenshots https://staging.myapp.com

# Just capture a single screen (add to command)
/manual screenshots http://localhost:3000 --only dashboard
```

---

## Screenshot Configuration Reference

### Full `manual-screenshots.yml` Example

```yaml
# Base URL for the application
base_url: http://localhost:3000

# Authentication (optional)
auth:
  type: cookie  # none | cookie | basic | token
  login_url: /login
  credentials:
    email: demo@example.com
    password: demo123
  # For token auth:
  # token_header: Authorization
  # token_value: Bearer xxx

# Global settings
defaults:
  viewport:
    width: 1280
    height: 800
  format: png
  quality: 90  # for jpeg/webp

# Screenshots to capture
screens:
  # Simple screenshot
  - id: dashboard
    path: /dashboard
    description: Main dashboard overview
    doc_file: getting-started/dashboard.md

  # With custom viewport
  - id: dashboard-mobile
    path: /dashboard
    description: Mobile dashboard view
    doc_file: getting-started/dashboard.md
    section: mobile-navigation
    viewport:
      width: 375
      height: 667

  # With actions
  - id: create-agent-modal
    path: /agents
    description: Agent creation dialog
    doc_file: agents/creating.md
    actions:
      - click: "[data-testid='new-agent-btn']"
      - wait: 500

  # Full page capture
  - id: settings-full
    path: /settings
    description: Full settings page
    doc_file: reference/settings.md
    fullPage: true

  # Element-specific screenshot
  - id: agent-card
    path: /agents
    description: Individual agent card
    doc_file: agents/index.md
    element: "[data-testid='agent-card']:first-child"

  # With hover state
  - id: tooltip-example
    path: /dashboard
    description: Tooltip on hover
    doc_file: reference/ui-components.md
    actions:
      - hover: "[data-tooltip]"
      - wait: 300
```

### Inline Directive Reference

| Directive | Description | Example |
|-----------|-------------|---------|
| `screenshot: <id>` | Basic screenshot | `<!-- screenshot: dashboard -->` |
| `path=<url>` | Custom URL path | `path=/settings/profile` |
| `viewport=WxH` | Set viewport | `viewport=375x667` |
| `fullpage` | Capture full page | `fullpage` |
| `click=<sel>` | Click before capture | `click=#open-modal` |
| `hover=<sel>` | Hover before capture | `hover=.tooltip-trigger` |
| `wait=<ms>` | Wait before capture | `wait=1000` |
| `element=<sel>` | Screenshot element only | `element=.card` |
