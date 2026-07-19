# Page Topology — wirebot.trade

Single landing page, one vertical scroll column, no horizontal overflow (`main` has `overflow-x-hidden`).
Root: `<main class="min-h-screen bg-black text-wire-cyan overflow-x-hidden page-enter">`.

Sections top→bottom (desktop 1440px positions):

| # | Component | Element | Position | Height | Interaction model |
|---|-----------|---------|----------|--------|-------------------|
| 1 | `NavBar` | `<nav>` sticky top-0 z-50 | 0 | 59px | static (sticky, hover states only — does NOT change on scroll) |
| 2 | `HeroSection` | `<section>` min-h-[78vh] | 59 | 786px | time-driven (boot line stagger, flicker/glitch CSS animations) |
| 3 | `TickerMarquee` | `<div>` | 845 | 33px | time-driven (CSS marquee 25s loop) |
| 4 | `AboutSection` | `<section id="about">` | 878 | 685px | static + hover |
| 5 | `GuideSection` | `<section id="guide">` | 1563 | 613px | static + hover |
| 6 | `CommandsSection` | `<section>` | 2176 | 642px | static + hover |
| 7 | `SecuritySection` | `<section>` | 2818 | 443px | static + hover |
| 8 | `LiveFeed` | `<section id="feed">` | 3260 | 474px | time-driven (polls /api/feed every 8s; 15s re-render tick) |
| 9 | `Footer` | `<footer>` | 3734 | 195px | static + hover |

Total document height: 3929px @1440px viewport.

## Page-level notes
- `html { scroll-behavior: smooth; scroll-padding-top: 72px; }` (reduced-motion → auto). Nav anchors (#about, #guide, #feed) rely on this. NO smooth-scroll library (no Lenis/Locomotive).
- `html.dark` class is set (dark always on).
- Base CSS on html: `background:#000; color:var(--cyan); font-family:"Share Tech Mono",ui-monospace,monospace; -webkit-font-smoothing:none;`
- z-index layers: nav z-50 only; everything else flows.
- Sections 4–7 all use the pattern: `max-w-5xl mx-auto` wrapper, `// SECTION LABEL` kicker (font-mono text-xs text-wire-muted tracking-[0.4em] mb-2), ASCII divider line `╠══…╣` (font-mono text-[10px] text-wire-border mb-8 or mb-10), then a `grid gap-px bg-wire-border` grid of `bg-black` cells (1px "borders" are grid gaps showing the bg).
- Framework of original: Next.js App Router + Tailwind v3 + next-auth. Feed data via `/api/feed?limit=25`.
- Out of scope: `/docs` page, `/dashboard`, real auth (`/api/auth/session`). Nav/footer keep `/docs` href as-is.

## Source artifacts (authoritative)
- `docs/research/wirebot.trade/page.html` — full SSR HTML (exact classes + text for everything)
- `docs/research/wirebot.trade/site.css` — full CSS (19.8KB)
- `docs/research/wirebot.trade/page-chunk.js` — minified page component source (all client logic)
- `docs/research/wirebot.trade/feed-sample.json` — real /api/feed response (25 items + stats)
