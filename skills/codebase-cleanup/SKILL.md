---
name: codebase-cleanup
description: "Identify and remove unused, redundant, or dead code files in a project. Triggers on: clean up unused files, find unnecessary files, remove dead code, codebase cleanup, reduce project bloat."
user-invocable: true
context: fork
agent: Explore
model: sonnet
effort: low
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
tool-annotations:
  Bash: { readOnlyHint: true, idempotentHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
  agent-spawned:
    verbosity: minimal
---

# Codebase Cleanup

This skill analyzes codebases to identify unused or unnecessary files, generates detailed reports, and safely removes files with user permission.

## Workflow

### Step 1: Initial Analysis

**Understand the project structure:**

1. Identify the project root (ask user if unclear)
2. Detect project type (Node.js, Python, Java, etc.) by looking for:
   - `package.json` (Node.js)
   - `requirements.txt`, `pyproject.toml`, `setup.py` (Python)
   - `pom.xml`, `build.gradle` (Java)
   - `Cargo.toml` (Rust)
   - `go.mod` (Go)
3. Identify build/output directories that can be safely excluded
4. Check for `.gitignore` to understand what's already considered unnecessary

**Ask the user:**

- "What's the root directory of your project?"
- "Are there any specific directories or file types you want me to focus on or exclude?"
- "Do you want me to check for unused dependencies as well?"

### Step 2: Comprehensive File Analysis

Run the analysis script to identify unused files:

```bash
python ${CLAUDE_SKILL_DIR}/scripts/analyze_codebase.py <project_root>
```

The script will:

- Map all import/require statements
- Track which files are referenced
- Identify orphaned files (no imports pointing to them)
- Flag common unnecessary files (backup files, temp files, etc.)
- Detect duplicate files
- Find empty or near-empty files
- Identify old configuration files

**Manual checks to perform:**

1. **Check for common unnecessary files:**
   - Backup files: `*.bak`, `*.backup`, `*~`, `.DS_Store`
   - Temporary files: `*.tmp`, `*.temp`, `*.swp`, `.*.sw[p-z]`
   - Log files in version control: `*.log`, `debug.log`
   - IDE files: `.vscode/`, `.idea/` (if in gitignore)
   - OS files: `Thumbs.db`, `desktop.ini`

2. **Look for duplicate functionality:**
   - Multiple similar utility files
   - Duplicate test files
   - Copy-pasted components with minor variations

3. **Check for outdated files:**
   - Old migration files
   - Deprecated API versions
   - Legacy configuration files

4. **Identify dead code:**
   - Unused exported functions/classes
   - Components not imported anywhere
   - Test files for deleted features

### Step 3: Generate Detailed Report

Create a comprehensive markdown report with:

```markdown
# Codebase Cleanup Report

Generated: [date]

## Summary

- Total files analyzed: X
- Unused files found: Y
- Potential space savings: Z MB
- Risk level: Low/Medium/High

## Categories

### 1. Orphaned Files (High Confidence)

Files with no imports/references:

- path/to/file1.js (120 lines)
- path/to/file2.py (45 lines)

### 2. Temporary/Backup Files (High Confidence)

- path/to/file.bak (created 6 months ago)
- .DS_Store files (23 instances)

### 3. Empty or Near-Empty Files (Medium Confidence)

- path/to/empty.js (0 lines)
- path/to/minimal.py (3 lines, only comments)

### 4. Duplicate Files (Medium Confidence)

- path/to/util1.js and path/to/util2.js (95% similar)

### 5. Old Configuration Files (Low Confidence - Review Required)

- old-webpack.config.js (last modified 2 years ago)
- legacy-tsconfig.json

### 6. Unused Dependencies (Review Required)

Package.json contains but never imported:

- lodash
- moment

## Recommendations

### Safe to Delete (High Confidence)

[List files that are very likely safe to delete]

### Review Before Deleting (Medium Confidence)

[List files that probably can be deleted but need review]

### Manual Review Required (Low Confidence)

[List files that might be unused but need careful consideration]

## Next Steps

1. Review the report
2. Confirm which files to delete
3. Create a backup or commit current state
4. Execute deletion
```

Present the report to the user and save it to a file for reference.

### Step 4: Request Permission

**Never delete files without explicit user permission.**

Present the findings and ask:

```
I've identified [X] files that appear to be unused or unnecessary.

High confidence deletions: [N] files
Medium confidence: [M] files
Requires review: [R] files

Would you like to:
1. Delete all high-confidence files now
2. Review each file individually before deletion
3. Create a backup first, then delete
4. Export the list for manual review
5. Cancel cleanup

Please respond with a number (1-5) or describe what you'd like to do.
```

### Step 5: Safe Deletion Process

Based on user choice, execute the appropriate deletion strategy:

**Option 1: Automated deletion with backup**

```bash
# Create backup directory
mkdir -p ./.cleanup-backup-$(date +%Y%m%d-%H%M%S)

# Move files to backup instead of deleting
python ${CLAUDE_SKILL_DIR}/scripts/safe_delete.py \
  --files-list <file_list> \
  --backup-dir <backup_dir> \
  --mode move
```

**Option 2: Interactive deletion**

For each file:

1. Show file path and reason for deletion
2. Show file preview (first 20 lines)
3. Ask: "Delete this file? (y/n/skip remaining)"
4. Track decisions

**Option 3: Git-based safety**

If project uses git:

```bash
# Create a new branch for cleanup
git checkout -b cleanup/remove-unused-files

# Delete files
python ${CLAUDE_SKILL_DIR}/scripts/safe_delete.py \
  --files-list <file_list> \
  --mode delete

# Create commit
git add -A
git commit -m "Remove unused files: [list summary]"

# User can review and merge or revert
```

### Step 6: Post-Deletion Report

After deletion, generate a summary:

```markdown
# Cleanup Completed

## Actions Taken

- Files deleted: X
- Space freed: Y MB
- Backup location: [path or commit hash]

## Deleted Files

[List of all deleted files]

## To Undo

[Instructions for restoring files]

## Next Steps

- Run tests to ensure nothing broke
- Verify application still works
- If all good, can remove backup after [timeframe]
```

## Safety Guidelines

**CRITICAL SAFETY RULES:**

1. **Never delete without permission** - Always get explicit user confirmation
2. **Always create backups** - Before any deletion, create a backup or git branch
3. **Start conservative** - Begin with obvious unnecessary files (`.DS_Store`, `*.bak`)
4. **Verify project type** - Language-specific files may seem unused but be required
5. **Respect .gitignore** - Files in `.gitignore` are usually there for a reason
6. **Check for dynamic imports** - Some files may be loaded dynamically (e.g., `require(variable)`)
7. **Preserve configuration** - Be extremely careful with config files
8. **Keep entry points** - Never suggest deleting main files, index files, or documented entry points
9. **Test after cleanup** - Remind user to run tests after deletion

## Common Pitfalls to Avoid

1. **Dynamic imports**: Files loaded via `require(variableName)` won't show up in static analysis
2. **Asset files**: Images, fonts, etc. might be referenced in CSS or HTML templates
3. **Build artifacts**: Don't analyze files in `dist/`, `build/`, `node_modules/`, etc.
4. **Platform-specific files**: Some files are required by specific platforms but seem unused
5. **Documentation**: README files, examples might not be "used" but are valuable
6. **Test fixtures**: Test data files might not be directly imported but are needed

## Language-Specific Considerations

### JavaScript/TypeScript

- Check for files imported in HTML (`<script src="">`)
- Look for webpack/rollup entry points
- Consider dynamic imports: `import()`, `require()`
- Check `package.json` scripts that might reference files

### Python

- Check `__init__.py` files carefully
- Look for files imported via `importlib`
- Consider `setup.py` and `pyproject.toml` entry points
- Check for files referenced in `MANIFEST.in`

### Java

- Check for reflection-based class loading
- Look at Spring configuration files
- Consider resources referenced in XML configs

### General

- Check CI/CD configuration files (GitHub Actions, GitLab CI, etc.)
- Review Docker files for COPY commands
- Check documentation for referenced examples

## Example Usage

**User:** "Help me clean up my Node.js project"

**Response:**

1. Analyze package.json and project structure
2. Run static analysis on all .js/.ts files
3. Generate report with unused files
4. Request permission with options
5. Execute safe deletion based on user choice
6. Provide post-deletion summary and undo instructions
