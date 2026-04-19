# Pre-Push Checklist

Before pushing to GitHub, verify these items:

## ✅ Security Check

- [ ] Review `settings.json` for any hardcoded secrets (should all be `${VAR_NAME}`)
- [ ] Verify `.gitignore` includes `.env` files
- [ ] Check all files for sensitive information
- [ ] Confirm agents/commands don't contain project-specific secrets

## ✅ Configuration Review

- [ ] Update README.md with your GitHub username
- [ ] Review all agent profiles are complete
- [ ] Verify all custom commands are included
- [ ] Check scripts are executable (`chmod +x`)

## ✅ Repository Setup

- [ ] Create GitHub repository (private recommended)
- [ ] Configure git identity
- [ ] Review commit message
- [ ] Test installation script locally first

## ✅ Documentation

- [ ] README.md is clear and complete
- [ ] GITHUB_SETUP.md has correct instructions
- [ ] .env.example has all required variables
- [ ] LICENSE is appropriate

## Quick Commands

```bash
# Security scan
grep -r "sk-\|xox\|ghp_\|secret_\|key_" . --exclude-dir=.git

# Review what will be committed
git status
git diff --cached

# Test install script
./install.sh  # in a test environment

# Commit and push
git add .
git commit -m "Initial commit: Claude Code setup"
git remote add origin https://github.com/YOUR_USERNAME/claude-setup.git
git push -u origin main
```

## After Pushing

- [ ] Verify repository is private
- [ ] Test clone and install on another machine/directory
- [ ] Update README with actual GitHub URL
- [ ] Add repository to your password manager notes
- [ ] Document environment variable sources

## Files Included

Total files: 24

**Configuration:**

- settings.json (MCP servers, default args)
- .env.example (template for environment variables)

**Agents:** (9 files)

- backend-agent.md
- codereview-agent.md
- database-agent.md
- devops-agent.md
- documentation-agent.md
- flight-price-optimizer.md
- frontend-agent.md
- security-agent.md
- fulltesting-agent.md

**Scripts:** (3 files)

- claude-agents (multi-agent launcher)
- claude-snapshot (git snapshots)
- claude-rollback (interactive rollback)

**Commands:** (4 files)

- analyze-deal.md
- financial-model.md
- generate-deck.md
- triage.md

**Skills:** (1 file)

- financial-data-extractor.skill

**Documentation:**

- README.md
- GITHUB_SETUP.md
- AGENT_COORDINATION_GUIDE.md
- LICENSE
- This checklist

**Meta:**

- .gitignore
- install.sh
