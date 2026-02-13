---
name: website-design
description: Create professional B2B SaaS websites, dashboards, landing pages, and web applications with modern UX/UI best practices. Use when Claude needs to design marketing websites, product dashboards, admin panels, landing pages, or any B2B-focused web interface. Covers full-stack design from hero sections to pricing pages, with emphasis on conversion optimization, data visualization, and professional aesthetics using Tailwind CSS, React, and modern web standards.
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - WebFetch
  - WebSearch
  - mcp__firecrawl__*
  - mcp__memory__*
memory: user
---

# Website Design Skill

Create professional, conversion-optimized B2B SaaS websites and dashboards with modern UX/UI best practices.

## When to Use This Skill

- Building B2B SaaS marketing websites
- Creating product dashboards and admin panels
- Designing landing pages for lead generation
- Building pricing pages and feature comparisons
- Creating data visualization dashboards
- Any professional web interface requiring modern UX/UI

## Workflow

1. **Understand Context** - Clarify industry, target audience, brand identity, conversion goals
2. **Select Page Type** - Homepage, landing page, dashboard, pricing, features, etc.
3. **Choose Design System** - Define color palette, typography, spacing scale
4. **Build Structure** - Create component hierarchy and layout
5. **Implement** - Code with Tailwind CSS + React (or HTML/CSS)
6. **Refine** - Add micro-interactions, polish details
7. **Deliver** - Output to `/mnt/user-data/outputs/`

---

## Atomic Tools vs Outcomes

### Agent-Native Design Principle

This skill follows the **Agent-native principle**: "Tools should be atomic primitives. Features are outcomes achieved by an agent operating in a loop."

### Atomic Tools Used

The website-design skill uses these atomic primitives:

- **Read** - Read existing design files, brand guidelines, inspiration references
- **Write** - Generate HTML/JSX components, CSS/Tailwind classes
- **Edit** - Refine components, adjust styling, fix issues
- **Glob/Grep** - Search for existing components, find design patterns in codebase
- **Bash** - Run dev servers, build processes, optimization tools
- **WebFetch** - Analyze competitor sites, gather design inspiration
- **WebSearch** - Research design trends, accessibility guidelines, component libraries
- **mcp**memory**\*** - Save design decisions, component patterns, client preferences

**Key insight**: This skill does NOT provide a `design_website(specs)` tool that outputs finished HTML. Instead, it uses atomic tools iteratively to achieve the design outcome.

### Outcomes Achieved via Prompts

The workflow steps are **outcomes**, not hardcoded procedures:

1. **Understand Context** - Outcome: "Gather requirements about industry, audience, brand, and goals"
   - Agent asks clarifying questions, uses Read to check existing brand docs, searches web for industry examples
   - The questions asked vary based on project type (dashboard vs landing page), guided by context prompts

2. **Select Page Type** - Outcome: "Determine the optimal page structure for the use case"
   - Agent considers conversion goals, content needs, technical constraints
   - Selection emerges from prompts about purpose, not from a fixed menu

3. **Choose Design System** - Outcome: "Define cohesive visual identity matching brand and industry"
   - Agent queries memory for client preferences, references color/typography guides, adapts to project
   - Design system emerges from aesthetic prompts and brand guidelines, not templates

4. **Build Structure** - Outcome: "Create semantic component hierarchy with proper layout"
   - Agent uses Write to create components, follows accessibility prompts, implements responsive patterns
   - Structure decisions guided by UX best practices in prompts

5. **Implement** - Outcome: "Write production-ready code with modern standards"
   - Agent writes JSX/HTML/CSS using atomic tools, following coding prompts and standards
   - Implementation adapts to tech stack, not locked to React

6. **Refine** - Outcome: "Add polish, micro-interactions, and accessibility improvements"
   - Agent uses Edit iteratively, checks against accessibility prompts, tests responsiveness
   - Refinement is prompt-guided, not a checklist

7. **Deliver** - Outcome: "Output optimized, documented code ready for integration"
   - Agent uses Write for final files, Bash for optimization, creates documentation
   - Delivery format adapts to project needs

### How to Modify Behavior via Prompts

**Want different design aesthetics?**

Edit the color palette section or add new palettes to the skill documentation. The agent will adapt its color selections based on these new aesthetic prompts.

**Want different component patterns?**

Modify the component examples section or add new patterns. The agent learns from these examples and applies them contextually.

**Want industry-specific design guidelines?**

Add vertical-specific prompts to the skill documentation:

```markdown
### Industry Design Guidelines

**Financial Services**

- Use conservative color palette (navy, gray, white)
- Emphasize security badges and trust signals prominently
- Include disclaimer text and regulatory information
- Minimize flashy animations, prioritize clarity

**Healthcare Tech**

- Use calming colors (soft blue, green, white)
- Large, readable typography (min 16px body)
- High contrast for accessibility (WCAG AAA)
- Patient testimonials with photos for trust

**Developer Tools**

- Dark mode as default
- Code syntax highlighting in examples
- Terminal/CLI-style components
- Technical accuracy over marketing fluff
```

The agent will adapt designs based on industry context from these prompts.

**Want different dashboard layouts?**

Add new layout patterns to the skill's dashboard section. The agent will reference these patterns when creating dashboards.

**Want to change typography philosophy?**

Update the font pairing section with new design philosophies and the agent will adapt its typography selections accordingly.

### Contrast: Workflow-Shaped Anti-Pattern

**What this skill does NOT do:**

```javascript
// Anti-pattern: Hardcoded design generator
function generate_website(pageType, industry) {
  const template = TEMPLATES[pageType]; // Locked templates
  const colors = INDUSTRY_COLORS[industry]; // Fixed palettes
  const components = template.map((component) => {
    return renderComponent(component, colors); // Hardcoded rendering
  });
  return assembleHTML(components); // Fixed assembly
}
```

**What this skill DOES:**

The agent receives outcome-oriented design prompts:

- "Create a B2B SaaS homepage that builds trust and drives demo bookings"
- "Design a financial dashboard emphasizing key metrics and actionable insights"
- "Build a landing page optimized for conversion with clear value proposition"

The agent uses atomic tools (Write, Edit, Read, WebFetch) to achieve these outcomes. Design decisions emerge from:

- Best practice prompts in the skill definition
- Industry context from user input
- Inspiration from WebFetch competitor analysis
- Learned patterns from Memory MCP
- Iterative refinement based on requirements

### Example: Adapting to Design Trends

**Scenario**: Glassmorphism becomes popular in Q2 2026.

**Without code changes**, add glassmorphism patterns to the visual effects section of the skill documentation. The agent immediately incorporates glassmorphism into designs where appropriate, guided by these new aesthetic prompts.

### Memory-Driven Design Evolution

Save successful design patterns to evolve behavior:

```javascript
// After delivering a high-performing dashboard
mcp__memory__create_entities({
  entities: [
    {
      name: "component-pattern:analytics-dashboard-header",
      entityType: "component-pattern",
      observations: [
        "Component: Dashboard header with time range selector",
        "Use case: Analytics dashboards needing date filtering",
        "Key classes: sticky top-0 z-40 backdrop-blur-xl bg-white/80",
        "Features: Integrated time range picker, export button, real-time status badge",
        "Proven in: Contably analytics, MNA portfolio reporter",
        "User feedback: Sticky header with blur was highly praised",
        "Variation: Light/dark mode with automatic theme detection",
        "Accessibility: Keyboard shortcuts for common date ranges (Alt+T)",
      ],
    },
  ],
});
```

Next time the agent designs an analytics dashboard, it queries memory and reuses this proven header pattern, applying learned improvements without any code modification.

---

## Memory Integration

This skill uses Memory MCP to learn and improve across design sessions.

### Memory Entity Types

| Type                | Purpose                                       | Example                                  |
| ------------------- | --------------------------------------------- | ---------------------------------------- |
| `design-decision`   | Color, typography, layout choices per project | `design-decision:contably-colors`        |
| `component-pattern` | Reusable component patterns that worked well  | `component-pattern:dashboard-stats-card` |
| `client-preference` | Client/project-specific preferences           | `client-preference:nuvini-brand`         |
| `design-insight`    | General learnings about design                | `design-insight:dark-mode-contrast`      |

### When to Query Memory

**At project start:**

```javascript
// Check for existing project preferences
mcp__memory__search_nodes({ query: "client-preference:{project}" });
mcp__memory__search_nodes({ query: "design-decision:{project}" });

// Load successful patterns
mcp__memory__search_nodes({ query: "component-pattern:dashboard" });
mcp__memory__search_nodes({ query: "design-insight" });
```

### When to Save to Memory

**After successful design delivery:**

```javascript
// Save project-specific decisions
mcp__memory__create_entities({
  entities: [
    {
      name: "design-decision:{project}-{aspect}",
      entityType: "design-decision",
      observations: [
        "Project: {project_name}",
        "Decision: {what was chosen}",
        "Rationale: {why}",
        "Colors: {palette}",
        "Typography: {fonts}",
        "Delivered: {date}",
      ],
    },
  ],
});

// Save reusable component patterns
mcp__memory__create_entities({
  entities: [
    {
      name: "component-pattern:{component-name}",
      entityType: "component-pattern",
      observations: [
        "Component: {name}",
        "Use case: {when to use}",
        "Key classes: {tailwind classes}",
        "Variations: {light/dark, sizes}",
        "Proven in: {project_name}",
      ],
    },
  ],
});
```

**After learning something new:**

```javascript
// Save design insights
mcp__memory__create_entities({
  entities: [
    {
      name: "design-insight:{topic}",
      entityType: "design-insight",
      observations: [
        "Insight: {what was learned}",
        "Context: {when it applies}",
        "Source: {how discovered}",
        "Discovered: {date}",
      ],
    },
  ],
});
```

### Memory-Enhanced Workflow

1. **Start** - Query memory for project/client preferences
2. **Design** - Apply learned patterns, reference successful components
3. **Deliver** - Save decisions, patterns, and insights to memory
4. **Improve** - Patterns become more refined with each use

---

## B2B SaaS Website Best Practices

### Homepage Essential Elements

| Element          | Purpose          | Best Practice                                            |
| ---------------- | ---------------- | -------------------------------------------------------- |
| Hero Section     | First impression | Clear value prop, single CTA, product visual             |
| Social Proof     | Build trust      | Client logos, testimonials, review badges (G2, Capterra) |
| Feature Overview | Explain product  | 3-6 key features with icons/visuals                      |
| Use Cases        | Show relevance   | Segment by role/industry                                 |
| Pricing Preview  | Qualify leads    | Show tiers or "starts at" pricing                        |
| Final CTA        | Convert          | Strong call-to-action above footer                       |

### Hero Section Formula

```
[Headline]: What you do + who it's for
[Subheadline]: How you do it differently
[Primary CTA]: "Start Free Trial" / "Book Demo"
[Secondary CTA]: "Watch Video" / "See Pricing"
[Visual]: Product screenshot or demo animation
[Social Proof]: "Trusted by 500+ companies"
```

### Navigation Best Practices

- **Max 6-7 items** in primary nav
- Use mega menus for complex products
- Sticky navigation for long pages
- Clear CTAs in nav (contrasting color)
- Mobile-first responsive design

### Trust Signals to Include

- Client logos (recognizable brands)
- Review platform ratings (G2, Capterra, Trustpilot)
- Security badges (SOC2, GDPR, ISO)
- Case study metrics ("40% cost reduction")
- Team/founder photos for startups

---

## Dashboard Design Best Practices

### Dashboard UX Principles

1. **Information Hierarchy** - Most important data top-left (F-pattern scanning)
2. **5-6 Card Maximum** - Don't overwhelm the initial view
3. **Progressive Disclosure** - Summary first, drill-down for details
4. **Consistent Visual Language** - Same chart styles, colors, spacing
5. **Action-Oriented** - Every metric should lead to an action

### Dashboard Layout Pattern

```
┌─────────────────────────────────────────────────────┐
│ Header: Logo | Navigation | Search | User Profile  │
├────────────┬────────────────────────────────────────┤
│            │  KPI Cards (3-4 key metrics)          │
│  Sidebar   ├────────────────────────────────────────┤
│  Navigation│  Primary Chart (trend/comparison)     │
│            ├─────────────────┬──────────────────────┤
│            │  Secondary      │  Data Table/List    │
│            │  Chart          │                     │
└────────────┴─────────────────┴──────────────────────┘
```

### Data Visualization Guidelines

| Data Type        | Best Chart    | When to Use                |
| ---------------- | ------------- | -------------------------- |
| Trends over time | Line chart    | Revenue, users, growth     |
| Comparisons      | Bar chart     | Category comparison        |
| Proportions      | Pie/Donut     | Market share, distribution |
| KPIs             | Stat cards    | Single important numbers   |
| Relationships    | Scatter plot  | Correlation analysis       |
| Progress         | Progress bars | Goals, completion rates    |

### Dashboard Color Usage

- **Primary color**: Brand identity, primary actions
- **Success (green)**: Positive trends, completed states
- **Warning (amber)**: Attention needed, thresholds
- **Error (red)**: Critical issues, negative trends
- **Neutral (gray)**: Supporting text, borders

**Accessibility Note**: Never rely on color alone. Use icons, patterns, or labels alongside color indicators.

---

## Modern Color Palettes

### B2B SaaS Color Strategies

**Professional Trust (Blue-based)**

```css
--primary: #2563eb; /* Trust blue */
--primary-dark: #1e40af;
--accent: #f97316; /* Orange accent */
--background: #f8fafc;
--text: #0f172a;
```

**Modern Tech (Purple gradient)**

```css
--primary: #7c3aed; /* Vibrant purple */
--primary-light: #a78bfa;
--accent: #06b6d4; /* Cyan accent */
--background: #fafafa;
--text: #18181b;
```

**Minimal Elegance (Monochrome + accent)**

```css
--primary: #18181b; /* Near black */
--primary-light: #52525b;
--accent: #f43f5e; /* Rose accent */
--background: #ffffff;
--text: #27272a;
```

**Dark Mode Dashboard**

```css
--bg-primary: #0f172a; /* Deep slate */
--bg-secondary: #1e293b;
--bg-card: #334155;
--text-primary: #f1f5f9;
--text-secondary: #94a3b8;
--accent: #3b82f6;
```

### The 60-30-10 Rule

- **60%**: Dominant color (background, large areas)
- **30%**: Secondary color (containers, sections)
- **10%**: Accent color (CTAs, highlights, links)

---

## Typography System

### Recommended Font Pairings

**Professional SaaS**

```css
--font-display: "Plus Jakarta Sans", sans-serif;
--font-body: "Inter", sans-serif;
```

**Modern Tech**

```css
--font-display: "Satoshi", sans-serif;
--font-body: "DM Sans", sans-serif;
```

**Editorial/Content**

```css
--font-display: "Fraunces", serif;
--font-body: "Source Sans Pro", sans-serif;
```

**Distinctive/Bold**

```css
--font-display: "Cabinet Grotesk", sans-serif;
--font-body: "General Sans", sans-serif;
```

### Type Scale (Tailwind default)

```
text-xs:   0.75rem  (12px)  - Labels, captions
text-sm:   0.875rem (14px)  - Secondary text
text-base: 1rem     (16px)  - Body text
text-lg:   1.125rem (18px)  - Large body
text-xl:   1.25rem  (20px)  - Subheadings
text-2xl:  1.5rem   (24px)  - Section headings
text-3xl:  1.875rem (30px)  - Page headings
text-4xl:  2.25rem  (36px)  - Hero subheadlines
text-5xl:  3rem     (48px)  - Hero headlines
text-6xl:  3.75rem  (60px)  - Marketing headlines
```

---

## Tailwind CSS Implementation

### Component Patterns

**Hero Section**

```jsx
<section className="relative min-h-[80vh] bg-gradient-to-br from-slate-50 to-blue-50">
  <div className="container mx-auto px-6 py-24">
    <div className="grid lg:grid-cols-2 gap-16 items-center">
      {/* Content */}
      <div className="space-y-8">
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 rounded-full text-blue-700 text-sm font-medium">
          <span className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></span>
          New Feature Released
        </div>
        <h1 className="text-5xl lg:text-6xl font-bold text-slate-900 leading-tight">
          Automate your <span className="text-blue-600">workflow</span> in
          minutes
        </h1>
        <p className="text-xl text-slate-600 leading-relaxed max-w-lg">
          The all-in-one platform that helps teams collaborate, automate, and
          scale their operations.
        </p>
        <div className="flex flex-wrap gap-4">
          <button className="px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl shadow-lg shadow-blue-500/30 transition-all hover:shadow-xl hover:shadow-blue-500/40">
            Start Free Trial
          </button>
          <button className="px-8 py-4 bg-white hover:bg-slate-50 text-slate-700 font-semibold rounded-xl border border-slate-200 transition-colors">
            Watch Demo
          </button>
        </div>
        {/* Social Proof */}
        <div className="flex items-center gap-8 pt-4">
          <div className="flex -space-x-3">{/* Avatar stack */}</div>
          <div className="text-sm text-slate-600">
            <span className="font-semibold text-slate-900">2,500+</span> teams
            trust us
          </div>
        </div>
      </div>
      {/* Product Visual */}
      <div className="relative">
        <div className="absolute inset-0 bg-gradient-to-r from-blue-500 to-purple-500 rounded-3xl blur-3xl opacity-20"></div>
        <img
          src="/dashboard-preview.png"
          alt="Dashboard"
          className="relative rounded-2xl shadow-2xl"
        />
      </div>
    </div>
  </div>
</section>
```

**Dashboard Stats Card**

```jsx
<div className="bg-white rounded-xl border border-slate-200 p-6 hover:shadow-lg transition-shadow">
  <div className="flex items-start justify-between">
    <div>
      <p className="text-sm font-medium text-slate-500">Total Revenue</p>
      <p className="text-3xl font-bold text-slate-900 mt-1">$45,231</p>
      <div className="flex items-center gap-1 mt-2">
        <span className="inline-flex items-center text-sm font-medium text-emerald-600">
          <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
            <path
              fillRule="evenodd"
              d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z"
              clipRule="evenodd"
            />
          </svg>
          +12.5%
        </span>
        <span className="text-sm text-slate-500">vs last month</span>
      </div>
    </div>
    <div className="p-3 bg-blue-50 rounded-lg">
      <svg className="w-6 h-6 text-blue-600" /* icon */ />
    </div>
  </div>
</div>
```

**Feature Grid**

```jsx
<div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
  {features.map((feature) => (
    <div
      key={feature.title}
      className="group p-8 bg-white rounded-2xl border border-slate-200 hover:border-blue-500 hover:shadow-xl transition-all"
    >
      <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center text-white mb-6 group-hover:scale-110 transition-transform">
        {feature.icon}
      </div>
      <h3 className="text-xl font-semibold text-slate-900 mb-3">
        {feature.title}
      </h3>
      <p className="text-slate-600 leading-relaxed">{feature.description}</p>
    </div>
  ))}
</div>
```

---

## Landing Page Optimization

### Above the Fold Checklist

- [ ] Clear headline stating the value proposition
- [ ] Subheadline explaining how you deliver value
- [ ] Primary CTA (high contrast, action verb)
- [ ] Product visualization or demo
- [ ] Social proof (logos, numbers, reviews)
- [ ] No navigation distractions (consider hiding nav)

### Conversion Rate Optimization

1. **Single Focus** - One goal per landing page
2. **Benefit-First Copy** - Lead with outcomes, not features
3. **Visual Hierarchy** - Guide eyes to CTA
4. **Friction Reduction** - Minimize form fields
5. **Urgency/Scarcity** - Limited time offers (if genuine)
6. **Trust Elements** - Reviews, security badges, guarantees

### Pricing Page Best Practices

- Highlight recommended tier visually
- Use annual toggle with savings percentage
- Feature comparison table for enterprise
- Include FAQ section below pricing
- Add social proof specific to each tier
- Clear CTA on each pricing card

---

## Animation & Micro-interactions

### CSS Animation Patterns

**Fade In Up (Page Load)**

```css
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in-up {
  animation: fadeInUp 0.6s ease-out forwards;
}
```

**Staggered Children**

```jsx
{
  items.map((item, i) => (
    <div
      key={item.id}
      className="animate-fade-in-up"
      style={{ animationDelay: `${i * 100}ms` }}
    >
      {item.content}
    </div>
  ));
}
```

**Hover Effects**

```jsx
// Scale on hover
<button className="transform hover:scale-105 transition-transform duration-200">

// Lift with shadow
<div className="hover:-translate-y-1 hover:shadow-xl transition-all duration-300">

// Glow effect
<button className="hover:shadow-lg hover:shadow-blue-500/30 transition-shadow">
```

---

## Responsive Design

### Breakpoint Strategy

```css
/* Mobile first approach */
sm:  640px   /* Landscape phones */
md:  768px   /* Tablets */
lg:  1024px  /* Laptops */
xl:  1280px  /* Desktops */
2xl: 1536px  /* Large screens */
```

### Common Responsive Patterns

```jsx
{/* Stack to grid */}
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">

{/* Responsive padding */}
<section className="px-4 md:px-8 lg:px-16 py-12 md:py-20">

{/* Hide/show elements */}
<nav className="hidden lg:flex">
<button className="lg:hidden">Menu</button>

{/* Responsive typography */}
<h1 className="text-3xl md:text-4xl lg:text-5xl xl:text-6xl">
```

---

## Accessibility Checklist

- [ ] Sufficient color contrast (4.5:1 for text)
- [ ] Focus states visible on all interactive elements
- [ ] Alt text on all meaningful images
- [ ] Semantic HTML structure (header, main, nav, footer)
- [ ] Keyboard navigation works throughout
- [ ] Form labels associated with inputs
- [ ] Error messages are descriptive
- [ ] Skip to main content link
- [ ] Responsive down to 320px width
- [ ] Reduced motion support: `prefers-reduced-motion`

---

## Quick Reference Templates

See `templates/` folder for ready-to-use components:

- `hero-sections.jsx` - 5 hero section variants
- `feature-sections.jsx` - Grid, alternating, bento layouts
- `pricing-cards.jsx` - 3-tier pricing with toggle
- `testimonials.jsx` - Cards, carousel, wall layouts
- `dashboard-layouts.jsx` - Sidebar, topbar, analytics
- `data-cards.jsx` - Stats, charts, tables

See `references/` folder for:

- `inspiration-sites.md` - Curated B2B SaaS examples
- `color-palettes.md` - 20+ tested color combinations
- `typography-pairings.md` - Font combination guide

---

## Completion Signals

This skill explicitly signals completion via structured status returns. Never rely on heuristics like "consecutive iterations without tool calls" to detect completion.

### Completion Signal Format

At the end of design work, return:

```json
{
  "status": "complete|partial|blocked|failed",
  "deliveryType": "homepage|landing-page|dashboard|full-site",
  "summary": "Brief description of what was designed",
  "deliverables": ["List of files created"],
  "designSystem": {
    "colors": "palette-name",
    "typography": "font-pairing",
    "components": 0
  },
  "userActionRequired": "What user should do next (if any)"
}
```

### Success Signal (Complete Design)

```json
{
  "status": "complete",
  "deliveryType": "full-site",
  "summary": "Professional B2B SaaS marketing site with 5 pages",
  "deliverables": [
    "/mnt/user-data/outputs/homepage.tsx",
    "/mnt/user-data/outputs/features.tsx",
    "/mnt/user-data/outputs/pricing.tsx",
    "/mnt/user-data/outputs/about.tsx",
    "/mnt/user-data/outputs/contact.tsx",
    "/mnt/user-data/outputs/design-system.md"
  ],
  "designSystem": {
    "colors": "Professional Trust (Blue-based)",
    "typography": "Plus Jakarta Sans + Inter",
    "components": 15
  },
  "pageCount": 5,
  "responsive": true,
  "accessible": "WCAG AA compliant",
  "outputLocation": "/mnt/user-data/outputs/"
}
```

### Success Signal (Dashboard Design)

```json
{
  "status": "complete",
  "deliveryType": "dashboard",
  "summary": "Analytics dashboard with data visualization components",
  "deliverables": [
    "/mnt/user-data/outputs/DashboardLayout.tsx",
    "/mnt/user-data/outputs/StatsCards.tsx",
    "/mnt/user-data/outputs/ChartComponents.tsx",
    "/mnt/user-data/outputs/DataTable.tsx"
  ],
  "designSystem": {
    "colors": "Dark Mode Dashboard",
    "typography": "Satoshi + DM Sans",
    "chartLibrary": "Recharts"
  },
  "componentCount": 12,
  "dataVisualizationTypes": [
    "line-chart",
    "bar-chart",
    "stat-cards",
    "data-table"
  ],
  "darkMode": true,
  "outputLocation": "/mnt/user-data/outputs/"
}
```

### Partial Completion Signal

```json
{
  "status": "partial",
  "deliveryType": "landing-page",
  "summary": "Hero and features sections complete, pricing section in progress",
  "completedSections": [
    "Hero section with CTA",
    "Feature grid (6 features)",
    "Social proof section",
    "Testimonial carousel"
  ],
  "remainingSections": ["Pricing cards", "FAQ accordion", "Footer"],
  "deliverables": [
    "/mnt/user-data/outputs/HeroSection.tsx",
    "/mnt/user-data/outputs/FeatureGrid.tsx",
    "/mnt/user-data/outputs/Testimonials.tsx"
  ],
  "userActionRequired": "Review completed sections before proceeding with pricing design"
}
```

### Blocked Signal

```json
{
  "status": "blocked",
  "deliveryType": "homepage",
  "summary": "Cannot proceed without brand guidelines and content",
  "blockers": [
    "Missing brand colors and logo",
    "No product screenshots or visuals provided",
    "Headline and copy not finalized",
    "Target audience not clearly defined"
  ],
  "userInputRequired": "Please provide: 1) Brand colors/logo, 2) Product screenshots, 3) Headline/copy preferences, 4) Target audience description"
}
```

### Failed Signal

```json
{
  "status": "failed",
  "deliveryType": "dashboard",
  "summary": "Design generation failed - requirements conflict",
  "errors": [
    "Requested both minimalist design and feature-rich dashboard",
    "Color palette conflicts with accessibility requirements",
    "Component count exceeds reasonable dashboard complexity"
  ],
  "recoverySuggestions": [
    "Clarify design priorities: minimalist vs feature-rich",
    "Adjust color palette for WCAG AA compliance",
    "Break dashboard into multiple views/tabs",
    "Prioritize top 5 metrics for initial view"
  ]
}
```

### When to Signal

- **After complete design delivery**: Signal "complete" with all deliverables and design system details
- **After section completion**: Signal "partial" if some sections done but awaiting feedback
- **Missing requirements**: Signal "blocked" immediately with clear list of needed inputs
- **Conflicting requirements**: Signal "failed" with specific conflicts and suggestions
- **Before user review**: Signal status and list deliverables THEN ask for feedback

### Special Cases

**Iterative design:**

```json
{
  "status": "complete",
  "summary": "Homepage design iteration 2 - incorporated user feedback",
  "iterationNumber": 2,
  "changes": [
    "Simplified hero section",
    "Updated color scheme to warmer tones",
    "Added client logo section",
    "Refined CTA copy"
  ],
  "deliverables": ["/mnt/user-data/outputs/homepage-v2.tsx"]
}
```

**Design system only:**

```json
{
  "status": "complete",
  "deliveryType": "design-system",
  "summary": "Complete design system with color palette, typography, and component library",
  "deliverables": [
    "/mnt/user-data/outputs/design-system.md",
    "/mnt/user-data/outputs/tailwind.config.js",
    "/mnt/user-data/outputs/color-swatches.md"
  ],
  "readyForImplementation": true
}
```

---

## Delivery Checklist

Before delivering website designs:

- [ ] All pages responsive (mobile → desktop)
- [ ] Color contrast meets WCAG AA
- [ ] Interactive states (hover, focus, active)
- [ ] Loading states for async actions
- [ ] Empty states for data-dependent views
- [ ] Error states for forms/failures
- [ ] Consistent spacing (8px grid)
- [ ] Production-ready code (no TODOs)
- [ ] Images optimized (WebP, lazy loading)
- [ ] SEO meta tags included
