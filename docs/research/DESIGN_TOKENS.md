# Design Tokens — wirebot.trade

## Colors (exact, from CSS)
| Token | Value | Usage |
|-------|-------|-------|
| black | `#000000` | page + card cell background |
| wire-cyan | `#00FFFF` (`--cyan`) | primary text/accent/borders |
| wire-green | `#00FF41` (`--green`) | BUY/DROP rows, glitch :after, traffic dot |
| wire-purple | `#BF5FFF` (`--purple`) | SELL rows |
| wire-dim | `#003333` (`--dim`) | box-drawing chars in command cards, new-row highlight (at /60) |
| wire-muted | `#336666` | secondary text |
| wire-border | `#0A2020` | borders, grid gaps, faint ASCII art, timestamps |
| wire-card | `#030A0A` | ticker bg, feed bg, card hover bg |
| glitch magenta | `#FF00FF` | `.glitch:before` only |
| red-500 / yellow-500 | Tailwind defaults | feed terminal traffic lights |

## Typography
- **Share Tech Mono** (Google Fonts, weight 400 only) — body default AND `.font-mono`. `html{font-family:"Share Tech Mono",ui-monospace,monospace}`.
- **VT323** (Google Fonts, weight 400 only) — `.wire-title{font-family:VT323,monospace;line-height:1;letter-spacing:.05em}` (nav + footer wordmark).
- `html{-webkit-font-smoothing:none}` — gives the crisp pixel look. IMPORTANT for fidelity.
- Original loads via `@import url("https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=VT323&display=swap")` — clone uses `next/font/google`.

## Custom utility classes (copy verbatim into globals.css)
```css
.glow-cyan { text-shadow: 0 0 8px var(--cyan), 0 0 20px var(--cyan), 0 0 40px rgba(0,255,255,.4); }
.glow-green { text-shadow: 0 0 8px var(--green), 0 0 20px var(--green); }
.glow-purple { text-shadow: 0 0 8px var(--purple), 0 0 20px var(--purple); }
.glow-box-cyan { box-shadow: 0 0 10px rgba(0,255,255,.35), 0 0 22px rgba(0,255,255,.18); }
.glow-svg-cyan { filter: drop-shadow(0 0 5px var(--cyan)) drop-shadow(0 0 11px rgba(0,255,255,.55)); }
.wire-title { font-family: var(--font-vt323), VT323, monospace; line-height: 1; letter-spacing: .05em; }
.page-enter { animation: pageIn .5s ease-out both; }
.reveal { animation: riseIn .6s ease-out both; }  /* defined but unused on page */
.cursor::after { content: "█"; animation: blink 1s step-start infinite; }
.glitch { position: relative; display: inline-block; }
.glitch::before, .glitch::after { content: attr(data-text); position: absolute; inset: 0; pointer-events: none; overflow: hidden; }
.glitch::before { color: #ff00ff; clip-path: polygon(0 25%,100% 25%,100% 45%,0 45%); animation: glitch-before 3.5s infinite; }
.glitch::after { color: var(--green); clip-path: polygon(0 65%,100% 65%,100% 80%,0 80%); animation: glitch-after 4.1s infinite; }
.animate-blink { animation: blink 1s step-start infinite; }
.animate-flicker { animation: flicker 6s infinite; }
.animate-marquee { animation: marquee 25s linear infinite; }
```

## Keyframes (verbatim)
```css
@keyframes flicker {0%,100%{opacity:1}92%{opacity:1}93%{opacity:.4}94%{opacity:1}96%{opacity:.6}97%{opacity:1}}
@keyframes marquee {0%{transform:translateX(0)}100%{transform:translateX(-50%)}}
@keyframes pageIn {0%{opacity:0;transform:translateY(10px)}100%{opacity:1;transform:none}}
@keyframes riseIn {0%{opacity:0;transform:translateY(18px)}100%{opacity:1;transform:none}}
@keyframes glitch-before {0%,100%{transform:translate(0);opacity:0}8%{transform:translate(-4px,2px);opacity:.9}10%{transform:translate(4px,-2px);opacity:.9}12%{opacity:0}55%{transform:translate(-2px,1px);opacity:.4}57%{opacity:0}}
@keyframes glitch-after {0%,100%{transform:translate(0);opacity:0}25%{transform:translate(4px,3px);opacity:.8}27%{transform:translate(-4px,-3px);opacity:.8}29%{opacity:0}75%{transform:translate(3px);opacity:.3}77%{opacity:0}}
@keyframes blink {0%,100%{opacity:1}50%{opacity:0}}
```

## Assets
- `public/images/logo.png` (WIRE robot logo, used in nav 32×32 and footer 22×22 via next/image)
- `public/seo/favicon-16.png`, `favicon-32.png`, `favicon.png` (apple-touch), `banner.png` (OG)

## Metadata
- title: `WIRE — The command layer for finance`
- description: `Buy, sell, and send tokenized stocks on Robinhood Chain. Just tweet @wirebotRH.`
- og:title `WIRE`, og:description `Trade tokenized stocks by tweeting. No app. No wallet setup.`, og/twitter image `/seo/banner.png`, twitter:card `summary_large_image`.
