# Codebase Cleanup - Usage Examples

This document provides detailed examples of how to use the codebase cleanup skill effectively.

## Quick Start Examples

### Example 1: Basic Cleanup (Safest Approach)

**User Request:**
"Help me clean up my Node.js project at /home/user/my-app"

**Claude's Response Flow:**
1. Runs analysis: `python scripts/analyze_codebase.py /home/user/my-app`
2. Generates markdown report
3. Presents findings with high/medium/low confidence categories
4. Asks: "Would you like to start with high-confidence deletions (temp files, .bak files)?"
5. On approval, creates backup and moves files
6. Provides undo script

### Example 2: Aggressive Cleanup

**User Request:**
"I want to clean up everything unnecessary in my Python project"

**Claude's Response Flow:**
1. Runs full analysis
2. Identifies:
   - 15 .pyc files (unnecessary)
   - 3 .bak files (unnecessary)
   - 5 orphaned modules
   - 2 empty __init__.py files
3. Presents summary: "Found 25 files to review"
4. Offers options:
   - Delete high-confidence only (18 files)
   - Review all files individually
   - Export list for manual review
5. User chooses option 1
6. Creates git branch `cleanup/remove-unused`
7. Deletes files and commits

### Example 3: Conservative Review

**User Request:**
"Show me what unused files I have, but I'll decide what to delete"

**Claude's Response Flow:**
1. Runs analysis
2. Generates detailed report
3. For each category, explains why files are flagged
4. Saves report to `cleanup_report.md`
5. Asks: "Would you like me to create a deletion list that you can review?"
6. Creates `files_to_delete.json` with user's selections
7. User manually reviews and edits
8. Claude executes deletion from edited list

## Interactive Decision Making

### Scenario: Uncertain Files

```
Claude: I found 3 files that might be unused, but I'm not certain:

1. utils/legacy_helper.js (120 lines, last modified 2 years ago)
   - No direct imports found
   - But filename suggests it might be dynamically loaded
   
2. config/old_database.json
   - Not referenced in code
   - But might be used by environment variables
   
3. tests/deprecated_test.js
   - Tests a feature that still exists
   - But test file hasn't been updated in 18 months

Would you like to:
a) Delete all three
b) Review each one individually
c) Keep all and move on
d) Check if these are referenced anywhere else
```

### Scenario: Duplicate Files

```
Claude: I found identical files:
- src/utils/formatter.js (original)
- src/helpers/formatter.js (duplicate)
- lib/format.js (slight variation, 95% similar)

Recommendation: Keep src/utils/formatter.js (most recent, most imports)

Should I:
1. Delete the duplicates and update imports
2. Show me the differences first
3. Keep all for now
```

## Command-Line Examples

### Manual Script Usage

```bash
# Step 1: Analyze codebase
python scripts/analyze_codebase.py /path/to/project \
  --exclude cache tmp build \
  --output analysis.json

# Step 2: Generate readable report
python scripts/generate_report.py analysis.json \
  --output cleanup_report.md

# Step 3: Create deletion list
cat > files_to_delete.json << EOF
{
  "files": [
    "temp/old_file.js",
    "backup/data.bak",
    ".DS_Store"
  ]
}
EOF

# Step 4: Delete with backup (dry run first)
python scripts/safe_delete.py /path/to/project \
  --files-list files_to_delete.json \
  --mode move \
  --dry-run

# Step 5: Actually delete
python scripts/safe_delete.py /path/to/project \
  --files-list files_to_delete.json \
  --mode move

# Step 6: If needed, restore
bash undo_deletion.sh
```

## Safety Patterns

### Pattern 1: Incremental Cleanup

1. Start with 100% safe files (.DS_Store, *.bak)
2. Test application
3. Move to high-confidence (orphaned obvious test files)
4. Test again
5. Review medium-confidence files
6. One-by-one deletion with testing

### Pattern 2: Git-Safe Cleanup

```bash
# Create cleanup branch
git checkout -b cleanup/remove-unused

# Let Claude delete files with git mode
# (automatically stages deletions)

# Review changes
git status
git diff --cached

# If good, commit
git commit -m "Remove unused files"

# If bad, discard
git reset --hard HEAD
```

### Pattern 3: Backup-First Cleanup

```bash
# Create timestamped backup
BACKUP_DIR=".cleanup-backup-$(date +%Y%m%d)"

# Let Claude move files there
# Review what was moved
ls -la $BACKUP_DIR

# After confirming all works, delete backup
rm -rf $BACKUP_DIR
```

## Language-Specific Examples

### Node.js/TypeScript Project

**Common unnecessary files found:**
- `node_modules/.cache/` (always safe)
- `*.js.map` files (if not needed)
- `dist/` old builds (if in .gitignore)
- Unused TypeScript `.d.ts` generated files

**Entry points protected:**
- `index.js`, `server.js`, `app.js`
- `package.json`, `tsconfig.json`
- Files referenced in `package.json` scripts

### Python Project

**Common unnecessary files found:**
- `__pycache__/` directories
- `*.pyc`, `*.pyo` compiled files
- `.pytest_cache/`
- Old migration files (needs review)

**Entry points protected:**
- `__init__.py` files
- `main.py`, `app.py`, `manage.py`
- `setup.py`, `pyproject.toml`

## Error Handling

### What if analysis fails?

```
Claude: I encountered an error analyzing some files:
- src/binary_data.bin: binary file (skipped)
- src/huge_file.js: too large (>10MB, skipped)

I was able to analyze 95% of your codebase. 
Would you like to continue with partial results?
```

### What if deletion fails?

```
Claude: Deletion completed with some errors:
✓ Deleted: 15 files
✗ Failed: 2 files (permission denied)
  - /etc/config.json (system protected)
  - logs/active.log (file in use)

The failed files are documented in deletion_log.json.
Would you like to retry with elevated permissions?
```

## Best Practices

1. **Always review before deleting** - Even high-confidence suggestions
2. **Test incrementally** - Don't delete everything at once
3. **Use version control** - Git branches or commits before cleanup
4. **Keep backups for a week** - Don't delete backups immediately
5. **Document decisions** - Note why you kept unusual files
6. **Run tests after cleanup** - Verify nothing broke
7. **Check build/deploy** - Make sure production still works

## Advanced Scenarios

### Large Monorepo

For projects with 10,000+ files:
1. Analyze by subdirectory
2. Focus on high-confidence only
3. Use pagination for results
4. Run cleanup over multiple sessions

### Legacy Codebase

For old projects with unknown dependencies:
1. Start with absolute certainties only
2. Keep everything that's uncertain
3. Document analysis for future reference
4. Very conservative approach

### Active Development

For projects under active development:
1. Check for recent git activity
2. Exclude files modified in last month
3. Focus on ancient files only
4. Coordinate with team before deletion
