# Environment Configuration Reference

Practical patterns for environment variable management across different stacks and deployment platforms.

---

## Environment File Templates

### Base `.env.example` Template

Every project should include a `.env.example` file committed to version control:

```env
# ===========================================
# Application Configuration
# ===========================================
NODE_ENV=development
APP_URL=http://localhost:3000
PORT=3000

# ===========================================
# Database
# ===========================================
DATABASE_URL=

# ===========================================
# Authentication
# ===========================================
NEXTAUTH_SECRET=
NEXTAUTH_URL=http://localhost:3000

# ===========================================
# External Services
# ===========================================
# Add service-specific variables as needed

# ===========================================
# Feature Flags (optional)
# ===========================================
ENABLE_ANALYTICS=false
ENABLE_DEBUG_MODE=true
```

---

## Stack-Specific Templates

### Next.js + Supabase

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Optional: Direct database connection for migrations
DATABASE_URL=postgresql://postgres:[password]@db.[ref].supabase.co:5432/postgres
DIRECT_URL=postgresql://postgres:[password]@db.[ref].supabase.co:5432/postgres
```

### Next.js + Prisma + PostgreSQL

```env
# Prisma Database URLs
# Pooled connection for application queries
DATABASE_URL=postgresql://user:password@host:5432/dbname?pgbouncer=true

# Direct connection for migrations
DIRECT_URL=postgresql://user:password@host:5432/dbname
```

### Next.js + Clerk Authentication

```env
# Clerk Authentication
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...

# Clerk URLs (optional customization)
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding
```

### Next.js + NextAuth.js

```env
# NextAuth Configuration
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=generate-with-openssl-rand-base64-32

# OAuth Providers
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

### API + External Services

```env
# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# Email (Resend)
RESEND_API_KEY=re_...

# AI Services
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Storage (AWS S3 / Cloudflare R2)
S3_ACCESS_KEY_ID=
S3_SECRET_ACCESS_KEY=
S3_BUCKET_NAME=
S3_REGION=us-east-1
```

---

## Environment Separation

### Development (`.env.local`)

Local development environment. Never committed to version control.

```env
NODE_ENV=development
APP_URL=http://localhost:3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myapp_dev
```

### Staging (`.env.staging`)

Staging environment for testing before production. Use separate credentials.

```env
NODE_ENV=staging
APP_URL=https://staging.myapp.com
DATABASE_URL=postgresql://user:pass@staging-db.example.com:5432/myapp_staging
```

### Production

Production environment variables should NEVER be stored in files. Use platform-native environment variable management.

---

## Secrets Management Best Practices

### Core Principles

1. **Never commit secrets** - Add `.env*` (except `.env.example`) to `.gitignore`
2. **Use platform secret management** - Vercel, Railway, and DigitalOcean all have secure env var storage
3. **Rotate credentials regularly** - Especially after team changes or suspected exposure
4. **Minimum privilege principle** - Each service should have only the permissions it needs
5. **Separate secrets per environment** - Never share production secrets with development

### Recommended `.gitignore` Entries

```gitignore
# Environment files
.env
.env.local
.env.development
.env.staging
.env.production
.env*.local

# Keep the example file
!.env.example
```

### Secret Generation

```bash
# Generate secure random strings for secrets
openssl rand -base64 32

# Generate UUID for API keys
uuidgen | tr '[:upper:]' '[:lower:]'
```

---

## Environment Validation

Validate environment variables at build/startup time to fail fast on misconfiguration.

### Zod Schema Validation

```typescript
// src/lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  // Required
  DATABASE_URL: z.string().url('DATABASE_URL must be a valid URL'),
  NEXTAUTH_SECRET: z.string().min(32, 'NEXTAUTH_SECRET must be at least 32 characters'),
  NEXTAUTH_URL: z.string().url(),

  // Optional with defaults
  NODE_ENV: z.enum(['development', 'staging', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),

  // Conditional (required in production)
  STRIPE_SECRET_KEY: z.string().optional().refine(
    (val) => process.env.NODE_ENV !== 'production' || !!val,
    'STRIPE_SECRET_KEY is required in production'
  ),
});

// Parse and export validated environment
export const env = envSchema.parse(process.env);

// Type export for use throughout the application
export type Env = z.infer<typeof envSchema>;
```

### T3 Env (Recommended for Next.js)

```typescript
// src/env.mjs
import { createEnv } from '@t3-oss/env-nextjs';
import { z } from 'zod';

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().url(),
    NEXTAUTH_SECRET: z.string().min(32),
  },
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url(),
  },
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    NEXTAUTH_SECRET: process.env.NEXTAUTH_SECRET,
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  },
});
```

---

## Platform-Specific Setup

### Vercel

Environment variables are set per environment (Production, Preview, Development).

```bash
# CLI setup
vercel env add DATABASE_URL production
vercel env add DATABASE_URL preview
vercel env add DATABASE_URL development

# Pull env vars for local development
vercel env pull .env.local
```

### Railway

```bash
# Link project
railway link

# Add variables
railway variables set DATABASE_URL="postgresql://..."

# Pull for local development
railway run env > .env.local
```

### DigitalOcean App Platform

Environment variables in `app.yaml` spec:

```yaml
name: my-app
services:
  - name: web
    environment_slug: node-js
    envs:
      - key: DATABASE_URL
        scope: RUN_TIME
        value: ${db.DATABASE_URL}
      - key: NEXTAUTH_SECRET
        scope: RUN_TIME
        type: SECRET
        value: EV[1:encrypted-value]
```

---

## Checklist for Go-Live

Before deploying to production, verify all environment configuration:

### Required Variables

- [ ] All required environment variables are set in the platform
- [ ] No placeholder values (e.g., `your-api-key-here`)
- [ ] Database URLs point to production database
- [ ] Authentication secrets are production values (not test keys)

### Security

- [ ] All secrets rotated from development/staging
- [ ] Service role keys restricted to minimum necessary permissions
- [ ] Webhook secrets configured and validated
- [ ] No `NEXT_PUBLIC_` prefix on sensitive values

### URLs and Domains

- [ ] `APP_URL` / `NEXTAUTH_URL` set to production domain
- [ ] OAuth callback URLs updated in provider dashboards
- [ ] Webhook URLs updated in external service dashboards
- [ ] CORS origins configured correctly

### Validation

- [ ] Environment validation passes at build time
- [ ] Application starts without environment errors
- [ ] Health check endpoint responds correctly
- [ ] Database connections successful

### Monitoring

- [ ] Error tracking configured (Sentry, etc.)
- [ ] Logging service connected
- [ ] Performance monitoring enabled

---

## Common Issues and Solutions

### Issue: `NEXT_PUBLIC_` variables not available client-side

Variables must be prefixed and available at build time:

```env
# Correct - available client-side
NEXT_PUBLIC_API_URL=https://api.example.com

# Incorrect - server-only
API_URL=https://api.example.com
```

### Issue: Database connection pooling errors

Use connection pooling in serverless environments:

```env
# With pgbouncer or similar
DATABASE_URL=postgresql://...?pgbouncer=true&connection_limit=1
```

### Issue: Environment variables undefined in production

Ensure variables are set for the correct environment scope (build vs. runtime):

- **Build-time**: Variables needed during `next build`
- **Runtime**: Variables needed when the application runs

---

## Quick Reference Commands

```bash
# Check if env file exists
ls -la .env*

# Validate env file syntax
cat .env | grep -v '^#' | grep -v '^$' | grep '='

# Count defined variables
grep -c '=' .env.example

# Find undefined variables (requires values)
grep -E '^[A-Z_]+=\s*$' .env

# Compare env files
diff .env.example .env.local
```
