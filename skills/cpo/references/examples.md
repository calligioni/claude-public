# CPO AI Skill Examples

This document provides comprehensive examples for using the CPO AI Skill effectively.

---

## Table of Contents

1. [Discovery Question Flows](#discovery-question-flows)
2. [Epic Decomposition Patterns](#epic-decomposition-patterns)
3. [Stage Breakdown Examples](#stage-breakdown-examples)
4. [Complete Master Project Examples](#complete-master-project-examples)
5. [Progress Log Examples](#progress-log-examples)
6. [Common Product Archetypes](#common-product-archetypes)

---

## Discovery Question Flows

### Example 1: SaaS Dashboard Application

**User Input:**
> "I want to build a dashboard for tracking team productivity metrics"

**CPO Discovery Response:**

```markdown
I'll help you build a team productivity dashboard. Let me ask a few strategic questions.

**1. Target Users & Market**
   A. Small teams (5-20 people)
   B. Medium companies (20-100 people)
   C. Enterprise (100+ people)
   D. Freelancers/individuals

**2. Core Problem**
   What's the #1 problem this solves?
   A. No visibility into team workload
   B. Difficulty measuring productivity
   C. Poor project time tracking
   D. Other: [describe]

**3. Scope**
   A. MVP - Basic metrics display
   B. Feature-complete - Metrics + insights + integrations
   C. Enterprise - All above + team management + SSO

**4. Data Sources**
   Where does productivity data come from?
   A. Manual time entries
   B. Integration with tools (Jira, GitHub, etc.)
   C. Automatic activity tracking
   D. Combination of above

**5. Key Metrics**
   What should we track? (select all)
   A. Hours worked
   B. Tasks completed
   C. Code commits/PRs
   D. Meeting time
   E. Other: [list]

**6. Authentication**
   A. Email/password only
   B. Google/Microsoft SSO
   C. Enterprise SSO (SAML)

**7. Deployment**
   A. Cloud (we host)
   B. Self-hosted option
   C. Both

Reply: "1B, 2A, 3B, 4D, 5: A,B,C,D, 6B, 7A"
```

---

### Example 2: E-commerce Marketplace

**User Input:**
> "Build a marketplace where artists can sell their digital art"

**CPO Discovery Response:**

```markdown
I'll help you build a digital art marketplace. A few strategic questions:

**1. Marketplace Model**
   A. Simple listings (like Etsy)
   B. Auction-based (like eBay)
   C. NFT/Blockchain integrated
   D. Hybrid approach

**2. Target Artists**
   A. Hobbyist artists
   B. Professional digital artists
   C. AI art creators
   D. All of the above

**3. Content Types**
   What can artists sell?
   A. Digital downloads only
   B. Print-on-demand products
   C. Commissions/custom work
   D. All above

**4. Revenue Model**
   A. Transaction fee (% per sale)
   B. Subscription for sellers
   C. Featured listings/ads
   D. Combination

**5. Payment Processing**
   A. Stripe only
   B. PayPal + Stripe
   C. Crypto payments included
   D. Custom (specify)

**6. Scope**
   A. MVP - List, buy, sell basics
   B. Full - Reviews, messaging, analytics
   C. Enterprise - API, white-label, multi-vendor

**7. Critical Feature**
   What's the ONE feature that must work perfectly?
   [Free text]

Reply with your answers.
```

---

## Epic Decomposition Patterns

### Pattern: Standard SaaS Application

| Epic | Description | Stages | Priority |
|------|-------------|--------|----------|
| E1: Foundation | Project setup, auth, database | 2-3 | P0 |
| E2: Core Domain | Main business logic | 3-5 | P0 |
| E3: User Interface | Frontend components | 2-4 | P1 |
| E4: Integrations | External services | 1-3 | P2 |
| E5: Admin & Analytics | Admin panel, reporting | 2-3 | P2 |
| E6: Production | Testing, docs, deploy | 2-3 | P0 |

### Pattern: Consumer Mobile-First App

| Epic | Description | Stages | Priority |
|------|-------------|--------|----------|
| E1: Foundation | API setup, auth, database | 2 | P0 |
| E2: User Onboarding | Registration, profile | 2 | P0 |
| E3: Core Experience | Main app functionality | 4-6 | P0 |
| E4: Social Features | Sharing, following, etc. | 2-3 | P1 |
| E5: Notifications | Push, email, in-app | 1-2 | P1 |
| E6: Monetization | Payments, subscriptions | 2 | P1 |
| E7: Production | Testing, docs, app store | 2 | P0 |

### Pattern: Internal Tool / Admin System

| Epic | Description | Stages | Priority |
|------|-------------|--------|----------|
| E1: Foundation | Setup, SSO integration | 1-2 | P0 |
| E2: Data Management | CRUD operations | 2-4 | P0 |
| E3: Workflows | Business processes | 2-3 | P0 |
| E4: Reporting | Dashboards, exports | 2 | P1 |
| E5: Audit & Security | Logging, permissions | 1-2 | P1 |
| E6: Production | Testing, deployment | 1-2 | P0 |

---

## Stage Breakdown Examples

### Example: User Authentication Epic

**Epic E1: Authentication & Authorization**

```json
{
  "stages": [
    {
      "id": "S1",
      "epicId": "E1",
      "name": "Basic Auth Setup",
      "description": "Email/password registration and login",
      "stories": [
        {
          "id": "S1-US-001",
          "title": "User registration with email",
          "description": "As a new user, I want to register with my email so I can access the application",
          "acceptanceCriteria": [
            "Registration form accepts email and password",
            "Password strength validation",
            "Duplicate email prevention",
            "Success redirects to dashboard",
            "Typecheck passes"
          ]
        },
        {
          "id": "S1-US-002",
          "title": "User login",
          "description": "As a registered user, I want to log in so I can access my account",
          "acceptanceCriteria": [
            "Login form accepts email and password",
            "Invalid credentials show error",
            "Successful login sets session/token",
            "Remember me option works",
            "Typecheck passes"
          ]
        },
        {
          "id": "S1-US-003",
          "title": "Password reset flow",
          "description": "As a user, I want to reset my password if I forget it",
          "acceptanceCriteria": [
            "Reset request sends email",
            "Reset link expires after 24 hours",
            "New password must meet strength requirements",
            "Success redirects to login",
            "Typecheck passes"
          ]
        }
      ]
    },
    {
      "id": "S2",
      "epicId": "E1",
      "name": "OAuth Integration",
      "description": "Social login with Google and GitHub",
      "dependsOn": ["S1"],
      "stories": [
        {
          "id": "S2-US-001",
          "title": "Google OAuth login",
          "description": "As a user, I want to sign in with Google for convenience",
          "acceptanceCriteria": [
            "Google sign-in button on login page",
            "OAuth flow completes successfully",
            "New users auto-registered",
            "Existing users linked to Google account",
            "Typecheck passes"
          ]
        },
        {
          "id": "S2-US-002",
          "title": "GitHub OAuth login",
          "description": "As a developer, I want to sign in with GitHub",
          "acceptanceCriteria": [
            "GitHub sign-in button on login page",
            "OAuth flow completes successfully",
            "Profile photo imported from GitHub",
            "Typecheck passes"
          ]
        }
      ]
    },
    {
      "id": "S3",
      "epicId": "E1",
      "name": "Session Management",
      "description": "Secure session handling and logout",
      "dependsOn": ["S1"],
      "stories": [
        {
          "id": "S3-US-001",
          "title": "Secure session handling",
          "description": "As a user, my session should be secure and persist appropriately",
          "acceptanceCriteria": [
            "Sessions expire after inactivity",
            "Session tokens are HTTP-only cookies",
            "CSRF protection enabled",
            "Typecheck passes"
          ]
        },
        {
          "id": "S3-US-002",
          "title": "Logout functionality",
          "description": "As a user, I want to log out securely",
          "acceptanceCriteria": [
            "Logout button in navigation",
            "Session destroyed on logout",
            "Redirects to login page",
            "All devices option available",
            "Typecheck passes"
          ]
        }
      ]
    }
  ]
}
```

---

## Complete Master Project Examples

### Example: Task Management App

```json
{
  "project": {
    "name": "TaskFlow",
    "description": "A modern task management application for teams",
    "version": "0.1.0",
    "createdAt": "2025-01-15T10:00:00Z",
    "status": "in_progress"
  },
  "productDefinition": {
    "vision": "Simple, fast task management that gets out of your way",
    "targetUser": "Small development teams (5-15 people)",
    "problemStatement": "Existing tools are too complex for simple task tracking",
    "scope": "MVP",
    "techStack": {
      "frontend": "Next.js 14",
      "backend": "Next.js API Routes",
      "database": "PostgreSQL with Prisma",
      "hosting": "Vercel"
    },
    "successMetrics": [
      "User can create task in < 3 seconds",
      "Page load < 1 second",
      "Zero critical bugs in launch"
    ]
  },
  "epics": [
    {
      "id": "E1",
      "name": "Foundation",
      "description": "Project setup and authentication",
      "priority": 0,
      "status": "completed",
      "dependsOn": [],
      "stages": ["S1", "S2"]
    },
    {
      "id": "E2",
      "name": "Task Management",
      "description": "Core task CRUD operations",
      "priority": 1,
      "status": "in_progress",
      "dependsOn": ["E1"],
      "stages": ["S3", "S4"]
    },
    {
      "id": "E3",
      "name": "Team Features",
      "description": "Collaboration and team functionality",
      "priority": 2,
      "status": "pending",
      "dependsOn": ["E2"],
      "stages": ["S5", "S6"]
    },
    {
      "id": "E4",
      "name": "Production",
      "description": "Testing, documentation, deployment",
      "priority": 3,
      "status": "pending",
      "dependsOn": ["E2", "E3"],
      "stages": ["S7", "S8"]
    }
  ],
  "stages": [
    {
      "id": "S1",
      "epicId": "E1",
      "name": "Project Setup",
      "status": "tested",
      "completedAt": "2025-01-15T12:00:00Z",
      "testedAt": "2025-01-15T12:30:00Z",
      "stories": [
        {
          "id": "S1-US-001",
          "title": "Initialize Next.js project",
          "passes": true,
          "completedAt": "2025-01-15T11:00:00Z"
        },
        {
          "id": "S1-US-002",
          "title": "Configure Prisma with PostgreSQL",
          "passes": true,
          "completedAt": "2025-01-15T11:30:00Z"
        },
        {
          "id": "S1-US-003",
          "title": "Setup TailwindCSS",
          "passes": true,
          "completedAt": "2025-01-15T12:00:00Z"
        }
      ]
    },
    {
      "id": "S2",
      "epicId": "E1",
      "name": "Authentication",
      "status": "tested",
      "completedAt": "2025-01-15T15:00:00Z",
      "testedAt": "2025-01-15T15:30:00Z",
      "stories": [
        {
          "id": "S2-US-001",
          "title": "User registration",
          "passes": true
        },
        {
          "id": "S2-US-002",
          "title": "User login/logout",
          "passes": true
        },
        {
          "id": "S2-US-003",
          "title": "Protected routes",
          "passes": true
        }
      ]
    },
    {
      "id": "S3",
      "epicId": "E2",
      "name": "Basic Task CRUD",
      "status": "in_progress",
      "startedAt": "2025-01-15T16:00:00Z",
      "stories": [
        {
          "id": "S3-US-001",
          "title": "Create task",
          "passes": true
        },
        {
          "id": "S3-US-002",
          "title": "List tasks",
          "passes": true
        },
        {
          "id": "S3-US-003",
          "title": "Update task",
          "passes": false,
          "attempts": 1
        },
        {
          "id": "S3-US-004",
          "title": "Delete task",
          "passes": false,
          "attempts": 0
        }
      ]
    }
  ],
  "currentStage": "S3",
  "verification": {
    "typecheck": "npm run typecheck",
    "test": "npm run test",
    "lint": "npm run lint",
    "build": "npm run build"
  },
  "progress": {
    "phase": "execution",
    "completedEpics": 1,
    "completedStages": 2,
    "completedStories": 8,
    "totalEpics": 4,
    "totalStages": 8,
    "totalStories": 24
  }
}
```

---

## Progress Log Examples

### Example: cpo-progress.md

```markdown
# CPO Progress Log: TaskFlow

**Started:** 2025-01-15
**Status:** Executing Phase 3

---

## Phase History

### Phase 1: Discovery
- **Completed:** 2025-01-15 09:30
- **Key Decisions:**
  - Target: Small dev teams
  - Scope: MVP with potential for expansion
  - Stack: Next.js + PostgreSQL on Vercel

### Phase 2: Planning
- **Completed:** 2025-01-15 10:00
- **Epics Defined:** 4
- **Stages Defined:** 8
- **Total Stories:** 24

---

## Stage Progress

| Stage | Status | Started | Completed | Tested |
|-------|--------|---------|-----------|--------|
| S1: Project Setup | Tested | 10:00 | 12:00 | 12:30 |
| S2: Authentication | Tested | 13:00 | 15:00 | 15:30 |
| S3: Basic Task CRUD | In Progress | 16:00 | - | - |
| S4: Task Organization | Pending | - | - | - |
| S5: Team Workspaces | Pending | - | - | - |
| S6: Collaboration | Pending | - | - | - |
| S7: Testing Suite | Pending | - | - | - |
| S8: Documentation | Pending | - | - | - |

---

## Implementation Log

### 2025-01-15 12:00 - Stage S1: Project Setup COMPLETE

**Stories Completed:** 3/3
**Tests Passed:** All
**Commit:** abc1234

**Key Implementations:**
- Next.js 14 app router configured
- Prisma schema with User model
- TailwindCSS with custom theme

**Learnings:**
- Use `@` path alias for cleaner imports
- Prisma generate needed in postinstall

---

### 2025-01-15 15:30 - Stage S2: Authentication COMPLETE

**Stories Completed:** 3/3
**Tests Passed:** All
**Commit:** def5678

**Key Implementations:**
- NextAuth.js with credentials provider
- Session handling with JWT
- Protected API routes middleware

**Learnings:**
- NextAuth v5 has breaking changes - use v4 for stability
- Middleware runs on edge - can't use Prisma directly

---

### 2025-01-15 17:00 - Stage S3: Basic Task CRUD IN PROGRESS

**Stories Completed:** 2/4
**Current Story:** S3-US-003 (Update task)
**Blocker:** Optimistic update causing race condition

**Notes:**
- Create and List working perfectly
- Need to implement proper optimistic updates with rollback

---
```

---

## Common Product Archetypes

### 1. SaaS Dashboard

**Typical Epics:**
1. Foundation (auth, database, billing)
2. Dashboard Core (metrics, charts, widgets)
3. Data Connections (integrations, imports)
4. User Management (teams, permissions)
5. Production (testing, docs, deploy)

**Key Considerations:**
- Data visualization library (Chart.js, Recharts)
- Real-time updates (WebSockets, polling)
- Multi-tenancy architecture

---

### 2. E-commerce Platform

**Typical Epics:**
1. Foundation (auth, database)
2. Catalog (products, categories, search)
3. Shopping (cart, checkout, payments)
4. Order Management (orders, fulfillment)
5. User Experience (reviews, wishlist)
6. Admin (dashboard, inventory)
7. Production

**Key Considerations:**
- Payment integration (Stripe, PayPal)
- Inventory management
- Tax calculation
- Shipping integration

---

### 3. Social/Community Platform

**Typical Epics:**
1. Foundation (auth, profiles)
2. Content (posts, media, feeds)
3. Social Graph (following, connections)
4. Engagement (likes, comments, shares)
5. Notifications (push, email, in-app)
6. Moderation (reporting, admin tools)
7. Production

**Key Considerations:**
- Content delivery (CDN for media)
- Feed algorithms
- Real-time notifications
- Content moderation

---

### 4. API/Developer Platform

**Typical Epics:**
1. Foundation (auth, rate limiting)
2. Core API (endpoints, documentation)
3. Developer Portal (docs, playground)
4. Management (API keys, usage tracking)
5. Billing (usage-based pricing)
6. Production

**Key Considerations:**
- API versioning strategy
- Rate limiting and quotas
- OpenAPI/Swagger documentation
- SDKs for popular languages

---

### 5. Internal Tool / Admin System

**Typical Epics:**
1. Foundation (SSO, permissions)
2. Data Views (tables, filters, exports)
3. Workflows (forms, approvals)
4. Reporting (dashboards, scheduled reports)
5. Audit (logging, compliance)
6. Production

**Key Considerations:**
- Role-based access control
- Audit logging requirements
- Data export formats (CSV, Excel)
- Integration with existing systems

---

## Story Sizing Guidelines

### Right-Sized Stories (1 Stage Iteration)

| Good | Why It's Good |
|------|---------------|
| "Add email field to user profile" | Single field, clear scope |
| "Create product listing page" | One page, defined layout |
| "Implement password reset email" | Single flow, clear end state |
| "Add filter dropdown to dashboard" | UI component, bounded scope |

### Stories That Need Splitting

| Too Big | Split Into |
|---------|------------|
| "Build user authentication" | Registration, Login, Password reset, OAuth |
| "Create admin dashboard" | Layout, User table, Metrics widgets, Filters |
| "Implement checkout flow" | Cart summary, Shipping form, Payment, Confirmation |
| "Add search functionality" | Basic search, Filters, Sort, Pagination |

### Splitting Heuristics

1. **Multiple UI pages** → One story per page
2. **Multiple API endpoints** → One story per endpoint
3. **Multiple user roles** → One story per role's experience
4. **Multiple integrations** → One story per integration
5. **"And" in title** → Probably two stories

---

## Testing Stage Examples

### Stage Test Plan Template

```markdown
## Test Plan: Stage [N] - [Name]

### Unit Tests
- [ ] [Component/Function 1]
- [ ] [Component/Function 2]

### Integration Tests
- [ ] [API Endpoint 1]
- [ ] [API Endpoint 2]

### E2E Scenarios
1. **[User Flow 1]**
   - Navigate to [page]
   - Perform [action]
   - Verify [outcome]

2. **[User Flow 2]**
   - ...

### Edge Cases
- [ ] Empty state handling
- [ ] Error state handling
- [ ] Loading state handling
- [ ] Permission denied handling

### Performance Checks
- [ ] Page load < [X]ms
- [ ] API response < [Y]ms
```

---

*These examples serve as references for the CPO AI Skill workflow. Adapt them to your specific product requirements.*
