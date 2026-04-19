# Production Monitoring Reference

Production monitoring setup for Phase 5 (Delivery). Covers error tracking, analytics,
uptime monitoring, and performance metrics for post-launch observability.

---

## 1. Monitoring Overview

### Why Monitoring Matters Post-Launch

Once deployed, you lose direct visibility into what users experience. Monitoring answers:
- **Is the app working?** - Uptime and health checks
- **What's breaking?** - Error tracking with stack traces
- **How are users behaving?** - Analytics and funnel analysis
- **Is it fast enough?** - Performance metrics and Core Web Vitals

### Three Pillars of Production Monitoring

| Pillar | Purpose | Key Question |
|--------|---------|--------------|
| **Errors** | Catch exceptions and failures | What's breaking? |
| **Analytics** | Understand user behavior | How do users interact? |
| **Uptime** | Ensure availability | Is the app accessible? |

### Free Tier Options for MVPs

| Service | Free Tier | Best For |
|---------|-----------|----------|
| Sentry | 5K errors/month | Error tracking |
| PostHog | 1M events/month | Product analytics |
| BetterStack | 10 monitors | Uptime monitoring |
| Checkly | 5 checks | Synthetic monitoring |
| Vercel Analytics | Included | Web vitals |

---

## 2. Error Tracking (Sentry)

### Setup

```bash
npm install @sentry/nextjs
npx @sentry/wizard@latest -i nextjs
```

### Configuration

```typescript
// sentry.client.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 1.0,
  environment: process.env.NODE_ENV,
});
```

### Environment Variables

```env
NEXT_PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx
SENTRY_AUTH_TOKEN=xxx
```

### Manual Error Capture

```typescript
import * as Sentry from "@sentry/nextjs";

try {
  await processPayment(orderId);
} catch (error) {
  Sentry.captureException(error, {
    tags: { feature: "payments" },
    extra: { orderId, userId: user.id },
  });
  throw error;
}
```

---

## 3. Analytics (PostHog)

### Setup

```bash
npm install posthog-js
```

### Configuration

```typescript
// lib/posthog.ts
import posthog from 'posthog-js';

if (typeof window !== 'undefined') {
  posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
    api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || 'https://app.posthog.com',
    capture_pageview: false, // Manual pageview tracking
  });
}

export { posthog };
```

### Event Tracking

```typescript
// Track key events
posthog.capture('task_created', {
  task_type: 'todo',
  has_due_date: true
});

posthog.capture('user_signed_up', {
  method: 'google'
});

// Identify users (call after login)
posthog.identify(user.id, {
  email: user.email,
  plan: user.subscription?.plan || 'free',
});
```

---

## 4. Uptime Monitoring (BetterStack/Checkly)

### Health Endpoint

```typescript
// app/api/health/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    // Check database connection
    await prisma.$queryRaw`SELECT 1`;

    return NextResponse.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || '1.0.0',
      checks: {
        database: 'ok',
        memory: process.memoryUsage().heapUsed / 1024 / 1024 + 'MB'
      }
    });
  } catch (error) {
    return NextResponse.json({
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 503 });
  }
}
```

### BetterStack Setup

1. Create account at betterstack.com
2. Add new monitor:
   - **URL**: `https://your-app.vercel.app/api/health`
   - **Check interval**: 1 minute (free tier)
   - **Expected status**: 200
3. Configure alerts (email, Slack)

---

## 5. Performance Monitoring (Vercel Analytics)

### Setup

```bash
npm install @vercel/analytics
```

### Integration

```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
```

---

## 6. Monitoring Checklist

```markdown
## Production Monitoring Checklist

### Error Tracking
- [ ] Sentry configured and tested
- [ ] Error alerts set up (email/Slack)
- [ ] Source maps uploaded for debugging

### Analytics
- [ ] PostHog/Mixpanel configured
- [ ] Key events identified and tracked
- [ ] User identification set up

### Uptime
- [ ] Health endpoint created
- [ ] Uptime monitor configured
- [ ] Alert thresholds set

### Performance
- [ ] Vercel Analytics enabled (if on Vercel)
- [ ] Core Web Vitals baseline established
```

---

## 7. Free Tier Comparison

| Service | Free Tier | Limits | Best For |
|---------|-----------|--------|----------|
| **Sentry** | 5K errors/month | 1 user, 30-day retention | Error tracking |
| **PostHog** | 1M events/month | Unlimited users | Product analytics |
| **BetterStack** | 10 monitors | 1-min interval | Uptime monitoring |
| **Checkly** | 5 checks | 50K check runs | Synthetic monitoring |
| **Vercel Analytics** | Included | Basic metrics | Web vitals |

---

## 8. Environment Variables for Monitoring

Add to `.env.example`:

```env
# Monitoring (Optional but recommended)
NEXT_PUBLIC_SENTRY_DSN=
SENTRY_AUTH_TOKEN=
NEXT_PUBLIC_POSTHOG_KEY=
NEXT_PUBLIC_POSTHOG_HOST=
```

---

## 9. Integration with Phase 5

Add monitoring setup to delivery phase:

```markdown
### Step 5.6: Setup Production Monitoring (Recommended)

Before marking launch complete, set up monitoring:

1. **Error Tracking:** Configure Sentry
2. **Analytics:** Set up PostHog
3. **Uptime:** Create health endpoint, configure BetterStack
4. **Test:** Trigger test error, verify alerts work

#### 5.6.1 Error Tracking
1. Create Sentry project
2. Run `npx @sentry/wizard@latest -i nextjs`
3. Add DSN to environment variables
4. Deploy and trigger test error
5. Verify error appears in Sentry dashboard

#### 5.6.2 Analytics
1. Create PostHog project
2. Install SDK and configure provider
3. Add key events (signup, key actions)
4. Identify users on login
5. Verify events in PostHog dashboard

#### 5.6.3 Uptime Monitoring
1. Create health endpoint at /api/health
2. Deploy to production
3. Create BetterStack monitor
4. Configure email/Slack alerts
5. Test alert by returning 503

#### 5.6.4 Verify Setup
- [ ] Trigger intentional error, check Sentry
- [ ] Perform tracked action, check PostHog
- [ ] Verify health endpoint returns 200
- [ ] Check uptime monitor shows green

Estimated time: 30-45 minutes
```

---

## 10. Troubleshooting

### Sentry Not Capturing Errors

```typescript
// Verify DSN is set
console.log("Sentry DSN:", process.env.NEXT_PUBLIC_SENTRY_DSN);

// Force capture for testing
import * as Sentry from "@sentry/nextjs";
Sentry.captureMessage("Test message from production");
```

### PostHog Events Not Appearing

```typescript
// Log to verify capture
posthog.capture("test_event", {}, { send_instantly: true });

// Check if opted out
console.log("PostHog opted out:", posthog.has_opted_out_capturing());
```

### Health Endpoint Timing Out

```typescript
// Add timeout to database query
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 5000);

try {
  await prisma.$queryRaw`SELECT 1`;
} finally {
  clearTimeout(timeout);
}
```

---

## Summary

Production monitoring is essential for maintaining quality post-launch. Start with:

1. **Sentry** for error tracking (catch bugs before users report them)
2. **PostHog** for analytics (understand user behavior)
3. **BetterStack** for uptime (know when you're down)
4. **Vercel Analytics** for performance (Core Web Vitals)

All services offer generous free tiers suitable for MVP stage. Setup takes 30-45 minutes
and provides invaluable visibility into production behavior.
