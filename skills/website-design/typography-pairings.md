# Typography Pairings for Web Design

Professional font combinations for B2B SaaS websites and dashboards.

---

## Premium Sans-Serif Pairings

### 1. Plus Jakarta Sans + Inter
```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Plus+Jakarta+Sans:wght@500;600;700;800&display=swap');

--font-display: 'Plus Jakarta Sans', sans-serif;
--font-body: 'Inter', sans-serif;
```
**Character**: Modern, friendly, professional
**Best for**: General SaaS, productivity tools
**Example**: H1 in Plus Jakarta 700, body in Inter 400

### 2. Satoshi + DM Sans
```css
/* Satoshi from fontshare.com */
--font-display: 'Satoshi', sans-serif;
--font-body: 'DM Sans', sans-serif;
```
**Character**: Contemporary, geometric, clean
**Best for**: Design tools, creative platforms
**Why it works**: Satoshi's geometric forms + DM Sans readability

### 3. Cabinet Grotesk + General Sans
```css
/* Both from fontshare.com */
--font-display: 'Cabinet Grotesk', sans-serif;
--font-body: 'General Sans', sans-serif;
```
**Character**: Bold, distinctive, startup energy
**Best for**: Innovative products, modern startups
**Tip**: Use Cabinet Grotesk sparingly for headlines only

### 4. Space Grotesk + Work Sans
```css
@import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=Work+Sans:wght@400;500;600&display=swap');

--font-display: 'Space Grotesk', sans-serif;
--font-body: 'Work Sans', sans-serif;
```
**Character**: Technical, modern, approachable
**Best for**: Developer tools, technical products

### 5. Manrope + Source Sans Pro
```css
@import url('https://fonts.googleapis.com/css2?family=Manrope:wght@500;600;700;800&family=Source+Sans+Pro:wght@400;600&display=swap');

--font-display: 'Manrope', sans-serif;
--font-body: 'Source Sans Pro', sans-serif;
```
**Character**: Rounded, modern, readable
**Best for**: HR tech, healthcare, friendly products

---

## Sans + Serif Pairings

### 6. Fraunces + Source Sans Pro
```css
@import url('https://fonts.googleapis.com/css2?family=Fraunces:wght@600;700&family=Source+Sans+Pro:wght@400;600&display=swap');

--font-display: 'Fraunces', serif;
--font-body: 'Source Sans Pro', sans-serif;
```
**Character**: Editorial, premium, sophisticated
**Best for**: Content platforms, publishing tools

### 7. Playfair Display + Lato
```css
@import url('https://fonts.googleapis.com/css2?family=Lato:wght@400;700&family=Playfair+Display:wght@600;700&display=swap');

--font-display: 'Playfair Display', serif;
--font-body: 'Lato', sans-serif;
```
**Character**: Elegant, traditional, trustworthy
**Best for**: Financial services, legal tech, luxury

### 8. Libre Baskerville + Open Sans
```css
@import url('https://fonts.googleapis.com/css2?family=Libre+Baskerville:wght@400;700&family=Open+Sans:wght@400;600&display=swap');

--font-display: 'Libre Baskerville', serif;
--font-body: 'Open Sans', sans-serif;
```
**Character**: Classic, professional, authoritative
**Best for**: Enterprise, consulting, education

---

## Monospace Accents

### For Code/Technical Content
```css
--font-mono: 'JetBrains Mono', 'Fira Code', 'SF Mono', monospace;
```

### Monospace Pairing Example
```css
--font-display: 'Space Grotesk', sans-serif;
--font-body: 'Inter', sans-serif;
--font-mono: 'JetBrains Mono', monospace;
```
**Use mono for**: Code snippets, API references, technical specs

---

## Dashboard-Specific Typography

### Data-Dense Dashboards
```css
/* Optimized for numbers and tables */
--font-ui: 'Inter', sans-serif;           /* Tabular numerals */
--font-data: 'Roboto Mono', monospace;    /* Numbers alignment */

/* Inter has tabular figures enabled with: */
font-feature-settings: 'tnum' 1;
```

### System Font Stack (Performance)
```css
/* Fastest loading option */
--font-system: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 
               'Helvetica Neue', Arial, sans-serif;
```

---

## Type Scale (Recommended)

### Marketing Pages
```css
/* Larger, more dramatic scale */
--text-hero: clamp(3rem, 8vw, 5rem);      /* 48-80px */
--text-h1: clamp(2.5rem, 5vw, 4rem);      /* 40-64px */
--text-h2: clamp(1.875rem, 4vw, 2.5rem);  /* 30-40px */
--text-h3: clamp(1.5rem, 3vw, 1.875rem);  /* 24-30px */
--text-body: 1.125rem;                     /* 18px */
--text-small: 0.875rem;                    /* 14px */
```

### Application/Dashboard UI
```css
/* Tighter, more functional scale */
--text-page-title: 1.5rem;     /* 24px */
--text-section: 1.25rem;       /* 20px */
--text-card-title: 1rem;       /* 16px */
--text-body: 0.875rem;         /* 14px */
--text-caption: 0.75rem;       /* 12px */
--text-label: 0.6875rem;       /* 11px */
```

---

## Font Weight Guidelines

### Headlines
- **Extra Bold (800)**: Hero headlines, splash pages
- **Bold (700)**: Page titles, section headers
- **Semi-Bold (600)**: Card titles, subheadings

### Body & UI
- **Medium (500)**: Buttons, nav items, labels
- **Regular (400)**: Body text, descriptions
- **Light (300)**: Secondary info, captions (use sparingly)

---

## Line Height & Spacing

### Line Height Rules
```css
/* Headings - tighter */
h1, h2, h3 { line-height: 1.2; }

/* Body text - comfortable */
p, li { line-height: 1.6; }

/* UI elements - snug */
button, label { line-height: 1.4; }
```

### Letter Spacing
```css
/* Uppercase text */
.uppercase { letter-spacing: 0.05em; }

/* Large headlines */
h1 { letter-spacing: -0.02em; }

/* Body text - normal */
p { letter-spacing: 0; }
```

---

## Free Font Resources

| Source | URL | Highlights |
|--------|-----|------------|
| Google Fonts | fonts.google.com | Largest free library |
| Fontshare | fontshare.com | High-quality free fonts |
| Fontsource | fontsource.org | NPM packages for fonts |
| Adobe Fonts | fonts.adobe.com | Premium (with CC subscription) |
| Font Squirrel | fontsquirrel.com | Commercial-use free fonts |

---

## Implementation Tips

### Performance
1. Limit to 2 font families maximum
2. Load only weights you need
3. Use `font-display: swap`
4. Preload critical fonts
5. Consider variable fonts

### Preload Critical Fonts
```html
<link rel="preload" href="/fonts/inter-var.woff2" as="font" type="font/woff2" crossorigin>
```

### Variable Font Example
```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter-var.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap;
}
```

---

## Fonts to Avoid (Overused)

⚠️ These fonts are technically fine but overused in generic AI/template designs:
- Inter (alone, without pairing)
- Poppins (everywhere)
- Roboto (Android default)
- Arial/Helvetica (system defaults)
- Open Sans (overexposed)

**Instead**: Pair common fonts creatively, or choose distinctive alternatives like Satoshi, General Sans, or Plus Jakarta Sans.
