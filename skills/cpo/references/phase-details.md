# CPO AI Skill - Detailed Phase Instructions

Complete step-by-step instructions for all five phases of the CPO AI workflow.

---

## Phase 1: Product Discovery

**Goal:** Transform a raw product idea into a qualified, scoped product definition.

### Step 1.1: Receive & Acknowledge the Idea

When user provides a product idea:

```
I'll help you build [product name/description]. As your Chief Product Officer AI,
I'll guide this from concept to production.

Let me ask a few strategic questions to properly scope this project.
```

### Step 1.2: Discovery Questions

Ask 5-8 strategic questions with options to quickly qualify the product:

```markdown
## Product Discovery Questions

**1. Target Users & Market**
   Who is the primary user of this product?
   A. Individual consumers (B2C)
   B. Business users/teams (B2B)
   C. Developers/technical users
   D. Internal tool for your organization
   E. Other: [describe]

**2. Core Problem Statement**
   What's the #1 problem this product solves?
   [Free text - be specific about the pain point]

**3. Scope & Complexity**
   What's your target scope?
   A. MVP/Prototype - Core functionality only, fastest path to working product
   B. Feature-complete - All planned features, production quality
   C. Enterprise-ready - Full features + security, scalability, admin tools
   D. Let me help define scope based on the idea

**4. Technical Constraints**
   Any required technologies or constraints?
   A. Web application (specify: React, Vue, Next.js, etc.)
   B. Mobile app (React Native, Flutter, native)
   C. API/Backend only
   D. Full-stack (recommend based on requirements)
   E. Must integrate with: [list systems]

**5. Data & Persistence**
   What data needs to be stored?
   A. Simple data - JSON/file storage is fine
   B. Relational data - PostgreSQL/MySQL
   C. Document data - MongoDB/Firebase
   D. Real-time data - Need live updates
   E. Help me decide

**6. Authentication Requirements**
   Who can access the product?
   A. Public - no login required
   B. Simple auth - email/password
   C. Social login (Google, GitHub, etc.)
   D. Enterprise SSO/SAML
   E. Multiple user roles with permissions

**7. Deployment Target**
   Where should this run?
   A. Local development only (for now)
   B. Cloud hosting (Vercel, Railway, AWS, etc.)
   C. Self-hosted/on-premise
   D. Help me choose based on requirements

**8. Success Criteria**
   How will you know this product is successful?
   [Free text - define measurable outcomes]

Reply with your answers like: "1A, 2: [problem], 3B, 4D, 5B, 6B, 7B, 8: [criteria]"
```

### Step 1.3: Synthesize Product Definition

After receiving answers, create the product definition:

```markdown
## Product Definition: [Product Name]

### Vision Statement
[One sentence describing the product's purpose and value]

### Target User
[Primary user persona based on Q1]

### Problem Statement
[Core problem from Q2]

### Scope
[Scope level from Q3 with implications]

### Technical Stack
[Recommended or specified stack from Q4-Q5]

### Key Features (Prioritized)
1. [Must-have feature 1]
2. [Must-have feature 2]
3. [Should-have feature 1]
...

### Non-Goals (Explicitly Out of Scope)
- [Feature/capability NOT included]
- [Complexity NOT tackled]

### Success Metrics
[From Q8, made measurable]

### Risks & Assumptions
- **Risk**: [potential issue]
- **Assumption**: [what we're assuming is true]
```

### Step 1.4: Research Phase (Product Research Agent)

Before finalizing the product definition, invoke the research agent:

```xml
<Task subagent_type="product-research-agent" prompt="
## Product Research Request

**Product Idea:** [Product name and description]
**Target Market:** [From Q1]
**Core Problem:** [From Q2]

### Research Objectives

1. **Competitor Analysis**
   - Identify top 5 competitors in this space
   - Analyze their features, pricing, and positioning
   - Find gaps and opportunities

2. **Design Inspiration**
   - Find best-in-class UI/UX examples for this product type
   - Collect 5-10 visual references with sources
   - Identify design patterns that work well

3. **Market Validation**
   - Assess market size and trends
   - Identify target user expectations
   - Note any industry-specific requirements

### Deliverables
- competitor-analysis.md
- design-references.md
- market-insights.md
"/>
```

**Incorporate Research Findings:**
- Add competitor insights to product definition
- Include design references for planning phase
- Adjust scope based on market expectations

### Step 1.5: Get Product Definition Approval

```
I've synthesized your product definition above, informed by:
- Competitor analysis: [key findings]
- Design research: [reference products]
- Market insights: [opportunities identified]

Please review and reply with:
- "approved" - Proceed to strategic planning
- "adjust [section]" - Modify specific section
- "questions" - Ask me anything about the approach
```

---

## Phase 2: Strategic Planning

**Goal:** Create a comprehensive, staged implementation plan.

### Step 2.0: Tech Stack & Architecture (CTO Advisor Agent)

Before epic decomposition, get CTO-level technical guidance:

```xml
<Task subagent_type="cto-advisor-agent" prompt="
## Tech Stack Recommendation Request

**Product:** [Product name]
**Scope:** [MVP/Feature-complete/Enterprise]
**Target Scale:** [Expected users, growth trajectory]

### Product Requirements
- [Key features from product definition]
- [Data requirements]
- [Real-time needs]
- [Integration requirements]

### Constraints
- Team size: [N developers]
- Timeline: [Target launch]
- Budget: [If relevant]
- Required technologies: [If any]

### Deliverables Required

1. **Tech Stack Recommendation**
   - Frontend framework with rationale
   - Backend/API approach
   - Database selection
   - Authentication solution
   - Hosting platform

2. **Architecture Overview**
   - High-level system design
   - Key architectural decisions (ADRs)
   - Scalability considerations

3. **Deployment Strategy**
   - Environment structure (dev/staging/prod)
   - CI/CD pipeline configuration
   - Infrastructure as Code templates

4. **Cost Estimation**
   - First year infrastructure costs
   - Scaling cost projections
"/>
```

**Output Files Generated:**
- `tech-stack-recommendation.md`
- `architecture-overview.md`
- `deployment-guide.md`
- `adr/` (Architecture Decision Records)

### Step 2.1: Epic Decomposition

Break the product into high-level epics (major feature areas):

```markdown
## Epic Structure

| Epic | Description | Priority | Dependencies |
|------|-------------|----------|--------------|
| E1: Foundation | Project setup, auth, database | P0 | None |
| E2: Core Features | [Main functionality] | P0 | E1 |
| E3: User Experience | [UI/UX polish] | P1 | E2 |
| E4: Integration | [External services] | P1 | E2 |
| E5: Production | Testing, docs, deployment | P0 | E3, E4 |
```

### Step 2.2: Stage Definition

Each epic breaks into implementable stages:

**Stage Sizing Rules:**
| Right-sized Stage | Too Big (Split) |
|-------------------|-----------------|
| 3-7 user stories | More than 10 stories |
| 1-3 hours work | Full day or more |
| Single feature area | Multiple unrelated features |
| Clear completion criteria | Vague "make it work" |

### Step 2.3: Story Breakdown

For each stage, define user stories following autonomous-dev format:

```json
{
  "id": "S1-US-001",
  "title": "Story title",
  "description": "As a [user], I want [capability] so that [benefit]",
  "acceptanceCriteria": [
    "Specific criterion 1",
    "Typecheck passes",
    "Tests pass"
  ],
  "priority": 1,
  "dependsOn": []
}
```

### Step 2.4: Generate Master Project File

Create complete `master-project.json` (see templates.md for full structure).

### Step 2.5: Initialize Progress Tracking

Create `cpo-progress.md` (see templates.md for structure).

### Step 2.6: Generate Cost Estimate

Before presenting the plan, calculate and display infrastructure costs:

```markdown
## Resource & Cost Estimate

### Development Scope
| Metric | Value |
|--------|-------|
| Epics | [N] |
| Stages | [M] |
| User Stories | [X] |
| Complexity | [Low/Medium/High] |

### Infrastructure Costs (Monthly)
| Service | Tier | Cost |
|---------|------|------|
| [Hosting] | [Tier] | $[X] |
| [Database] | [Tier] | $[X] |
| [Auth] | [Tier] | $[X] |
| **Total** | | **$[X]/month** |

### At Scale (10K users)
| Service | Tier | Cost |
|---------|------|------|
| [Hosting] | [Pro] | $[X] |
| [Database] | [Pro] | $[X] |
| **Total** | | **$[X]/month** |

*Estimates based on typical usage. See [cost-estimation.md](cost-estimation.md) for details.*
```

### Step 2.7: Present Plan for Approval

```markdown
## Strategic Plan Summary

**Product:** [Name]
**Epics:** [N] major feature areas
**Stages:** [M] implementation stages
**Stories:** [X] total user stories
**Estimated Complexity:** [Low/Medium/High]
**Estimated Cost:** ~$[X]/month (MVP) → ~$[Y]/month (at scale)

### Execution Order

1. **Stage 1: [Name]** ([N] stories)
   - [Story 1]
   - [Story 2]

2. **Stage 2: [Name]** ([N] stories)
   ...

### Quality Gates

Each stage will be:
1. Implemented via autonomous-dev (with backend-api-agent/frontend-design-agent delegation)
2. Tested via fulltest-skill
3. Committed only when tests pass
4. Pushed to repository

Ready to begin implementation?

Reply with:
- "start" - Begin Stage 1
- "adjust [stage]" - Modify stage plan
- "reorder [stages]" - Change execution order
- "costs" - Show detailed cost breakdown
- "questions" - Discuss the approach
```

---

## Phase 3: Stage-by-Stage Implementation

**Goal:** Implement each stage sequentially with quality gates.

### Step 3.0: Load Project State

At the start of EVERY stage:

```bash
cat master-project.json
cat cpo-progress.md
```

Find the next stage: first with `status: "pending"` ordered by dependencies.

### Step 3.1: Initialize Stage

```markdown
## Starting Stage [N]: [Name]

**Epic:** [Parent Epic]
**Dependencies:** [Completed stages this depends on]
**Stories:** [N] user stories

**Objectives:**
- [Objective 1]
- [Objective 2]

Delegating to specialized agents for implementation...
```

### Step 3.2: Delegate to Specialized Agents

**Stage Type Detection → Agent Selection:**

| Stage Type | Primary Agent | Secondary |
|------------|---------------|-----------|
| Foundation (Stage 1) | database-setup-agent | autonomous-dev |
| UI/Frontend | frontend-design-agent | autonomous-dev |
| API/Backend | backend-api-agent | autonomous-dev |
| Full-Stack | frontend + backend agents | autonomous-dev |
| Testing/Validation | fulltest-skill | - |
| Deployment | deployment-agent | - |

---

#### For Foundation Stage (Stage 1) - Database + Environment Setup

```xml
<Task subagent_type="database-setup-agent" prompt="
## Database Setup: [Product Name]

**Provider:** [Supabase/Neon/PostgreSQL from CTO recommendation]
**ORM:** [Prisma/Drizzle]

### Schema Requirements (from Product Definition)
- Users with authentication
- [Core entities from product definition]
- [Relationships]

### Deliverables
1. Database provisioning (if Supabase/Neon)
2. Schema file (Prisma or Drizzle)
3. Initial migration
4. Seed data for development
5. RLS policies (if Supabase)

See: subagents/database-setup-agent.md
"/>
```

**Then generate environment configuration:**

```bash
# Generate .env.example based on stack
cat > .env.example << 'EOF'
# Application
NODE_ENV=development
APP_URL=http://localhost:3000

# Database (from CTO recommendation)
DATABASE_URL=

# Authentication
NEXTAUTH_SECRET=
NEXTAUTH_URL=http://localhost:3000

# Add stack-specific variables...
EOF
```

---

#### For UI/Frontend Stages - Use Frontend Design Agent

**CRITICAL:** Always pass research findings to the frontend agent. Read research files first:

```bash
# Load research from Phase 1
cat design-references.md
cat competitor-analysis.md
cat market-insights.md
```

Then invoke with research context:

```xml
<Task subagent_type="frontend-design-agent" prompt="
## Frontend Design: Stage [N] - [Name]

**Product:** [Product name]
**Stage Objective:** [What this stage delivers]

### Research Input (from Product Research Agent)
[Paste key findings from competitor-analysis.md, design-references.md, market-insights.md]

### Design Direction (derived from research)
- **Aesthetic:** [Direction based on references]
- **Differentiator:** [What makes us unique vs competitors]

### Tech Stack
[Frontend framework, styling approach from CTO agent]

### Components/Pages to Build
1. [Component/Page 1] - [Purpose]
2. [Component/Page 2] - [Purpose]

Create production-ready code. Use research for inspiration but make it distinctive.
See: subagents/frontend-design-agent.md
"/>
```

---

#### For API/Backend Stages - Use Backend API Agent

```xml
<Task subagent_type="backend-api-agent" prompt="
## API Implementation: Stage [N] - [Name]

**Product:** [Product name]
**Stage Objective:** [What this stage delivers]

### Endpoints to Implement
- [METHOD] /api/[path] - [Purpose]
- [METHOD] /api/[path] - [Purpose]

### Authentication
[JWT/Session/API Key from CTO recommendation]

### Tech Stack
[Framework from CTO agent - Next.js API Routes, Express, tRPC]

### Database
[ORM and schema from database-setup-agent]

### Requirements
- Error handling following API conventions
- Input validation with Zod
- Proper HTTP status codes

See: subagents/backend-api-agent.md
"/>
```

---

#### For Full-Stack Stages

Run both frontend and backend agents, then autonomous-dev for integration.

### Step 3.3: Delegate to Autonomous Dev

Create stage-specific `prd.json` and invoke autonomous-dev:

```javascript
// Generate prd.json for this stage
const stagePrd = {
  project: masterProject.project.name,
  branchName: `feature/stage-${stage.id}`,
  description: stage.description,
  createdAt: new Date().toISOString(),
  verification: masterProject.verification,
  userStories: stage.stories.map(story => ({
    ...story,
    passes: false,
    attempts: 0,
    notes: ""
  }))
};
```

Launch autonomous-dev:

```xml
<Task subagent_type="general-purpose" prompt="
## Autonomous Development: Stage [N] - [Name]

You are implementing Stage [N] of the [Product Name] project.

### Context
[Include relevant context from master-project.json]

### Stage Objectives
[Stage description and goals]

### User Stories to Implement

[Paste stage.stories as formatted list]

### Existing Codebase Patterns
[Include patterns from AGENTS.md if exists]

### Implementation Instructions

1. Create feature branch: `feature/stage-[N]-[name]`
2. Implement each story following the prd.json format
3. Run verification after each story
4. Commit passing stories immediately
5. Report completion with summary

### Verification Commands
- Typecheck: [command]
- Test: [command]
- Lint: [command]

Begin implementation. Report progress and any blockers.
"/>
```

### Step 3.4: Monitor Stage Progress

Track autonomous-dev progress:
- Stories completed
- Issues encountered
- Learnings captured

Update `master-project.json`:
```json
{
  "stages": [{
    "status": "in_progress",
    "startedAt": "[timestamp]"
  }]
}
```

### Step 3.5: Stage Completion

When autonomous-dev completes the stage:

1. **Verify all stories pass:**
   ```bash
   cat prd.json | jq '.userStories | map(select(.passes == true)) | length'
   ```

2. **Update master project:**
   ```json
   {
     "stages": [{
       "status": "implemented",
       "completedAt": "[timestamp]"
     }]
   }
   ```

3. **Run stage testing:**

### Step 3.6: Stage Testing

Invoke fulltest-skill for the stage:

```xml
<Task subagent_type="general-purpose" prompt="
## Stage Testing: Stage [N] - [Name]

Test all functionality implemented in this stage.

### What Was Built
[Summary from autonomous-dev output]

### Test Scope
- New endpoints: [list]
- New UI components: [list]
- New database operations: [list]

### Test Commands
[Include verification commands]

### Test Scenarios
[Generate test scenarios based on user stories]

Run comprehensive tests and report:
1. What passed
2. What failed (with details)
3. Recommended fixes

If using fulltest-skill with a web UI, test at the configured URL.
"/>
```

### Step 3.7: Handle Test Results

#### If all tests pass:

1. Update master project:
   ```json
   {
     "stages": [{
       "status": "tested",
       "testedAt": "[timestamp]"
     }]
   }
   ```

2. Commit the stage:
   ```bash
   git add -A
   git commit -m "feat(stage-[N]): [Stage Name]

   Implemented:
   - [Story 1]
   - [Story 2]

   Tested: All stories pass"
   ```

3. Push to repository:
   ```bash
   git push origin feature/stage-[N]-[name]
   ```

4. Update progress log:
   ```markdown
   ## [Timestamp] - Stage [N]: [Name] COMPLETE

   **Stories Completed:** [N]
   **Tests Passed:** All
   **Commit:** [hash]

   **Key Implementations:**
   - [What was built]

   **Learnings:**
   - [Patterns discovered]
   ```

5. Enter User Feedback Loop (Step 3.7b)

#### Step 3.7b: User Feedback Loop

After committing the stage, enter the feedback loop to ensure user satisfaction:

**1. Run Full Testing**

Invoke fulltesting-agent to verify the complete app state:

```
Run /fulltesting-agent on the current application.
Focus on Stage [N] functionality but include regression tests for previous stages.
```

**2. Handle Test Results**

- If tests FAIL:
  - Analyze failures and determine fixes
  - Invoke autonomous-dev with fix requirements
  - Commit: `fix(stage-[N]): address test failures`
  - Loop back to step 1 (re-run fulltesting-agent)

- If tests PASS:
  - Continue to step 3

**3. Request User Review**

```markdown
## Stage [N]: [Name] - Ready for Review

The stage has been implemented and all tests pass.

**Please review the app:**
- [URL or local instructions to view the app]
- [Key features to test in this stage]

**Your feedback:**
- Reply "done" to approve and continue to the next stage
- Reply with feedback to request changes (I'll implement and re-test)
```

**4. Process User Response**

**If user says "done" (or equivalent: "approved", "looks good", "move on"):**

- Update master-project.json:
  ```json
  {
    "stages": [{
      "feedbackLoop": {
        "status": "user_approved",
        "approvedAt": "[timestamp]"
      }
    }]
  }
  ```
- Proceed to Step 3.8 (Stage Completion Check)

**If user provides feedback:**

- Record feedback in master-project.json:
  ```json
  {
    "stages": [{
      "feedbackLoop": {
        "iterations": [N+1],
        "history": [{
          "iteration": [N],
          "userFeedback": "[feedback text]",
          "timestamp": "[ISO timestamp]"
        }]
      }
    }]
  }
  ```
- Invoke autonomous-dev with user feedback:
  ```
  Implement the following user feedback for Stage [N]:

  [User's feedback]

  Make the requested changes and ensure existing tests still pass.
  ```
- Commit changes: `fix(stage-[N]): incorporate user feedback - [summary]`
- Loop back to step 1 (run fulltesting-agent again)

**This loop continues until the user approves the stage.**

#### If tests fail:

1. Analyze failures:
   ```markdown
   ### Test Failures for Stage [N]

   | Test | Error | Root Cause | Fix Required |
   |------|-------|------------|--------------|
   | [test] | [error] | [cause] | [fix] |
   ```

2. Re-invoke autonomous-dev with fixes:
   ```xml
   <Task subagent_type="general-purpose" prompt="
   ## Fix Stage [N] Test Failures

   The following tests failed:
   [Failure details]

   Root cause analysis:
   [Analysis]

   Required fixes:
   [List of fixes]

   Implement fixes and verify tests pass.
   "/>
   ```

3. Re-test (max 3 iterations)

4. If still failing after 3 iterations:
   ```markdown
   Stage [N] has persistent test failures.

   Options:
   1. Review failures manually
   2. Simplify stage scope
   3. Get user input on blockers
   4. Skip non-critical tests and continue

   What would you like to do?
   ```

### Step 3.8: Stage Completion Check

After each stage:

```javascript
const remainingStages = stages.filter(s => s.status !== 'tested');
if (remainingStages.length === 0) {
  // All stages complete - proceed to Phase 4
  output("ALL STAGES COMPLETE - Beginning full project validation");
} else {
  // Continue to next stage
  continueToNextStage();
}
```

---

## Phase 4: Full Project Validation

**Goal:** Comprehensive testing of the complete integrated product.

### Step 4.1: Merge All Stage Branches

```bash
# Ensure we're on main branch
git checkout main

# Merge each stage branch
for stage in S1 S2 S3...; do
  git merge --no-ff feature/stage-${stage}-[name] -m "merge: Stage ${stage}"
done
```

### Step 4.2: Full Integration Testing

```xml
<Task subagent_type="general-purpose" prompt="
## Full Project Validation: [Product Name]

All stages have been implemented. Run comprehensive integration testing.

### Project Summary
- Epics: [N]
- Stages: [M] (all implemented and individually tested)
- Features: [List key features]

### Full Test Suite

1. **Unit Tests**
   ```bash
   [test command]
   ```

2. **Integration Tests**
   ```bash
   [integration test command]
   ```

3. **E2E Tests** (if applicable)
   ```bash
   [e2e test command]
   ```

4. **Build Verification**
   ```bash
   [build command]
   ```

### Critical User Journeys to Verify

[List end-to-end user flows that must work]

1. [Journey 1: e.g., User registration to first action]
2. [Journey 2: e.g., Core workflow completion]
3. [Journey 3: e.g., Error handling scenarios]

Report comprehensive results including:
- Overall test pass rate
- Any failures with root causes
- Performance observations
- Security considerations
"/>
```

### Step 4.3: Fix Any Integration Issues

If integration issues found:

1. Categorize by severity:
   - **Critical**: Blocks core functionality
   - **High**: Significant impact on UX
   - **Medium**: Edge cases or minor issues
   - **Low**: Polish or optimization

2. Fix critical/high issues before proceeding

3. Log medium/low as known issues for future iteration

### Step 4.4: Quality Gate

Only proceed to Phase 5 when:
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Build completes successfully
- [ ] Critical user journeys work
- [ ] No critical or high severity bugs

---

## Phase 5: Documentation & Delivery

**Goal:** Create user documentation and prepare for production.

### Step 5.1: Generate User Guide

Create `docs/user-guide.md` (see templates.md for full structure).

### Step 5.2: Generate Technical Documentation

Create `docs/technical-docs.md` (see templates.md for structure).

### Step 5.3: Final Commit

```bash
# Add all documentation
git add docs/

# Final commit
git commit -m "docs: Add user guide and technical documentation

- User guide with getting started, features, troubleshooting
- Technical documentation with architecture, setup, deployment
- Project README updates"
```

### Step 5.4: Push to GitHub

```bash
# Push main branch with all merged stages
git push origin main

# Create release tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial production release

Features:
- [Feature 1]
- [Feature 2]
- [Feature 3]

Documented and tested."

git push origin v1.0.0
```

### Step 5.5: Deploy to Production

Use the Deployment Agent for actual deployment execution:

```xml
<Task subagent_type="deployment-agent" prompt="
## Production Deployment: [Product Name]

**Platform:** [Vercel/Railway/DigitalOcean from CTO recommendation]
**Repository:** [GitHub URL]
**Branch:** main

### Environment Variables
[List from .env.example - production values]

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Build succeeds locally
- [ ] Environment variables ready
- [ ] Database provisioned and migrated
- [ ] Domain configured (if applicable)

### Post-Deployment Verification
- [ ] Health endpoint responds
- [ ] Core user flows work
- [ ] No console errors
- [ ] SSL certificate valid

### Rollback Plan
[Platform-specific rollback command]

Execute deployment and report results.
"/>
```

**Deployment Output:**
```markdown
## Deployment Complete

**URL:** https://[product-name].vercel.app (or custom domain)
**Platform:** [Vercel/Railway/DigitalOcean]
**Deployed At:** [timestamp]

### Verification Results
- Health Check: ✓ 200 OK (145ms)
- Homepage Load: ✓ 200 OK (890ms)
- API Health: ✓ 200 OK (120ms)
- SSL Certificate: ✓ Valid

### Environment
- Node.js: 20.x
- Region: [auto-detected]
- Database: Connected
```

### Step 5.6: Go-Live Report

See templates.md for complete go-live report structure.
