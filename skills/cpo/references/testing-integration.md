# Testing Integration Reference

Comprehensive guide for integrating testing into the CPO AI workflow at every stage.

## Testing Strategy Overview

The CPO AI implements a multi-layered testing approach that scales with product complexity:

### Testing Pyramid

```
        /\
       /E2E\          <- 10% - Critical user journeys
      /------\
     /Integration\    <- 30% - API endpoints, feature flows
    /------------\
   /  Unit Tests  \   <- 60% - Business logic, utilities
  /----------------\
```

### Coverage Targets

| Code Type | Target Coverage | Priority |
|-----------|----------------|----------|
| Business Logic | 90%+ | High |
| API Routes | 85%+ | High |
| UI Components | 75%+ | Medium |
| Utilities | 95%+ | High |
| Integration Code | 70%+ | Medium |

### Quality Gates

Each stage must pass these gates before proceeding:

- ✅ All tests pass
- ✅ Coverage targets met
- ✅ No critical bugs in E2E tests
- ✅ TypeScript compilation successful
- ✅ Linting passes

## Test Generation Per Stage

### Stage Type Testing Matrix

| Stage Type | Generated Tests | Tools | When to Run |
|------------|----------------|-------|-------------|
| Foundation | Setup validation, config tests | Vitest/Jest | After stage completion |
| Database | Schema tests, seed validation | Vitest + DB client | After migrations |
| API/Backend | Unit + Integration + API tests | Jest + Supertest | After each endpoint |
| Frontend | Component + visual tests | Vitest + Testing Library | After component impl |
| Full Integration | E2E user flows | Playwright/Cypress | End of phase |

### Foundation Stage Tests

```typescript
// tests/setup/foundation.test.ts
import { describe, it, expect } from 'vitest'
import { checkEnvVariables, validateDatabaseConnection } from '@/lib/setup'

describe('Foundation Setup', () => {
  it('should have all required environment variables', () => {
    const required = ['DATABASE_URL', 'NEXT_PUBLIC_API_URL']
    const missing = checkEnvVariables(required)
    expect(missing).toHaveLength(0)
  })

  it('should connect to database', async () => {
    const connected = await validateDatabaseConnection()
    expect(connected).toBe(true)
  })

  it('should have correct Next.js configuration', () => {
    const config = require('@/next.config')
    expect(config.reactStrictMode).toBe(true)
  })
})
```

### API/Backend Stage Tests

```typescript
// src/app/api/users/route.test.ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { NextRequest } from 'next/server'
import { GET, POST } from './route'
import { cleanupTestDb, seedTestDb } from '@/tests/helpers'

describe('GET /api/users', () => {
  beforeEach(async () => {
    await seedTestDb()
  })

  afterEach(async () => {
    await cleanupTestDb()
  })

  it('should return 200 with user list', async () => {
    const request = new NextRequest('http://localhost:3000/api/users')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.users).toBeDefined()
    expect(data.users.length).toBeGreaterThan(0)
  })

  it('should return 401 for unauthenticated request', async () => {
    const request = new NextRequest('http://localhost:3000/api/users')
    const response = await GET(request)

    expect(response.status).toBe(401)
  })

  it('should support pagination', async () => {
    const request = new NextRequest('http://localhost:3000/api/users?page=2&limit=10')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.pagination.currentPage).toBe(2)
    expect(data.users.length).toBeLessThanOrEqual(10)
  })
})

describe('POST /api/users', () => {
  it('should create user with valid data', async () => {
    const userData = {
      email: 'test@example.com',
      name: 'Test User'
    }

    const request = new NextRequest('http://localhost:3000/api/users', {
      method: 'POST',
      body: JSON.stringify(userData)
    })

    const response = await POST(request)
    const data = await response.json()

    expect(response.status).toBe(201)
    expect(data.user.email).toBe(userData.email)
  })

  it('should return 400 for invalid email', async () => {
    const userData = { email: 'invalid-email', name: 'Test' }
    const request = new NextRequest('http://localhost:3000/api/users', {
      method: 'POST',
      body: JSON.stringify(userData)
    })

    const response = await POST(request)
    expect(response.status).toBe(400)
  })
})
```

### Frontend Stage Tests

```typescript
// src/components/UserList.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { UserList } from './UserList'

describe('UserList Component', () => {
  it('should render loading state initially', () => {
    render(<UserList />)
    expect(screen.getByText(/loading/i)).toBeInTheDocument()
  })

  it('should display users after fetch', async () => {
    const mockUsers = [
      { id: 1, name: 'Alice', email: 'alice@example.com' },
      { id: 2, name: 'Bob', email: 'bob@example.com' }
    ]

    global.fetch = vi.fn(() =>
      Promise.resolve({
        ok: true,
        json: async () => ({ users: mockUsers })
      })
    )

    render(<UserList />)

    await waitFor(() => {
      expect(screen.getByText('Alice')).toBeInTheDocument()
      expect(screen.getByText('Bob')).toBeInTheDocument()
    })
  })

  it('should handle pagination clicks', async () => {
    render(<UserList />)
    const user = userEvent.setup()

    await waitFor(() => screen.getByText('Next'))
    await user.click(screen.getByText('Next'))

    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('page=2')
    )
  })
})
```

### E2E Integration Tests

```typescript
// tests/e2e/user-management.spec.ts
import { test, expect } from '@playwright/test'

test.describe('User Management Flow', () => {
  test('should complete full user CRUD cycle', async ({ page }) => {
    // Navigate to users page
    await page.goto('http://localhost:3000/users')

    // Create new user
    await page.click('button:has-text("Add User")')
    await page.fill('input[name="email"]', 'newuser@example.com')
    await page.fill('input[name="name"]', 'New User')
    await page.click('button:has-text("Save")')

    // Verify user appears in list
    await expect(page.locator('text=New User')).toBeVisible()

    // Edit user
    await page.click('button[aria-label="Edit New User"]')
    await page.fill('input[name="name"]', 'Updated User')
    await page.click('button:has-text("Save")')

    await expect(page.locator('text=Updated User')).toBeVisible()

    // Delete user
    await page.click('button[aria-label="Delete Updated User"]')
    await page.click('button:has-text("Confirm")')

    await expect(page.locator('text=Updated User')).not.toBeVisible()
  })

  test('should show validation errors', async ({ page }) => {
    await page.goto('http://localhost:3000/users')
    await page.click('button:has-text("Add User")')
    await page.click('button:has-text("Save")')

    await expect(page.locator('text=Email is required')).toBeVisible()
  })
})
```

## Acceptance Criteria Templates with Tests

### Story Acceptance Criteria Example

```json
{
  "story": "User Registration",
  "acceptanceCriteria": [
    {
      "criterion": "User can register with email and password",
      "testType": "E2E",
      "testFile": "tests/e2e/auth.spec.ts",
      "testName": "should register new user successfully"
    },
    {
      "criterion": "API returns 201 on successful registration",
      "testType": "Integration",
      "testFile": "src/app/api/auth/register/route.test.ts",
      "testName": "should return 201 with user data"
    },
    {
      "criterion": "Password is hashed before storing",
      "testType": "Unit",
      "testFile": "src/lib/auth.test.ts",
      "testName": "should hash password with bcrypt"
    },
    {
      "criterion": "Duplicate email returns 409 error",
      "testType": "Integration",
      "testFile": "src/app/api/auth/register/route.test.ts",
      "testName": "should return 409 for duplicate email"
    }
  ],
  "coverageRequirement": {
    "overall": 85,
    "newCode": 90
  }
}
```

### Auto-generated Test Stub

When a story is created, generate test stubs:

```typescript
// Auto-generated from story acceptance criteria
import { describe, it, expect } from 'vitest'

describe('Story: User Registration', () => {
  describe('AC1: User can register with email and password', () => {
    it('should register new user successfully', () => {
      // TODO: Implement test
      expect(true).toBe(false)
    })
  })

  describe('AC2: API returns 201 on successful registration', () => {
    it('should return 201 with user data', () => {
      // TODO: Implement test
      expect(true).toBe(false)
    })
  })

  // ... more test stubs
})
```

## fulltest-skill Integration

### Invoking fulltest After Each Stage

```xml
<!-- After completing API stage -->
<Task subagent_type="fulltesting-agent" prompt="
Test Stage 2 (API Implementation) at http://localhost:3000

Focus areas:
- New API endpoints: /api/users, /api/auth/login, /api/auth/register
- Database interactions for user CRUD
- Authentication middleware

Coverage requirements:
- All API endpoints return correct status codes (200, 201, 400, 401, 404)
- No unhandled promise rejections
- Database connections are properly closed
- Response schemas match OpenAPI spec

Test types needed:
- Integration tests for each endpoint
- Unit tests for validation logic
- Error handling tests

Report format: JSON with pass/fail per endpoint and coverage metrics
"/>
```

### Phase 4 Full Validation

```xml
<Task subagent_type="fulltesting-agent" prompt="
Complete Phase 4 validation for User Management product at http://localhost:3000

Comprehensive testing checklist:

1. E2E User Flows:
   - User registration → login → profile update → logout
   - Admin creating users → assigning roles → viewing audit log
   - Password reset flow: request → email → reset → login

2. API Testing:
   - All endpoints in /api/users, /api/auth, /api/admin
   - Authentication required endpoints reject unauthorized requests
   - Rate limiting works (max 100 req/min per IP)

3. UI Testing:
   - All pages render without console errors
   - Forms show validation errors correctly
   - Loading states display during async operations
   - Mobile responsive (320px to 1920px)

4. Performance:
   - Page load times under 2s
   - API response times under 500ms
   - No memory leaks during navigation

5. Security:
   - XSS protection on all inputs
   - CSRF tokens on mutations
   - SQL injection prevention verified

Coverage target: 85% overall, 95% for auth logic

Generate:
- Detailed test report (JSON)
- List of failed tests with reproduction steps
- Coverage report
- Performance metrics
- Security audit summary
"/>
```

## Test File Organization

### Recommended Structure

```
my-product/
├── src/
│   ├── app/
│   │   └── api/
│   │       └── users/
│   │           ├── route.ts
│   │           └── route.test.ts          # Co-located API tests
│   ├── components/
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.test.tsx            # Co-located component tests
│   │   │   └── Button.stories.tsx         # Storybook stories
│   │   └── UserList/
│   │       ├── UserList.tsx
│   │       └── UserList.test.tsx
│   ├── lib/
│   │   ├── auth.ts
│   │   └── auth.test.ts                   # Co-located utility tests
│   └── hooks/
│       ├── useUser.ts
│       └── useUser.test.ts
├── tests/
│   ├── e2e/
│   │   ├── auth.spec.ts                   # E2E tests
│   │   ├── user-management.spec.ts
│   │   └── admin-flows.spec.ts
│   ├── integration/
│   │   ├── api-integration.test.ts        # Cross-service tests
│   │   └── database-integration.test.ts
│   ├── helpers/
│   │   ├── test-db.ts                     # Test utilities
│   │   ├── mock-data.ts
│   │   └── test-server.ts
│   └── setup.ts                           # Global test setup
├── playwright.config.ts
├── vitest.config.ts
└── coverage/                               # Generated coverage reports
```

## Coverage Tracking in master-project.json

### Testing Metadata Structure

```json
{
  "productId": "user-management-v1",
  "productName": "User Management System",
  "testing": {
    "framework": {
      "unit": "vitest",
      "integration": "vitest",
      "e2e": "playwright"
    },
    "coverage": {
      "target": 85,
      "current": 82.5,
      "byType": {
        "statements": 83.2,
        "branches": 78.5,
        "functions": 85.1,
        "lines": 82.5
      },
      "byArea": {
        "api": 88.0,
        "components": 79.0,
        "utilities": 92.0,
        "hooks": 75.0
      }
    },
    "testCounts": {
      "unit": 145,
      "integration": 32,
      "e2e": 18,
      "total": 195
    },
    "e2ePassRate": 100,
    "lastTestRun": "2024-01-15T14:30:00Z",
    "lastFullSuite": "2024-01-15T12:00:00Z",
    "averageTestDuration": "45s",
    "flakyTests": [],
    "skippedTests": [
      "src/lib/payment.test.ts - PayPal integration (external service)"
    ]
  },
  "qualityGates": {
    "minCoverage": 80,
    "maxE2EFailures": 0,
    "maxFlakyTests": 2,
    "maxSkippedTests": 5
  }
}
```

## Test Commands Configuration

### package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:unit": "vitest run --coverage",
    "test:watch": "vitest watch",
    "test:integration": "vitest run --config vitest.integration.config.ts",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:headed": "playwright test --headed",
    "test:all": "npm run test:unit && npm run test:integration && npm run test:e2e",
    "test:coverage": "vitest run --coverage && playwright test",
    "test:ci": "npm run test:all -- --reporter=junit --coverage"
  }
}
```

### vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/**/*.test.{ts,tsx}',
        'src/**/*.stories.{ts,tsx}',
        'src/types/**',
        'src/**/*.d.ts'
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 75,
        statements: 80
      }
    }
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  }
})
```

## When to Run Which Tests

### Development Workflow

| Action | Tests to Run | Command | Why |
|--------|-------------|---------|-----|
| After writing function | Unit tests for that file | `vitest path/to/file.test.ts` | Immediate feedback |
| Before committing | Changed files + related | `vitest related` | Catch regressions |
| After completing story | Unit + Integration | `npm run test:unit && npm run test:integration` | Verify acceptance criteria |
| After completing stage | Full test suite | `npm run test:all` | Ensure no breaks |
| Before PR | Full suite + coverage | `npm run test:coverage` | Quality gate |
| After merging | CI runs all tests | `npm run test:ci` | Final verification |

### Stage-Specific Testing

#### Stage 1: Foundation
- ✅ Config validation tests
- ✅ Environment setup tests
- ⏭️ Skip API/UI tests (nothing to test yet)

#### Stage 2: Database
- ✅ Migration tests
- ✅ Schema validation tests
- ✅ Seed data tests
- ⏭️ Skip E2E tests

#### Stage 3: API/Backend
- ✅ Unit tests for business logic
- ✅ Integration tests for endpoints
- ✅ API contract tests
- ⏭️ E2E tests (no UI yet)

#### Stage 4: Frontend
- ✅ Component unit tests
- ✅ Integration tests (components + API)
- ✅ E2E tests for completed flows

#### Stage 5: Full Integration
- ✅ All test types
- ✅ Performance tests
- ✅ Security tests
- ✅ Accessibility tests

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run test:unit

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run test:integration

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run test:e2e
      - uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
```

## Summary Checklist

Before marking a stage complete, verify:

- [ ] All acceptance criteria have corresponding tests
- [ ] Tests are passing (0 failures)
- [ ] Coverage meets targets (80%+ for new code)
- [ ] No skipped tests without justification
- [ ] E2E tests cover happy paths
- [ ] Error cases are tested
- [ ] Tests are deterministic (no flakiness)
- [ ] Test data is isolated and cleaned up
- [ ] CI pipeline runs tests successfully
- [ ] Coverage report generated and reviewed
