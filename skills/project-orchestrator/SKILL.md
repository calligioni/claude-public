---
description: Full project orchestrator - analyze, build, test, deploy
argument-hint: [project-path]
allowed-tools: "*"
---

## Argument Syntax
- `$0` - First argument
- `$1` - Second argument
- `$ARGUMENTS` - Full argument string
- `$ARGUMENTS[0]` - Indexed access

# Project Orchestrator

Full project orchestrator that analyzes a codebase, creates an implementation plan, coordinates specialized agents to build it, runs comprehensive testing until all tests pass, then deploys to GitHub and Railway.

## Process

1. Analyze the codebase structure and requirements
2. Create a detailed implementation plan
3. Coordinate Frontend/Backend/Database agents to build features
4. Run fulltesting-agent with auto-fix loop until all tests pass
5. Deploy to GitHub and Railway

## Usage

```
/project-orchestrator
```

The assistant will:

- Analyze your project structure and understand the tech stack
- Create a step-by-step implementation plan
- Spawn specialized agents (Frontend, Backend, Database) in parallel
- Run E2E tests and automatically fix issues
- Deploy the completed project to production

## Output

- Implementation plan
- Built/modified codebase
- Passing test suite
- Deployed application on Railway
- GitHub repository with all changes

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed task chains.

## Best For

- Getting projects from zero to production
- Full-stack feature implementation
- Complex multi-component builds
- Automated testing and deployment pipelines
