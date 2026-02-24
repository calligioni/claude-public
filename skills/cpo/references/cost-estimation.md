# Cost Estimation Reference

Guide for estimating project costs and resource requirements in CPO AI workflows.

## When to Show Estimates

1. **End of Phase 2 (Planning)** - Before user approves strategic plan
2. **Significant scope changes** - When epics/stages are added or removed
3. **On explicit request** - User asks "show costs", "what will this cost", "estimate pricing"
4. **Before deployment** - Final cost verification in Phase 5

## Resource Estimation Template

Display after Phase 2 planning is complete:

```markdown
## Resource Estimate: [Project Name]

### Development Scope
| Metric | Value |
|--------|-------|
| Epics | 4 |
| Stages | 12 |
| User Stories | 36 |
| Estimated Complexity | Medium |
| Estimated Timeline | 4-6 weeks (with AI assistance) |

### Infrastructure Costs (Monthly)

#### MVP / Launch Phase
| Service | Tier | Cost | Notes |
|---------|------|------|-------|
| Vercel | Hobby | $0 | 100GB bandwidth, hobby projects |
| Supabase | Free | $0 | 500MB DB, 1GB storage |
| Domain | - | ~$1/month | ~$12/year amortized |
| **Total** | | **~$1/month** | |

#### Growth Phase (1K-10K users)
| Service | Tier | Cost | Notes |
|---------|------|------|-------|
| Vercel | Pro | $20/month | Unlimited bandwidth, analytics |
| Supabase | Pro | $25/month | 8GB DB, 100GB storage |
| Domain | - | ~$1/month | Same domain |
| **Total** | | **~$46/month** | |

#### Scale Phase (10K+ users)
| Service | Tier | Cost | Notes |
|---------|------|------|-------|
| Vercel | Pro | $20/month | May need multiple seats |
| Supabase | Pro | $25-100/month | Based on DB size |
| CDN/Extras | - | $10-50/month | Images, caching |
| **Total** | | **~$55-170/month** | |

### Cost Projections

**First 6 Months**: ~$3-10 (mostly free tier)
**First Year**: ~$100-300 (depends on growth)
**Year 2+**: ~$300-2000/year (scales with users)

💡 **Recommendation**: Start with free tiers, upgrade as you grow. Most costs are pay-as-you-go.
```

## Infrastructure Cost Reference

### Hosting Platforms

| Provider | Free Tier | Paid Tier | Best For | Notes |
|----------|-----------|-----------|----------|-------|
| **Vercel** | 100GB bandwidth, unlimited sites | $20/seat/month | Next.js, React, static | Best DX, auto-scaling |
| **Railway** | $5 credit/month | Usage-based ($0.000463/GB-sec) | Full-stack apps | Simple deployment |
| **Netlify** | 100GB bandwidth | $19/seat/month | Static sites, JAMstack | Great for marketing sites |
| **Cloudflare Pages** | Unlimited requests | $5/month (Workers Paid) | Static + edge functions | Best free tier |
| **Render** | 750 hrs/month | $7/month per service | Docker, any stack | Good for side projects |
| **Fly.io** | 3 VMs free | Usage-based (~$10/month) | Global apps | Good global distribution |

### Database Services

| Provider | Free Tier | Paid Tier | Best For | Notes |
|----------|-----------|-----------|----------|-------|
| **Supabase** | 500MB DB, 1GB storage | $25/month (8GB DB) | Postgres + Auth + Storage | All-in-one solution |
| **Neon** | 0.5GB storage | $19/month (10GB) | Serverless Postgres | Auto-pause, branching |
| **PlanetScale** | 1B row reads/month | $29/month | MySQL, high-scale | Great for growth |
| **MongoDB Atlas** | 512MB storage | $9/month (2GB shared) | NoSQL | Good free tier |
| **Firebase** | 1GB storage | Pay-as-you-go | Real-time apps | Best for mobile |
| **Turso** | 9GB storage | $29/month | SQLite at edge | Very fast reads |

### Authentication

| Provider | Free Tier | Paid Tier | Best For | Notes |
|----------|-----------|-----------|----------|-------|
| **Clerk** | 10K MAU | $25/month (10K MAU) | React/Next.js | Best DX, beautiful UI |
| **Supabase Auth** | Unlimited | Included in DB tier | All-in-one | Free with Supabase |
| **Auth0** | 7,500 MAU | $35/month (500 MAU then $0.07/MAU) | Enterprise needs | Feature-rich |
| **Firebase Auth** | Unlimited | Free (pay for usage) | Mobile-first | Good free tier |
| **NextAuth.js** | Self-hosted (free) | Free (OSS) | Next.js | Most flexible |

### Storage & CDN

| Provider | Free Tier | Paid Tier | Best For | Notes |
|----------|-----------|-----------|----------|-------|
| **Cloudflare R2** | 10GB storage | $0.015/GB/month | Object storage | No egress fees |
| **Vercel Blob** | Included | $0.15/GB stored | Next.js apps | Easy integration |
| **Supabase Storage** | 1GB | Included in tier | User uploads | S3-compatible |
| **Cloudinary** | 25GB bandwidth | $99/month | Images/video | Auto-optimization |
| **UploadThing** | 2GB storage | $10/month (10GB) | File uploads | Simple API |

### Email Services

| Provider | Free Tier | Paid Tier | Best For | Notes |
|----------|-----------|-----------|----------|-------|
| **Resend** | 3,000/month | $20/month (50K) | Transactional | Best DX |
| **SendGrid** | 100/day | $20/month (50K) | Established apps | Reliable |
| **Postmark** | 100/month | $15/month (10K) | Critical emails | Best deliverability |
| **AWS SES** | 62,000/month (from EC2) | $0.10/1000 | High volume | Cheapest at scale |

### Monitoring & Analytics

| Provider | Free Tier | Paid Tier | Best For | Notes |
|----------|-----------|-----------|----------|-------|
| **Vercel Analytics** | Included (2.5K events) | $10/month (100K events) | Vercel apps | Zero-config |
| **PostHog** | 1M events/month | $450/month | Product analytics | Open source option |
| **LogRocket** | 1,000 sessions/month | $99/month | Session replay | Great for debugging |
| **Sentry** | 5K errors/month | $26/month | Error tracking | Industry standard |

## Complexity Estimation

### Complexity Matrix

| Complexity | Stories | Stages | Timeline | Characteristics |
|------------|---------|--------|----------|-----------------|
| **Low** | 5-15 | 3-5 | 1-2 weeks | Single feature, no auth, static data |
| **Medium** | 15-30 | 5-10 | 3-6 weeks | Auth + CRUD + basic UI, 1-2 integrations |
| **High** | 30-50 | 10-15 | 6-12 weeks | Multiple integrations, complex UI, real-time |
| **Enterprise** | 50+ | 15+ | 3-6 months | Multi-tenant, advanced security, microservices |

### Complexity Indicators

**Increases Complexity:**
- User authentication (+1 level)
- Real-time features (+1 level)
- Payment processing (+1 level)
- Multi-tenant architecture (+1-2 levels)
- Complex permissions/RBAC (+1 level)
- External API integrations (+0.5 per integration)
- File uploads/processing (+0.5 level)
- Email notifications (+0.5 level)

**Examples:**

| Project Type | Complexity | Why |
|--------------|------------|-----|
| Landing page with waitlist | Low | Static content, simple form |
| Blog with admin panel | Medium | Auth, CRUD, rich text editor |
| SaaS dashboard | High | Auth, payments, multi-user, analytics |
| Marketplace platform | Enterprise | Multi-tenant, payments, search, messaging |

## Cost Calculation Logic

### Estimation Function

```javascript
function estimateInfrastructureCost(productDefinition) {
  const { scope, techStack, scale, features } = productDefinition;

  // Base costs by tier
  const hosting = getHostingCost(techStack.hosting, scale);
  const database = getDatabaseCost(techStack.database, scale);
  const auth = getAuthCost(techStack.auth, scale);
  const storage = getStorageCost(features.fileUploads, scale);
  const email = getEmailCost(features.notifications, scale);
  const extras = getExtrasCost(features, scale);

  const monthly = hosting + database + auth + storage + email + extras;

  return {
    mvp: calculateMVPCost(techStack),
    monthly: monthly,
    firstYear: (monthly * 12) + getDomainCost(),
    atScale: estimateAtScale(monthly, scale),
    breakdown: { hosting, database, auth, storage, email, extras }
  };
}

function getHostingCost(provider, scale) {
  const costs = {
    vercel: { mvp: 0, growth: 20, scale: 20 },
    railway: { mvp: 5, growth: 15, scale: 30 },
    cloudflare: { mvp: 0, growth: 5, scale: 20 },
    render: { mvp: 0, growth: 7, scale: 25 }
  };

  return costs[provider]?.[scale] || 0;
}

function getDatabaseCost(provider, scale) {
  const costs = {
    supabase: { mvp: 0, growth: 25, scale: 50 },
    neon: { mvp: 0, growth: 19, scale: 40 },
    planetscale: { mvp: 0, growth: 29, scale: 60 },
    mongodb: { mvp: 0, growth: 9, scale: 30 }
  };

  return costs[provider]?.[scale] || 0;
}

function getAuthCost(provider, scale) {
  const costs = {
    clerk: { mvp: 0, growth: 25, scale: 100 },
    supabase: { mvp: 0, growth: 0, scale: 0 }, // Included with DB
    auth0: { mvp: 0, growth: 35, scale: 200 },
    nextauth: { mvp: 0, growth: 0, scale: 0 } // Self-hosted
  };

  return costs[provider]?.[scale] || 0;
}
```

### Scale Definitions

- **MVP**: < 100 users, testing product-market fit
- **Growth**: 100-10K users, proven concept
- **Scale**: 10K+ users, established product

## Cost Display Examples

### Example 1: Simple SaaS Dashboard

```markdown
## Resource Estimate: TaskFlow Dashboard

### Development Scope
| Metric | Value |
|--------|-------|
| Epics | 3 (Auth, Tasks, Analytics) |
| Stages | 9 |
| User Stories | 24 |
| Estimated Complexity | Medium |

### Infrastructure Costs

**Stack**: Next.js (Vercel) + Supabase + Clerk

**MVP Phase** (< 100 users): **$0/month**
- Vercel Hobby (free)
- Supabase Free (free)
- Clerk Free (free)

**Growth Phase** (1K users): **$50/month**
- Vercel Pro ($20)
- Supabase Pro ($25)
- Clerk Starter ($25) - over 10K MAU
- Domain (~$1)

**First Year Projection**: ~$100-300 depending on growth
```

### Example 2: E-commerce Platform

```markdown
## Resource Estimate: ShopLocal Marketplace

### Development Scope
| Metric | Value |
|--------|-------|
| Epics | 6 (Auth, Products, Cart, Payments, Admin, Analytics) |
| Stages | 18 |
| User Stories | 54 |
| Estimated Complexity | High |

### Infrastructure Costs

**Stack**: Next.js (Vercel) + Supabase + Stripe

**MVP Phase**: **$0/month** + Stripe fees (2.9% + $0.30)
- All services on free tier

**Growth Phase** (1K orders/month): **~$150/month**
- Vercel Pro ($20)
- Supabase Pro ($25)
- Cloudinary ($99) - product images
- Stripe fees (~$87 on $3K revenue at 2.9%)
- Email ($20) - transactional emails

**First Year Projection**: ~$600-1200 + payment processing fees
```

## Important Disclaimers

### Always Include

1. **Estimates are approximate** - Actual costs depend on usage patterns
2. **Free tiers have limits** - Bandwidth, storage, requests vary
3. **Prices change** - Provider pricing updated regularly
4. **Hidden costs exist** - Development time, maintenance, support
5. **Usage-based pricing** - Some services charge per request/user
6. **Growth is unpredictable** - Viral growth can spike costs

### Standard Disclaimer Text

```markdown
⚠️ **Cost Disclaimer**

These estimates are rough guidelines based on typical usage. Actual costs may vary based on:
- Traffic patterns and user behavior
- Geographic distribution of users
- Feature usage (storage, bandwidth, compute)
- Provider pricing changes
- Promotional credits and discounts

Start with free tiers and monitor usage. Most platforms have generous free tiers for MVP validation.
```

## Tips for Cost Optimization

1. **Start Free**: Use free tiers until you validate product-market fit
2. **Monitor Usage**: Set up billing alerts before hitting limits
3. **Optimize Early**: Images, caching, queries affect costs significantly
4. **Bundle Services**: All-in-one solutions (Supabase) often cheaper than piecing together
5. **Edge Computing**: Cloudflare Workers/Pages can reduce hosting costs
6. **Self-Host Selectively**: Some services (NextAuth) save money when self-hosted
7. **Annual Billing**: Often 10-20% cheaper than monthly
8. **Educational Credits**: Many providers offer startup/education credits

## When NOT to Estimate

- Pre-Phase 2 (before scope is defined)
- For exploratory prototypes
- When user hasn't asked and scope is obvious
- For trivial projects (< 5 stories)

Keep estimates visible but not overwhelming. Focus on actionable insights.
