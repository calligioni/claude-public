# GitHub Setup Instructions

Follow these steps to push your Claude setup to GitHub.

## 1. Create GitHub Repository

Go to [GitHub](https://github.com/new) and create a new repository:
- Repository name: `claude-setup` (or your preferred name)
- Description: "My personal Claude Code configuration and tools"
- Visibility: **Private** (recommended to keep your config private)
- **Do NOT** initialize with README, .gitignore, or license (we already have these)

## 2. Configure Git

```bash
cd /Volumes/AI/Code/claude-setup

# Set your identity if not already set
git config user.name "Pierre Schurmann"
git config user.email "escotilha@gmail.com"

# Rename branch to main (optional, recommended)
git branch -m master main
```

## 3. Review and Clean Sensitive Data

**IMPORTANT**: Before pushing, review your files for any sensitive data:

```bash
# Check settings.json for hardcoded tokens/secrets
cat settings.json | grep -i "token\|secret\|key\|password"

# Make sure all sensitive values use environment variable syntax: ${VAR_NAME}
```

The current `settings.json` already uses environment variables, but double-check!

## 4. Commit Your Files

```bash
# Stage all files
git add .

# Review what will be committed
git status

# Commit
git commit -m "Initial commit: Claude Code setup with agents, commands, and scripts"
```

## 5. Push to GitHub

Replace `YOUR_USERNAME` with your actual GitHub username:

```bash
# Add remote
git remote add origin https://github.com/YOUR_USERNAME/claude-setup.git

# Push to GitHub
git push -u origin main
```

## 6. Update README

After pushing, update the README.md on GitHub to replace `YOUR_USERNAME` with your actual username in the clone command.

## 7. Test Installation on Another Machine

When you get a new computer:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/claude-setup.git ~/.claude-setup

# Run installation
cd ~/.claude-setup
./install.sh

# Set up environment variables (copy from your password manager)
nano ~/.zshrc  # or ~/.bashrc
# Add your export statements

# Source the profile
source ~/.zshrc
```

## Optional: Keep It Updated

To update your setup when you make changes:

```bash
cd ~/.claude-setup

# Pull latest changes
git pull

# Make your changes...

# Commit and push
git add .
git commit -m "Update: [describe your changes]"
git push
```

## Security Best Practices

1. **Never commit real tokens/secrets** - Always use environment variables
2. **Keep repository private** - Your config may contain project-specific info
3. **Use .gitignore** - Already configured to ignore .env files
4. **Review before pushing** - Always check `git diff` before committing
5. **Use separate .env per machine** - Don't commit actual .env files

## Sync to New Machine Quick Reference

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/claude-setup.git ~/.claude-setup

# 2. Install
cd ~/.claude-setup && ./install.sh

# 3. Setup env vars
cp .env.example ~/.env
nano ~/.env  # Fill in your actual values

# 4. Add to shell profile
echo 'export $(cat ~/.env | xargs)' >> ~/.zshrc
source ~/.zshrc

# 5. Test
claude code
```

Done! 🎉
