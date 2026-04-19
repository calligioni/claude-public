# CTO - Universal AI Technical Advisor

A Claude Code skill that provides CTO-level technical leadership for any project. Get expert guidance on architecture, code quality, security, performance, and strategic technical decisions.

## Why Use This?

- **Context-aware**: Adapts to your codebase and existing patterns
- **Comprehensive**: Covers architecture, security, performance, and code quality
- **Actionable**: Provides prioritized recommendations with implementation guidance
- **Strategic**: Helps with long-term technical decisions, not just quick fixes

## Quick Start

```bash
# In any project directory
claude

# Then invoke the skill
> /cto

# Or trigger naturally with phrases like:
> "Review this codebase as a CTO"
> "Do a security audit"
> "Should we migrate to microservices?"
```

## What It Does

### 1. Architecture Review
- Evaluates system design and component relationships
- Identifies architectural anti-patterns
- Creates Architecture Decision Records (ADRs)

### 2. Code Quality Assessment
- Reviews code organization and structure
- Identifies technical debt
- Recommends refactoring strategies

### 3. Security Audit
- Checks for OWASP Top 10 vulnerabilities
- Reviews authentication patterns
- Evaluates secrets management

### 4. Performance Analysis
- Identifies bottlenecks
- Reviews database patterns
- Recommends caching strategies

### 5. Tech Stack Evaluation
- Assesses current technology choices
- Provides scored comparisons
- Plans migration strategies

## Configuration (Optional)

Create `cto-requirements.md` in your project to guide reviews:

```markdown
# CTO Requirements

## Focus Areas
- [x] Security audit
- [ ] Performance analysis

## Known Issues
1. Authentication needs review
2. Database queries are slow

## Priority Questions
1. Should we add caching?
2. Is our auth implementation secure?
```

## Example Output

```markdown
## CTO Technical Assessment

**Overall Health:** Fair

**Top 3 Priorities:**
1. Fix SQL injection vulnerability in user search - CRITICAL
2. Add proper error handling in API layer - HIGH
3. Implement caching for product catalog - MEDIUM

**Quick Wins Available:**
- Add rate limiting (2 hours)
- Update vulnerable dependencies (1 hour)
- Add security headers (30 minutes)
```

## Triggers

- `/cto`
- "CTO advice"
- "architecture review"
- "tech stack decision"
- "system design"
- "code quality review"
- "security audit"
- "performance review"
- "technical roadmap"
- "refactoring strategy"

## Integration

Works with other skills:

- **autonomous-dev**: CTO identifies issues → autonomous-dev implements fixes
- **fulltest-skill**: CTO reads test reports for additional context
- **cpo-ai-skill**: CTO advises on technical architecture during product development

## Installation

Copy the `cto` folder to your Claude skills directory:

```bash
cp -r skills/cto ~/.claude/skills/
```

## Requirements

- Claude Code CLI
- Optional: Memory MCP (for cross-project learning)

## License

MIT
