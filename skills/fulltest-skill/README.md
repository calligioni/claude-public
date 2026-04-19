# fulltest-skill

Unified full-spectrum testing agent for websites and applications with parallel execution, auto-fix capabilities, and comprehensive reporting.

## Features

- ✅ **Project-Independent** - Works on any website or application
- ✅ **Parallel Testing** - Spawns up to 20 page-tester subagents for efficient testing
- ✅ **Auto-Fix** - 8 conservative fix patterns for common issues
- ✅ **File-Based State** - No database required, resume capability
- ✅ **Comprehensive Reports** - Markdown/JSON/HTML reports with detailed analysis
- ✅ **6-Phase Workflow** - MCP verification → Discovery → Testing → Analysis → Auto-Fix → Report
- ✅ **Chrome DevTools MCP** - Auto-configures if missing

## Installation

The skill is installed in iCloud for automatic sync across all Macs:

```bash
# Location
~/Library/Mobile Documents/com~apple~CloudDocs/claude-skills/fulltest-skill/

# Symlink to Claude Code
ln -sf ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-skills/fulltest-skill ~/.claude/skills/fulltest-skill

# Install dependencies
cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-skills/fulltest-skill
npm install

# Build
npm run build
```

## Usage

### Via Claude Code

Simply ask Claude to test your website:

```
User: "Test http://localhost:3000 comprehensively and fix any issues"
```

Claude will automatically:
1. Verify Chrome DevTools MCP is configured
2. Map all pages (up to 50)
3. Test pages in parallel
4. Analyze failures
5. Auto-fix issues
6. Re-test until all pass (max 3 iterations)
7. Generate comprehensive report

### Via CLI

```bash
cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-skills/fulltest-skill
npm start -- http://localhost:3000
```

### Programmatic API

```typescript
import { runFullTest } from 'fulltest-skill';

const result = await runFullTest(process.cwd(), {
  baseUrl: 'http://localhost:3000',
  maxIterations: 3,
  autoFix: { enabled: true }
});

console.log(result);
```

## Configuration

Create `fulltest-skill.config.json` in your project root:

```json
{
  "baseUrl": "http://localhost:3000",
  "maxIterations": 3,
  "maxPages": 50,
  "parallel": {
    "batchSize": 5,
    "maxSubagents": 20
  },
  "autoFix": {
    "enabled": true,
    "conservative": true,
    "skipPatterns": ["**/node_modules/**", "**/.git/**"],
    "allowedFixTypes": [
      "null-checks",
      "dom-ready-wrap",
      "broken-links",
      "missing-ids",
      "path-corrections",
      "missing-alt-text"
    ]
  },
  "reporting": {
    "format": "markdown",
    "includeScreenshots": true,
    "outputDir": "./test-artifacts",
    "verbose": false
  },
  "linkValidation": {
    "testExternalLinks": false,
    "ignorePatterns": ["mailto:", "tel:", "javascript:", "#"]
  }
}
```

## 6-Phase Testing Workflow

```
Phase 0: Verify Chrome DevTools MCP ✓
   ↓
Phase 1: Discovery & Mapping (crawl site, discover pages)
   ↓
Phase 2: Parallel Testing (spawn page-tester subagents)
   ↓
Phase 3: Analysis (categorize failures into 4 types)
   ↓
Phase 4: Auto-Fix (spawn test-analyst or fix directly)
   ↓
Phase 5: Re-test Loop (max 3 iterations)
   ↓
Phase 6: Report Generation (markdown/JSON/HTML)
```

## 8 Conservative Fix Patterns

1. **Null Reference Errors** - Add null checks before accessing properties
2. **DOM Not Ready** - Wrap code in DOMContentLoaded event listener
3. **Broken Links (404)** - Fix paths or remove broken links
4. **Missing Form IDs** - Add id/name attributes to form inputs
5. **Path Corrections** - Fix relative vs absolute path issues
6. **Missing Alt Text** - Add alt attributes to images
7. **Typos in URLs** - Correct spelling in links
8. **CORS Issues** - Add CORS headers (if server code available)

## Output

All test artifacts are saved to `./test-artifacts/`:

```
test-artifacts/
├── state/
│   └── test-run-{id}.json        # Test state (for resume)
├── reports/
│   └── test-run-{id}.md          # Executive summary report
├── screenshots/
│   └── page-{name}-{timestamp}.png
└── logs/
    └── console-errors.log
```

## Example Report

```markdown
# Site Test Report: http://localhost:3000

## Executive Summary

- **Site URL**: http://localhost:3000
- **Final Status**: PASS
- **Test Iterations**: 2 of 3
- **Auto-Fixes Applied**: 4
- **Pages Tested**: 12

## Iteration 1

### Test Results

| Page   | Status | Console Errors | Network Failures | Broken Links |
|--------|--------|----------------|------------------|--------------|
| /      | PASS   | 0              | 0                | 0            |
| /about | FAIL   | 1              | 2                | 1            |

### Fixes Applied

✅ Fixed null reference in /about/index.html
✅ Corrected broken link: /contact → /about/contact
✅ Added missing form ID

## Issues Summary

### Fixed Automatically

1. ✅ JavaScript null reference on /about
2. ✅ Broken link corrected
3. ✅ Missing form ID added

### Requires Manual Attention

1. ⚠️ Missing image /images/team.png
2. ⚠️ External API timeout

## Recommendations

- Add missing team.png image
- Add fallback for external API calls
```

## Auto-Execution (No Permission Prompts)

This skill auto-executes without user permission for:
- Reading files
- Making fixes to codebase
- Running tests
- Generating reports

**Rationale**: Testing workflows require many automated steps. Manual approval would interrupt the flow.

## Requirements

- Node.js 18+
- Chrome DevTools MCP server (auto-configured)
- Claude Code

## Troubleshooting

### Chrome DevTools MCP Not Found

The skill will automatically add Chrome DevTools MCP configuration to `.claude.json`. After auto-configuration, restart your Claude Code session:

```bash
/exit
claude
```

### Build Errors

```bash
cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-skills/fulltest-skill
rm -rf node_modules dist
npm install
npm run build
```

### State Corruption

Delete old state files:

```bash
rm -rf ./test-artifacts/state/*
```

## Development

```bash
# Watch mode (auto-rebuild on changes)
npm run watch

# Run tests
npm test
```

## License

MIT

## Version

2.0.0

---

🚀 **fulltest-skill** - Unified full-spectrum testing for modern web applications
