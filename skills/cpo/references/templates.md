# CPO AI Skill - Templates

All JSON and Markdown templates used throughout the CPO AI workflow.

---

## master-project.json Template

Complete structure for the master project file:

```json
{
  "project": {
    "name": "[Product Name]",
    "description": "[Product description]",
    "version": "0.1.0",
    "createdAt": "[ISO timestamp]",
    "status": "planning"
  },
  "productDefinition": {
    "vision": "[Vision statement]",
    "targetUser": "[User persona]",
    "problemStatement": "[Core problem]",
    "scope": "[MVP|Feature-complete|Enterprise]",
    "techStack": {
      "frontend": "[framework]",
      "backend": "[framework]",
      "database": "[database]",
      "hosting": "[platform]",
      "authentication": "[auth solution]",
      "orm": "[Prisma|Drizzle|etc]"
    },
    "successMetrics": ["[metric 1]", "[metric 2]"],
    "nonGoals": ["[explicitly out of scope]"]
  },
  "epics": [
    {
      "id": "E1",
      "name": "Foundation",
      "description": "Project setup, authentication, database",
      "priority": 0,
      "status": "pending",
      "dependsOn": []
    },
    {
      "id": "E2",
      "name": "Core Features",
      "description": "Primary product functionality",
      "priority": 0,
      "status": "pending",
      "dependsOn": ["E1"]
    },
    {
      "id": "E3",
      "name": "User Experience",
      "description": "UI polish and UX refinements",
      "priority": 1,
      "status": "pending",
      "dependsOn": ["E2"]
    },
    {
      "id": "E4",
      "name": "Integration",
      "description": "External service integrations",
      "priority": 1,
      "status": "pending",
      "dependsOn": ["E2"]
    },
    {
      "id": "E5",
      "name": "Production",
      "description": "Testing, documentation, deployment",
      "priority": 0,
      "status": "pending",
      "dependsOn": ["E3", "E4"]
    }
  ],
  "stages": [
    {
      "id": "S1",
      "epicId": "E1",
      "name": "Project Initialization",
      "description": "Set up project structure, tooling, and foundation",
      "status": "pending",
      "dependsOn": [],
      "stories": [
        {
          "id": "S1-US-001",
          "title": "Initialize Next.js project with TypeScript",
          "description": "As a developer, I want a properly configured Next.js project so that we have a solid foundation",
          "acceptanceCriteria": [
            "Next.js 14+ with App Router initialized",
            "TypeScript configured with strict mode",
            "ESLint and Prettier configured",
            "Project builds without errors",
            "Typecheck passes"
          ],
          "priority": 1,
          "dependsOn": []
        },
        {
          "id": "S1-US-002",
          "title": "Set up database connection",
          "description": "As a developer, I want database connectivity configured so that the app can persist data",
          "acceptanceCriteria": [
            "Database provider configured (Supabase/Neon)",
            "ORM schema file created",
            "Connection string in .env.example",
            "Migration runs successfully",
            "Test query succeeds"
          ],
          "priority": 1,
          "dependsOn": ["S1-US-001"]
        }
      ],
      "startedAt": null,
      "completedAt": null,
      "testedAt": null,
      "feedbackLoop": {
        "iterations": 0,
        "status": "pending",
        "history": [],
        "approvedAt": null
      }
    },
    {
      "id": "S2",
      "epicId": "E2",
      "name": "User Authentication",
      "description": "Implement user registration and login",
      "status": "pending",
      "dependsOn": ["S1"],
      "stories": [],
      "startedAt": null,
      "completedAt": null,
      "testedAt": null,
      "feedbackLoop": {
        "iterations": 0,
        "status": "pending",
        "history": [],
        "approvedAt": null
      }
    }
  ],
  "currentStage": null,
  "verification": {
    "typecheck": "npm run typecheck",
    "test": "npm run test",
    "lint": "npm run lint",
    "build": "npm run build",
    "e2e": "npm run test:e2e"
  },
  "repository": {
    "url": null,
    "branch": "main",
    "lastCommit": null
  },
  "costs": {
    "mvp": {
      "hosting": { "service": "Vercel", "tier": "Hobby", "monthly": 0 },
      "database": { "service": "Supabase", "tier": "Free", "monthly": 0 },
      "auth": { "service": "NextAuth", "tier": "Self-hosted", "monthly": 0 },
      "total": 0
    },
    "scale": {
      "hosting": { "service": "Vercel", "tier": "Pro", "monthly": 20 },
      "database": { "service": "Supabase", "tier": "Pro", "monthly": 25 },
      "auth": { "service": "NextAuth", "tier": "Self-hosted", "monthly": 0 },
      "total": 45
    }
  }
}
```

---

## cpo-progress.md Template

```markdown
# CPO Progress Log: [Product Name]

**Started:** [Date]
**Status:** [Current Phase]
**Last Updated:** [Timestamp]

---

## Phase History

### Phase 1: Discovery
- **Started:** [Date]
- **Completed:** [Date]
- **Key Decisions:**
  - Target User: [User persona]
  - Scope: [MVP/Feature-complete/Enterprise]
  - Tech Stack: [Framework choices]
  - Success Metric: [Primary metric]

### Phase 2: Planning
- **Started:** [Date]
- **Completed:** [Date]
- **Epics Defined:** [N]
- **Stages Defined:** [M]
- **Total Stories:** [X]
- **Tech Recommendations:**
  - Frontend: [Framework + rationale]
  - Backend: [Approach + rationale]
  - Database: [Choice + rationale]
  - Hosting: [Platform + rationale]

### Phase 3: Implementation
- **Started:** [Date]
- **Status:** [Stage N of M]
- **Stages Completed:** [X/M]

### Phase 4: Validation
- **Status:** [Not started | In progress | Complete]

### Phase 5: Delivery
- **Status:** [Not started | In progress | Complete]
- **Production URL:** [If deployed]

---

## Stage Progress

| Stage | Epic | Status | Started | Completed | Tested | Stories |
|-------|------|--------|---------|-----------|--------|---------|
| S1: Project Init | E1 | Tested | 2024-01-15 | 2024-01-15 | 2024-01-15 | 5/5 |
| S2: Authentication | E2 | In Progress | 2024-01-16 | - | - | 2/4 |
| S3: Core Features | E2 | Pending | - | - | - | 0/7 |
| S4: UI Polish | E3 | Pending | - | - | - | 0/6 |

---

## Implementation Log

### 2024-01-15 14:30 - Stage S1: Project Initialization COMPLETE

**Stories Completed:** 5
**Tests Passed:** All
**Commit:** a3f2d9c

**Key Implementations:**
- Next.js 14 with App Router and TypeScript
- Supabase PostgreSQL database connected
- Prisma ORM with initial schema
- Authentication scaffolding with NextAuth
- Environment configuration templates

**Learnings:**
- Using Supabase for rapid setup
- Prisma schema-first approach works well
- NextAuth v5 beta has cleaner API

**Issues Encountered:**
- None

---

### 2024-01-16 09:15 - Stage S2: User Authentication IN PROGRESS

**Stories Completed:** 2/4
**Current Story:** Registration flow with email verification

**Progress:**
- ✅ NextAuth configuration complete
- ✅ Login page UI implemented
- 🔄 Registration form in progress
- ⏳ Email verification pending

**Blockers:**
- None

---

## Metrics

| Metric | Value |
|--------|-------|
| Total Commits | 12 |
| Total Stories Completed | 7 |
| Test Pass Rate | 100% |
| Stages Completed | 1/8 |
| Overall Progress | 12.5% |

---

## Research Findings

### Competitor Analysis
- **Primary Competitors:** [List]
- **Key Differentiators:** [What makes us unique]
- **Design Inspiration:** [Reference products]

### Technical Decisions
- **CTO Recommendations:** [Link to tech-stack-recommendation.md]
- **Architecture:** [Link to architecture-overview.md]

---

## Notes & Observations

- [Freeform notes from the CPO process]
- [Architectural insights]
- [User feedback if any]
```

---

## User Guide Template

Complete structure for `docs/user-guide.md`:

```markdown
# [Product Name] User Guide

**Version:** 1.0.0
**Last Updated:** [Date]

---

## Overview

[Product description and value proposition - 2-3 sentences]

**Key Features:**
- [Feature 1]
- [Feature 2]
- [Feature 3]

---

## Getting Started

### Prerequisites

Before using [Product Name], ensure you have:
- [Requirement 1 - e.g., Modern web browser]
- [Requirement 2 - e.g., GitHub account (if required)]
- [Requirement 3 - e.g., API keys for integrations]

### Quick Start

Get up and running in 3 steps:

1. **[Step 1 Title]**
   ```bash
   [Command or action]
   ```
   [Brief explanation]

2. **[Step 2 Title]**
   [Instructions]

3. **[Step 3 Title]**
   [Instructions]

**Expected Result:** [What users should see after quick start]

---

## Installation

### Option 1: Hosted Version (Recommended)

Access the product at: **[Production URL]**

No installation required.

### Option 2: Local Development

For developers who want to run locally:

```bash
# Clone the repository
git clone [repo-url]
cd [project-name]

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your values

# Run database migrations
npm run db:migrate

# Start development server
npm run dev
```

Access at: `http://localhost:3000`

---

## Core Features

### Feature 1: [Feature Name]

[Description of what this feature does and why it's useful]

**How to use:**

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Example:**
```
[Example usage or screenshot description]
```

**Tips:**
- [Tip 1]
- [Tip 2]

---

### Feature 2: [Feature Name]

[Description]

**How to use:**

[Instructions]

---

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Yes | - |
| `NEXTAUTH_SECRET` | Authentication secret | Yes | - |
| `NEXTAUTH_URL` | Application URL | Yes | `http://localhost:3000` |
| `[CUSTOM_VAR]` | [Description] | No | `[default]` |

### Advanced Configuration

**[Config Topic]:**
```javascript
// Example configuration
```

---

## User Workflows

### Workflow 1: [Common Task]

Complete end-to-end guide for [task]:

1. **[Step 1 Title]**
   - [Action]
   - [Expected result]

2. **[Step 2 Title]**
   - [Action]
   - [Expected result]

3. **[Step 3 Title]**
   - [Action]
   - [Expected result]

**Success Indicator:** [How users know they succeeded]

---

## Troubleshooting

### Common Issues

#### Issue: [Problem Description]

**Symptoms:**
- [What users see]
- [Error message if applicable]

**Solution:**
```bash
[Fix command or instructions]
```

**Why this happens:** [Explanation]

---

#### Issue: [Another Problem]

**Quick Fix:**
1. [Step 1]
2. [Step 2]

---

### Getting Help

If you encounter issues not covered here:

1. **Check Status Page:** [Status URL if applicable]
2. **Search Issues:** [GitHub Issues URL]
3. **Ask Community:** [Discord/Forum URL if applicable]
4. **Contact Support:** [Email or contact method]

When reporting bugs, include:
- Steps to reproduce
- Expected vs actual behavior
- Browser/environment info
- Error messages or screenshots

---

## API Reference (if applicable)

### Authentication

All API requests require authentication via [method]:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://[api-url]/api/endpoint
```

### Endpoints

#### GET /api/[endpoint]

[Description]

**Request:**
```json
{
  "param1": "value1"
}
```

**Response:**
```json
{
  "data": [],
  "status": "success"
}
```

---

## Best Practices

### [Practice Category 1]

- **Do:** [Recommended approach]
- **Don't:** [Avoid this pattern]
- **Why:** [Explanation]

### [Practice Category 2]

[Guidance]

---

## FAQ

**Q: [Common question]**
A: [Answer]

**Q: [Another question]**
A: [Answer]

---

## Changelog

See [CHANGELOG.md](../CHANGELOG.md) for version history.

---

## Support & Feedback

- **Documentation:** [Link to docs]
- **GitHub:** [Repo URL]
- **Report Bug:** [Issues URL]
- **Request Feature:** [Issues URL]
- **Contact:** [Email or contact method]

---

**Built with [Tech Stack]** | **Version 1.0.0** | **Last Updated: [Date]**
```

---

## Technical Documentation Template

Structure for `docs/technical-docs.md`:

```markdown
# [Product Name] Technical Documentation

**For Developers**
**Version:** 1.0.0
**Last Updated:** [Date]

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Client Layer                      │
│  [Next.js App Router + React + Tailwind CSS]        │
└───────────────────┬─────────────────────────────────┘
                    │
                    │ HTTPS / API Routes
                    │
┌───────────────────▼─────────────────────────────────┐
│                 Application Layer                    │
│  [Next.js API Routes / Server Actions / tRPC]       │
└───────────────────┬─────────────────────────────────┘
                    │
                    │ ORM (Prisma)
                    │
┌───────────────────▼─────────────────────────────────┐
│                   Data Layer                         │
│  [Supabase PostgreSQL + RLS + Auth]                 │
└─────────────────────────────────────────────────────┘
```

**Key Components:**
- **Frontend:** [Framework + UI approach]
- **Backend:** [API approach]
- **Database:** [Database + ORM]
- **Authentication:** [Auth solution]
- **Hosting:** [Platform]

---

## Tech Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| Frontend | Next.js | 14.x | React framework with SSR/SSG |
| UI | Tailwind CSS | 3.x | Utility-first styling |
| Backend | Next.js API Routes | 14.x | Serverless API endpoints |
| Database | PostgreSQL | 15.x | Relational database |
| ORM | Prisma | 5.x | Type-safe database client |
| Auth | NextAuth.js | 5.x | Authentication framework |
| Deployment | Vercel | - | Hosting platform |
| CI/CD | GitHub Actions | - | Automated testing/deployment |

**Dependencies:**
- See `package.json` for complete list
- Key libraries: [List critical dependencies]

---

## Project Structure

```
[project-name]/
├── app/                    # Next.js App Router pages
│   ├── (auth)/            # Auth-protected routes
│   ├── api/               # API route handlers
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Homepage
├── components/            # React components
│   ├── ui/               # Reusable UI components
│   └── features/         # Feature-specific components
├── lib/                   # Utility functions and configs
│   ├── db.ts             # Database client
│   ├── auth.ts           # Auth configuration
│   └── utils.ts          # Helper functions
├── prisma/               # Database schema and migrations
│   ├── schema.prisma     # Prisma schema
│   └── migrations/       # Migration files
├── public/               # Static assets
├── tests/                # Test files
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docs/                 # Documentation
├── .env.example          # Environment template
├── package.json          # Dependencies
└── tsconfig.json         # TypeScript config
```

---

## Development Setup

### Prerequisites

- Node.js 20.x or later
- npm or pnpm
- PostgreSQL database (or Supabase account)
- Git

### Initial Setup

1. **Clone and Install:**
   ```bash
   git clone [repo-url]
   cd [project-name]
   npm install
   ```

2. **Environment Configuration:**
   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your values:
   ```env
   DATABASE_URL="postgresql://user:pass@host:5432/db"
   NEXTAUTH_SECRET="generate-with-openssl-rand-base64-32"
   NEXTAUTH_URL="http://localhost:3000"
   ```

3. **Database Setup:**
   ```bash
   # Run migrations
   npm run db:migrate

   # Seed development data (optional)
   npm run db:seed
   ```

4. **Start Development Server:**
   ```bash
   npm run dev
   ```

   Access at: `http://localhost:3000`

---

## Database Schema

### Tables

#### users
```prisma
model User {
  id            String    @id @default(cuid())
  email         String    @unique
  name          String?
  emailVerified DateTime?
  image         String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  accounts      Account[]
  sessions      Session[]
  // Add product-specific relations
}
```

#### [Other Tables]
[Document key tables and relationships]

### Migrations

Run migrations:
```bash
# Development
npm run db:migrate

# Production
npm run db:migrate:prod
```

Create new migration:
```bash
npm run db:migrate:create
```

---

## API Endpoints

### Authentication

#### POST /api/auth/signin
Sign in user

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": { "id": "...", "email": "..." },
  "token": "..."
}
```

---

### [Feature] Endpoints

#### GET /api/[resource]
[Description]

#### POST /api/[resource]
[Description]

---

## Testing

### Test Structure

```
tests/
├── unit/           # Unit tests for utilities and functions
├── integration/    # API and database integration tests
└── e2e/            # End-to-end user flow tests
```

### Running Tests

```bash
# All tests
npm test

# Unit tests only
npm run test:unit

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# Watch mode
npm run test:watch

# Coverage report
npm run test:coverage
```

### Writing Tests

**Unit Test Example:**
```typescript
import { describe, it, expect } from 'vitest';
import { myFunction } from '@/lib/utils';

describe('myFunction', () => {
  it('should do something', () => {
    const result = myFunction('input');
    expect(result).toBe('expected');
  });
});
```

---

## Deployment

### Environment Setup

**Required Environment Variables:**
- `DATABASE_URL` - Production database connection
- `NEXTAUTH_SECRET` - Strong random secret
- `NEXTAUTH_URL` - Production URL
- [Add product-specific variables]

### Vercel Deployment

1. **Connect Repository:**
   - Link GitHub repo in Vercel dashboard
   - Configure build settings (auto-detected)

2. **Set Environment Variables:**
   - Add production env vars in Vercel project settings

3. **Deploy:**
   ```bash
   # Via Git push
   git push origin main

   # Or via Vercel CLI
   vercel --prod
   ```

### Database Migrations

Run migrations on production:
```bash
# Using Prisma
npx prisma migrate deploy
```

### Health Checks

Verify deployment:
```bash
# Health endpoint
curl https://[your-domain]/api/health

# Expected response
{"status":"ok","timestamp":"..."}
```

---

## Architecture Decision Records

### ADR-001: [Decision Title]

**Date:** [Date]
**Status:** Accepted

**Context:**
[What circumstances led to this decision]

**Decision:**
[What we decided to do]

**Consequences:**
[Positive and negative outcomes of this decision]

---

## Code Style & Conventions

### TypeScript

- Use strict mode
- Prefer `const` over `let`
- Always define types for function parameters and return values
- Use meaningful variable names

### React

- Functional components only
- Use hooks for state management
- Extract reusable logic into custom hooks
- Keep components small and focused

### File Naming

- Components: PascalCase (`UserProfile.tsx`)
- Utilities: camelCase (`formatDate.ts`)
- API routes: kebab-case (`user-settings.ts`)

---

## CI/CD Pipeline

### GitHub Actions

**On Pull Request:**
1. Lint code
2. Run type checking
3. Run unit tests
4. Run integration tests

**On Merge to Main:**
1. All PR checks
2. Build project
3. Deploy to staging (if configured)

**On Release Tag:**
1. All checks
2. Build production bundle
3. Deploy to production
4. Create release notes

---

## Monitoring & Observability

### Recommended Tools

- **Error Tracking:** Sentry
- **Analytics:** PostHog or Mixpanel
- **Uptime:** BetterStack
- **Logs:** Vercel logs or Datadog

### Key Metrics to Track

- Page load times
- API response times
- Error rates
- User sign-ups
- [Product-specific metrics]

---

## Security Considerations

- All API routes require authentication (except public endpoints)
- Input validation using Zod schemas
- SQL injection prevention via Prisma parameterized queries
- XSS prevention via React's built-in escaping
- CSRF protection via NextAuth
- Rate limiting on sensitive endpoints
- Environment variables never committed to Git

---

## Performance Optimization

### Current Optimizations

- Static page generation where possible
- Image optimization via Next.js Image component
- Code splitting via dynamic imports
- Database query optimization with indexes
- CDN caching for static assets

### Future Considerations

- [List planned optimizations]

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for development workflow and PR guidelines.

---

## Troubleshooting

### Common Development Issues

**Issue: Database connection failed**
```bash
# Verify DATABASE_URL is correct
echo $DATABASE_URL

# Test connection
npm run db:test
```

**Issue: TypeScript errors after pulling**
```bash
# Regenerate Prisma client
npm run db:generate

# Clear TypeScript cache
rm -rf .next
npm run build
```

---

## References

- [Next.js Documentation](https://nextjs.org/docs)
- [Prisma Documentation](https://www.prisma.io/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Architecture Diagram](./architecture-diagram.png)

---

**Maintained by [Team/Individual]** | **Version 1.0.0** | **Last Updated: [Date]**
```

---

## Go-Live Report Template

```markdown
# Product Launch Report 🚀

## [Product Name] v1.0.0

**Launch Date:** [Date and Time]
**Status:** ✅ Live in Production

---

## Production Environment

| Service | Status | URL/Details |
|---------|--------|-------------|
| Application | ✅ Live | https://[your-domain] |
| Database | ✅ Connected | [Provider + Region] |
| Authentication | ✅ Configured | [Provider] |
| SSL Certificate | ✅ Valid | Expires: [Date] |

---

## Deployment Summary

### Metrics

| Metric | Value |
|--------|-------|
| **Epics Completed** | [N] |
| **Stages Implemented** | [M] |
| **User Stories Delivered** | [X] |
| **Total Commits** | [Y] |
| **Tests Passing** | [Z]/[Z] (100%) |
| **Test Coverage** | [XX]% |
| **Build Time** | [N] seconds |
| **Deployment Time** | [N] minutes |

### Development Timeline

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Discovery | [N] days | Product definition, research findings |
| Planning | [N] days | [M] stages, [X] stories, tech stack |
| Implementation | [N] days | All features built and tested |
| Validation | [N] days | Full integration testing |
| Delivery | [N] days | Documentation, deployment |
| **Total** | **[N] days** | Production-ready product |

---

## Features Delivered

### Core Features

1. **[Feature 1 Name]**
   - [Brief description]
   - User impact: [How it helps users]

2. **[Feature 2 Name]**
   - [Brief description]
   - User impact: [How it helps users]

3. **[Feature 3 Name]**
   - [Brief description]
   - User impact: [How it helps users]

### Technical Capabilities

- ✅ [Capability 1 - e.g., User authentication with email/password]
- ✅ [Capability 2 - e.g., Real-time data synchronization]
- ✅ [Capability 3 - e.g., Responsive mobile design]
- ✅ [Capability 4 - e.g., API rate limiting and security]

---

## Infrastructure

### Tech Stack

| Layer | Technology | Version | Notes |
|-------|------------|---------|-------|
| Frontend | [Framework] | [X.x] | [Why chosen] |
| Backend | [Framework] | [X.x] | [Why chosen] |
| Database | [Database] | [X.x] | [Why chosen] |
| ORM | [ORM] | [X.x] | Type-safe queries |
| Auth | [Auth solution] | [X.x] | [Why chosen] |
| Hosting | [Platform] | - | [Why chosen] |

### Cost Structure

**MVP (Current Scale):**
| Service | Tier | Monthly Cost |
|---------|------|--------------|
| [Hosting] | [Tier] | $[X] |
| [Database] | [Tier] | $[X] |
| [Auth] | [Tier] | $[X] |
| **Total** | | **$[X]/month** |

**At Scale (10K users):**
| Service | Tier | Projected Cost |
|---------|------|----------------|
| [Hosting] | [Pro] | $[X] |
| [Database] | [Pro] | $[X] |
| **Total** | | **$[X]/month** |

---

## Quality Assurance

### Test Results

| Test Type | Tests Run | Pass | Fail | Coverage |
|-----------|-----------|------|------|----------|
| Unit | [N] | [N] | 0 | [XX]% |
| Integration | [M] | [M] | 0 | [XX]% |
| E2E | [K] | [K] | 0 | [XX]% |

### Deployment Verification

**Post-Deployment Checks:**
- ✅ Health endpoint responding (HTTP 200)
- ✅ Homepage loads < 1s
- ✅ API endpoints functional
- ✅ Database connectivity verified
- ✅ Authentication flow working
- ✅ SSL certificate valid
- ✅ No console errors
- ✅ Mobile responsive verified

**Performance Metrics:**
- Page Load (First Load): [XXX]ms
- Time to Interactive: [XXX]ms
- API Response Time (avg): [XX]ms
- Lighthouse Score: [XX]/100

---

## Documentation

### Available Documentation

- **User Guide:** [Link to docs/user-guide.md]
  - Getting started guide
  - Feature documentation
  - Troubleshooting

- **Technical Documentation:** [Link to docs/technical-docs.md]
  - Architecture overview
  - Development setup
  - API reference
  - Deployment guide

- **Repository:** [GitHub URL]
  - README with quick start
  - CHANGELOG with version history
  - CONTRIBUTING guidelines

---

## Access & Links

### Production Access

- **Application URL:** https://[your-domain]
- **Admin Panel:** https://[your-domain]/admin (if applicable)
- **API Docs:** https://[your-domain]/api/docs (if applicable)

### Development Resources

- **GitHub Repository:** [URL]
- **Project Board:** [URL if applicable]
- **Deployment Dashboard:** [Vercel/Railway/DO URL]
- **Database Dashboard:** [Supabase/Neon URL]

### Credentials & Secrets

- Stored in: [Password manager/secrets vault]
- Access: [Who has access]

---

## Monitoring & Maintenance

### Recommended Setup (Next Steps)

**Immediate:**
- [ ] Set up error tracking (Sentry)
- [ ] Configure uptime monitoring (BetterStack)
- [ ] Enable basic analytics (PostHog)

**Within 1 Week:**
- [ ] Review initial error logs
- [ ] Monitor performance metrics
- [ ] Gather initial user feedback

**Within 1 Month:**
- [ ] Analyze usage patterns
- [ ] Identify optimization opportunities
- [ ] Plan first iteration of improvements

### Health Monitoring

- **Uptime Target:** 99.9%
- **Response Time Target:** < 500ms
- **Error Rate Target:** < 0.1%

---

## Known Issues & Limitations

### Current Limitations

1. **[Limitation 1]**
   - Impact: [Low/Medium/High]
   - Planned fix: [When/how]

2. **[Limitation 2]**
   - Impact: [Low/Medium/High]
   - Planned fix: [When/how]

### Future Enhancements (Backlog)

Priority features for next iteration:

- [ ] **[Feature Name]** - [Brief description]
- [ ] **[Feature Name]** - [Brief description]
- [ ] **[Feature Name]** - [Brief description]

See [GitHub Issues](link) for complete backlog.

---

## Success Metrics

### Initial Success Criteria

From product definition, we aim to measure:

1. **[Metric 1]:** [Target value]
   - How measured: [Method]
   - Review frequency: [Daily/Weekly]

2. **[Metric 2]:** [Target value]
   - How measured: [Method]
   - Review frequency: [Daily/Weekly]

3. **[Metric 3]:** [Target value]
   - How measured: [Method]
   - Review frequency: [Daily/Weekly]

---

## Team & Acknowledgments

**Built by:**
- CPO AI Skill (Product orchestration)
- Autonomous Dev Skill (Implementation)
- Fulltest Skill (Quality assurance)

**Specialized Agents:**
- Product Research Agent (Market analysis)
- CTO Advisor Agent (Technical architecture)
- Frontend Design Agent (UI implementation)
- Backend API Agent (API development)
- Database Setup Agent (Schema design)
- Deployment Agent (Production deployment)

---

## Next Steps

### For Users

1. Visit https://[your-domain]
2. Read the [User Guide](docs/user-guide.md)
3. Provide feedback via [method]

### For Developers

1. Review [Technical Documentation](docs/technical-docs.md)
2. Set up local development environment
3. Check [Issues](GitHub-issues-url) for contribution opportunities

### For Product Owner

1. Monitor initial usage and errors
2. Gather user feedback
3. Prioritize next iteration features
4. Schedule first retrospective

---

## Support

**For Issues:**
- GitHub Issues: [URL]
- Email: [support-email]
- Documentation: [docs-url]

**For Feature Requests:**
- GitHub Discussions: [URL]
- Email: [product-email]

---

## Conclusion

🎉 **Congratulations!** [Product Name] is now live in production.

**Summary:**
- ✅ All planned features delivered
- ✅ Comprehensive testing completed
- ✅ Documentation published
- ✅ Production deployment successful
- ✅ Monitoring ready to be configured

**What's next:**
Focus on user acquisition, gather feedback, and plan the next iteration based on real-world usage data.

---

**Report Generated:** [Timestamp]
**CPO AI Skill Version:** 2.0.0
**Deployment:** Production
**Status:** ✅ Complete
```

---

## Stage PRD Template (for autonomous-dev)

```json
{
  "project": "[Product Name]",
  "branchName": "feature/stage-[N]-[name]",
  "description": "[Stage description]",
  "createdAt": "[ISO timestamp]",
  "verification": {
    "typecheck": "npm run typecheck",
    "test": "npm run test",
    "lint": "npm run lint"
  },
  "userStories": [
    {
      "id": "S[N]-US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [capability] so that [benefit]",
      "acceptanceCriteria": [
        "[Criterion 1]",
        "[Criterion 2]",
        "Typecheck passes",
        "Tests pass"
      ],
      "priority": 1,
      "dependsOn": [],
      "passes": false,
      "attempts": 0,
      "notes": ""
    }
  ]
}
```

---

## Environment Configuration Template

Complete `.env.example` for different stacks:

### Next.js + Supabase

```env
# Application
NODE_ENV=development
APP_URL=http://localhost:3000
APP_NAME="[Product Name]"

# Database (Supabase)
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"
DIRECT_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# Supabase
NEXT_PUBLIC_SUPABASE_URL="https://[PROJECT-REF].supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="[ANON-KEY]"
SUPABASE_SERVICE_ROLE_KEY="[SERVICE-ROLE-KEY]"

# Authentication (NextAuth)
NEXTAUTH_SECRET="[generate-with: openssl rand -base64 32]"
NEXTAUTH_URL="http://localhost:3000"

# OAuth Providers (optional)
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""

GITHUB_CLIENT_ID=""
GITHUB_CLIENT_SECRET=""

# Email (if using email auth)
SMTP_HOST=""
SMTP_PORT=""
SMTP_USER=""
SMTP_PASSWORD=""
SMTP_FROM=""

# Feature Flags (optional)
NEXT_PUBLIC_ENABLE_ANALYTICS=false
NEXT_PUBLIC_ENABLE_SENTRY=false
```

### Next.js + Neon

```env
# Application
NODE_ENV=development
APP_URL=http://localhost:3000

# Database (Neon)
DATABASE_URL="postgresql://[user]:[password]@[endpoint].neon.tech/[database]?sslmode=require"

# Prisma
DATABASE_URL_UNPOOLED="postgresql://[user]:[password]@[endpoint].neon.tech/[database]?sslmode=require"
DATABASE_URL_POOLED="postgresql://[user]:[password]@[endpoint]-pooler.neon.tech/[database]?sslmode=require"

# Authentication
NEXTAUTH_SECRET=""
NEXTAUTH_URL="http://localhost:3000"

# Add other services as needed
```

---

This templates file provides all the structured templates needed throughout the CPO AI workflow.
