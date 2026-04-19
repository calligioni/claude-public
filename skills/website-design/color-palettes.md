# Color Palettes for B2B SaaS Websites

Tested, production-ready color combinations for professional web design.

---

## Professional Trust Palettes

### Corporate Blue
```css
/* Classic B2B trust palette */
--primary-50: #eff6ff;
--primary-100: #dbeafe;
--primary-500: #3b82f6;
--primary-600: #2563eb;
--primary-700: #1d4ed8;
--accent: #f97316;        /* Orange for CTAs */
--success: #10b981;
--warning: #f59e0b;
--error: #ef4444;
--neutral-50: #f8fafc;
--neutral-900: #0f172a;
```
Best for: Enterprise software, financial services, healthcare

### Navy Professional
```css
--primary: #1e3a5f;
--primary-light: #3d5a80;
--accent: #ee6c4d;        /* Coral accent */
--background: #f7f9fc;
--text: #1e293b;
--text-muted: #64748b;
```
Best for: Consulting, legal tech, B2B services

---

## Modern Tech Palettes

### Vibrant Purple
```css
--primary-500: #8b5cf6;
--primary-600: #7c3aed;
--primary-700: #6d28d9;
--secondary: #06b6d4;     /* Cyan */
--accent: #f43f5e;        /* Rose */
--background: #fafafa;
--surface: #ffffff;
--text: #18181b;
```
Best for: AI/ML products, creative tools, startups

### Electric Indigo
```css
--primary: #4f46e5;
--primary-light: #818cf8;
--accent: #22d3ee;        /* Cyan */
--success: #34d399;
--background: #f5f5f7;
--text: #111827;
```
Best for: Developer tools, tech platforms

---

## Minimal & Elegant Palettes

### Monochrome + Accent
```css
--primary: #18181b;
--primary-light: #3f3f46;
--accent: #f43f5e;        /* Rose red */
--accent-hover: #e11d48;
--background: #ffffff;
--surface: #fafafa;
--border: #e4e4e7;
--text: #27272a;
--text-muted: #71717a;
```
Best for: Design tools, premium products, luxury SaaS

### Warm Neutral
```css
--primary: #292524;
--primary-light: #57534e;
--accent: #ea580c;        /* Orange */
--background: #fafaf9;
--surface: #f5f5f4;
--border: #e7e5e4;
--text: #1c1917;
--text-muted: #78716c;
```
Best for: Lifestyle brands, creative agencies

---

## Dark Mode Palettes

### Slate Dark
```css
--bg-primary: #0f172a;
--bg-secondary: #1e293b;
--bg-tertiary: #334155;
--surface: #475569;
--border: #475569;
--text-primary: #f1f5f9;
--text-secondary: #94a3b8;
--text-muted: #64748b;
--primary: #3b82f6;
--primary-hover: #60a5fa;
```
Best for: Developer tools, technical products

### True Dark
```css
--bg-primary: #09090b;
--bg-secondary: #18181b;
--bg-tertiary: #27272a;
--surface: #3f3f46;
--border: #3f3f46;
--text-primary: #fafafa;
--text-secondary: #a1a1aa;
--primary: #a855f7;       /* Purple */
--accent: #22d3ee;        /* Cyan */
```
Best for: Gaming, media, entertainment SaaS

### Charcoal Warm
```css
--bg-primary: #1a1a1a;
--bg-secondary: #262626;
--bg-tertiary: #333333;
--text-primary: #f5f5f5;
--text-secondary: #a3a3a3;
--accent: #fbbf24;        /* Amber */
--success: #4ade80;
```
Best for: Analytics dashboards, productivity tools

---

## Dashboard-Specific Palettes

### Analytics Dashboard (Light)
```css
--bg-page: #f8fafc;
--bg-card: #ffffff;
--bg-sidebar: #1e293b;
--border: #e2e8f0;

/* Chart colors */
--chart-1: #3b82f6;       /* Primary blue */
--chart-2: #8b5cf6;       /* Purple */
--chart-3: #06b6d4;       /* Cyan */
--chart-4: #10b981;       /* Emerald */
--chart-5: #f59e0b;       /* Amber */
--chart-6: #ef4444;       /* Red */

/* Status */
--status-success: #10b981;
--status-warning: #f59e0b;
--status-error: #ef4444;
--status-info: #3b82f6;
```

### Financial Dashboard
```css
--positive: #10b981;      /* Green - gains */
--negative: #ef4444;      /* Red - losses */
--neutral: #6b7280;       /* Gray - unchanged */
--highlight: #fbbf24;     /* Gold - important */
--chart-primary: #2563eb;
--chart-secondary: #7c3aed;
```

---

## Gradient Combinations

### Hero Backgrounds
```css
/* Subtle blue gradient */
background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 50%, #f0f9ff 100%);

/* Purple mesh */
background: linear-gradient(135deg, #faf5ff 0%, #f3e8ff 50%, #ede9fe 100%);

/* Warm gradient */
background: linear-gradient(135deg, #fff7ed 0%, #ffedd5 50%, #fef3c7 100%);

/* Dark gradient */
background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%);
```

### CTA Button Gradients
```css
/* Blue energy */
background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);

/* Purple power */
background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);

/* Success green */
background: linear-gradient(135deg, #10b981 0%, #059669 100%);

/* Premium gold */
background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
```

---

## Accessibility Notes

### Contrast Requirements (WCAG AA)
- Normal text (< 18px): 4.5:1 ratio minimum
- Large text (≥ 18px bold or ≥ 24px): 3:1 ratio minimum
- UI components: 3:1 ratio minimum

### Color Blind Considerations
- Don't use red/green alone for status
- Add icons or patterns alongside colors
- Test with color blindness simulators

### Tools
- WebAIM Contrast Checker: webaim.org/resources/contrastchecker/
- Colorable: colorable.jxnblk.com
- Stark (Figma plugin)
- Sim Daltonism (Mac app)

---

## Quick Copy Tailwind Configs

### Professional Blue Theme
```js
// tailwind.config.js
theme: {
  extend: {
    colors: {
      primary: {
        50: '#eff6ff',
        100: '#dbeafe',
        200: '#bfdbfe',
        300: '#93c5fd',
        400: '#60a5fa',
        500: '#3b82f6',
        600: '#2563eb',
        700: '#1d4ed8',
        800: '#1e40af',
        900: '#1e3a8a',
      },
      accent: {
        DEFAULT: '#f97316',
        hover: '#ea580c',
      }
    }
  }
}
```

### Dark Mode Dashboard
```js
// tailwind.config.js
theme: {
  extend: {
    colors: {
      dark: {
        bg: '#0f172a',
        surface: '#1e293b',
        card: '#334155',
        border: '#475569',
      }
    }
  }
}
```
