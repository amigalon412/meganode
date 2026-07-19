# Behaviors — wirebot.trade

All values below are extracted from the site's actual CSS/JS, not estimated.

## Global
- **Page enter:** `main` has `.page-enter` → `animation: pageIn .5s ease-out both` where `@keyframes pageIn {0%{opacity:0;transform:translateY(10px)} to{opacity:1;transform:none}}`. Runs once on load.
- **Smooth anchor scroll:** `html{scroll-behavior:smooth;scroll-padding-top:72px}` with `@media (prefers-reduced-motion)` → `auto`. No JS scroll library.
- **Sticky nav:** `sticky top-0 z-50 bg-black/85 backdrop-blur`. No scroll-triggered style change (verified: same at 0 and 3000px).

## Hero (time-driven)
1. **ASCII logo flicker:** `.animate-flicker` → `flicker 6s infinite`: `0%,to{opacity:1} 92%{opacity:1} 93%{opacity:.4} 94%{opacity:1} 96%{opacity:.6} 97%{opacity:1}`.
2. **Glitch overlay** on the ASCII `<pre class="glitch" data-text="...">`:
   - `.glitch{position:relative;display:inline-block}`
   - `:before` and `:after` = `content:attr(data-text);position:absolute;inset:0;pointer-events:none;overflow:hidden`
   - `:before{color:#ff00ff;clip-path:polygon(0 25%,100% 25%,100% 45%,0 45%);animation:glitch-before 3.5s infinite}`
   - `:after{color:var(--green);clip-path:polygon(0 65%,100% 65%,100% 80%,0 80%);animation:glitch-after 4.1s infinite}`
   - `@keyframes glitch-before{0%,to{transform:translate(0);opacity:0}8%{transform:translate(-4px,2px);opacity:.9}10%{transform:translate(4px,-2px);opacity:.9}12%{opacity:0}55%{transform:translate(-2px,1px);opacity:.4}57%{opacity:0}}`
   - `@keyframes glitch-after{0%,to{transform:translate(0);opacity:0}25%{transform:translate(4px,3px);opacity:.8}27%{transform:translate(-4px,-3px);opacity:.8}29%{opacity:0}75%{transform:translate(3px);opacity:.3}77%{opacity:0}}`
3. **Boot sequence** (React state): 4 lines, each `setTimeout` reveals index at delays **0 / 700 / 1400 / 2100 ms** after mount. Line class: `font-mono text-sm transition-all duration-200 {shown ? 'opacity-100' : 'opacity-0'} {isLast ? 'text-wire-cyan' : 'text-wire-muted'}`. After ALL 4 shown, append `<div class="text-wire-cyan font-mono text-sm cursor" />` — `.cursor:after{content:"█";animation:blink 1s step-start infinite}`; `@keyframes blink{0%,to{opacity:1}50%{opacity:0}}`.

## Ticker marquee (time-driven)
- Track: `flex animate-marquee whitespace-nowrap` → `marquee 25s linear infinite`, `@keyframes marquee{0%{transform:translateX(0)}to{transform:translateX(-50%)}}`.
- 8 phrases rendered TWICE (16 spans) so -50% loops seamlessly.

## Live feed (time-driven)
- On mount + every **8000ms**: `fetch('/api/feed?limit=25', {cache:'no-store'})` → `{items, stats}`.
- Separate **15000ms** interval forces re-render (updates relative time labels).
- **New-row highlight:** ids not seen before (skipped on very first load) get row class suffix `bg-wire-dim/60`, cleared after **2000ms**.
- **Pre-load state:** `<div class="text-wire-muted py-8 text-center"><span class="cursor">CONNECTING TO LEDGER</span></div>`.
- **timeAgo(ts):** `t = max(0, floor(now/1000 - ts))`; `<60 → "{t}s"`, `<3600 → "{floor(t/60)}m"`, `<86400 → "{floor(t/3600)}h"`, else `"{floor(t/86400)}d"`.
- **Stats header:** `{total.toLocaleString()} TX · ${Math.round(volumeUsd).toLocaleString()} VOL` (hidden below md).
- **LIVE dot:** `w-1.5 h-1.5 rounded-full bg-wire-cyan animate-blink` (blink 1s step-start infinite).
- **Action map:** buy → `▲ BUY` cls `text-wire-green glow-green`; sell → `▼ SELL` cls `text-wire-purple glow-purple`; send → `→ SEND` cls `text-wire-cyan glow-cyan`; drop → `🎁 DROP` cls `text-wire-green glow-green`; fallback → `• {action.toUpperCase()}` cls `text-wire-cyan`.
- Feed list container: `px-6 py-4 font-mono text-xs md:text-sm max-h-[440px] overflow-y-auto`, rows wrapper `space-y-1.5`.

## Hover states (all `transition-all` or `transition-colors`, default duration 150ms)
- Nav center links: `text-wire-cyan/80` → `hover:text-wire-cyan hover:glow-cyan` (glow = text-shadow, see DESIGN_TOKENS).
- Nav X icon btn / BUY $WIRE / CONNECT: bordered cyan → `hover:bg-wire-cyan hover:text-black`.
- Hero SIGN IN button: `hover:opacity-90 hover:shadow-[0_0_40px_rgba(0,255,255,0.35)]`.
- All grid cards (about/guide/commands/security): `bg-black hover:bg-wire-card transition-colors`.
- Command cards additionally: `group` → command text `group-hover:glow-cyan transition-all`.
- OPEN DOCS button: `border-wire-border` → `hover:border-wire-cyan hover:glow-cyan`.
- Footer links: `text-wire-muted hover:text-wire-cyan transition-colors`.
- Feed actor links: `text-wire-cyan hover:glow-cyan hover:underline`; feed tweet/tx links: `text-wire-border hover:text-wire-cyan`.

## Responsive (Tailwind default breakpoints: sm 640 / md 768 / lg 1024)
- Nav: center link group `hidden lg:flex`; grid `grid-cols-2 lg:grid-cols-3`.
- Hero: ASCII status box `hidden md:block`; ASCII logo `text-[10px] md:text-[14px] lg:text-[18px]`; tagline `text-base md:text-lg`; paragraph `text-xs md:text-sm`.
- About h2: `text-2xl md:text-3xl`; card grids `grid-cols-1 md:grid-cols-3` (about, security) and `md:grid-cols-2` (guide, commands).
- Guide footer row: `flex-col md:flex-row`.
- Feed: stats `hidden md:inline`; row tweet/tx links `hidden sm:inline`; text `text-xs md:text-sm`.
- Footer: `flex-col md:flex-row`.
- No scroll-reveal animations on sections (`.reveal` class exists in CSS but is used 0 times).
