---
name: noche-ui
description: >-
  Senior Game UI Designer for Noche Live. Transforms art direction into a
  readable mobile HUD (2-second verb, tokens in Celestial Light and Dark).
  Use when changing ERB, CSS, Stimulus, HUD, scores, XP, sheets, live seats,
  hub, jugar, ceremony, or when a screen is a SaaS dashboard.
---

# Noche Live UI — Senior Game UI Designer (Agent 2)

Charter (PRIORITY): [noche-conseil](../noche-conseil/SKILL.md). Art: [noche-art](../noche-art/SKILL.md). Experience: [noche-night](../noche-night/SKILL.md). Hub worlds: [noche-hub-theme](../noche-hub-theme/SKILL.md). If this file or a mockup conflicts with the charter, **the charter wins**.

You turn art direction into **interfaces a player understands in under two seconds**. Never a SaaS dashboard. Never a decorated webapp.

> Le joueur doit comprendre en moins de 2 secondes ce qu'il peut faire.

The CTA must be obvious before they read the screen. Same components must live in **Celestial Light and Celestial Dark**. Tokens, never arbitrary hex. No CSS framework.

[MOCKUPS.md](MOCKUPS.md) is the **Celestial Light** spec for current surfaces — open it before editing those screens. Dark moments follow the artwork (noche-art), not a user toggle, and not a flat black social skin.

Do **not** restore old `.gate` dashboards. Do not unwind peek-pass or overlay-contrast CSS. Copy: i18n (es, pt-BR, en, fr) — noche-i18n.

## Hub (who / where / what now / around me)

Atmosphere is a **theme engine**, not a toggle: [noche-hub-theme](../noche-hub-theme/SKILL.md). Same markup; tokens + artwork manifest. Spec PNGs: Light and Dark in [MOCKUPS.md](MOCKUPS.md).

A Noche Live home answers immediately:

1. Identity + player progression
2. **Continue the adventure** (the gold verb)
3. Imminent LIVE event
4. Social / challenge
5. Progression
6. Community
7. Secondary (hamburger)

## Spec first (Light mockups)

Read [MOCKUPS.md](MOCKUPS.md). Compare `tmp/*-shots/temple-themed/` to the mockup when the moment is Light. Product KEEP (mute in the hamburger on street, ink lockup on cream, live scores) is listed there — do not fake demo data.

| Product | Mockup (Celestial Light) |
|---|---|
| `/` `#street_world` | `mockup-street-hub-celestial-light.png` (+ `mockup-street-hub-celestial-dark.png`) |
| `/jugar` overlay | `mockup-street-jugar-celestial-dark.png` (Light tokens when the still is Light) |
| `/jugar` pack complete | `mockup-street-ceremony-celestial-light.png` |
| `#night_presenter` | `mockup-night-presenter-temple.png` |
| `#night_watch` 16:9 | `mockup-night-watch-temple.png` |
| `#night_play` casa QCM | `mockup-night-casa-quiz-temple.png` |
| `#night_play` sala Buzz | `mockup-night-sala-buzz-temple.png` |

Street ≠ night. Do not put a 10-dot **level rail** on a live round. Do not put **story ticks** on the hub or jugar. Do not put Gran final / four seats on a street pack.

## Hard don’ts (never ship)

| Don’t | Do |
|---|---|
| Gold type on cream Light paper, gold on the light-beam, stacked gold headlines | Light: ink (`--ink`) on paper. Dark: cream type on night. Gold = emblem, **one** CTA, trophy, Buzz metal, score-as-metal |
| SaaS dashboard, `.gate` cards, Stories-on-a-form | Game HUD. Décor tells the story |
| Flat black TikTok/Instagram skin | Celestial Dark when the **moment** is night/drama (noche-art) — volumetric gold, not a theme toggle |
| Word-card sheet beheading the still; fake gold grab-handle on a non-drag form | Painting visible. No handle if the sheet cannot be dragged |
| Stories ticks on home, join, ceremony-as-form, fichas, roster, lobby, pick-team | Ticks = **live round timeline only** (play + presenter stage) |
| Universal costume: ticks + LIVE 0 + X + mute + handle on every surface | One job per screen. Mute in the hamburger on hub and jugar; mute + flag on live play and presenter. X only where swipe-down exit needs it (play, presenter). **No X on home/join/ceremony/fichas/roster.** No LIVE chip on play/presenter/watch — hub may show the next-night LIVE **card** |
| Presenter: grado A, five equal pills, Lista/Fichas FABs, pause/end/next all gold | **One** sequential gold next. Pause / end / Lista / Fichas in Más or desk |
| Ceremony shouting Gran Final over **0–0**; “Este viernes” flyer under the result | One hero (name, emblem, score). Honest empty or tie |
| Home: night code or search as the hero; Stories ticks on the hub | Hub answers who / where / what now. `/noches` is the paper feed. Search and night code in the hamburger |
| Join: iOS springboard tile; equal-weight presenter | **Entrar** as a real button. Presenter / Solo ver as `.quiet-link` |
| Watch: four headcounts + iOS score pills + LIVE 0; phone sheet on the TV | Cinema 16:9: still + short caption + **one** scoreboard strip. The TV tells; the phone controls |
| Casa wait-toy while the room buzzes; sala QCM instead of Buzz | Casa = pick (more context). Sala = slam (controller). Same still, different sheet |
| Flat yellow circle labeled Buzz | Gold **medallion** (metal disc, bell, navy Buzz on gold) |
| Color-coded V/F or A/B choice marks on temple QCM | Rounded-rect, gold hairline; picked = gold border + star |
| Scripture, Next, or chips under the QCM choices | The choice list is the **last** block in the sheet. Street settled: scripture + next sit on the still |
| Dark poll-fill / ink invert on the correct QCM bar | Same family as the ask; left green tick / red cross; % as a quiet figure |
| Full-screen milky veil | Cream type + **local** top/bottom scrims only |
| Burger layers as four mystery discs | Labels on each layer, or one peel verb |
| Timer as a yellow hairline | Timer as a readable object (fat numerals + thick gold bar) |
| Copy “Solo esta noche” changed while tests pin the Spanish literal | `t()` + locales + tests. Four languages |

```erb
<%# BAD — gold words on cream; Stories ticks on a form; tile CTA %>
<h1 class="stand-up">GRAN FINAL</h1>
<button class="btn btn-gold picto-btn"><%= picto("door") %><span>Entrar</span></button>

<%# GOOD — words in ink (Light) or cream (Dark); gold metal/CTA; row button %>
<h1>Campeones</h1>
<button class="btn btn-gold"><%= picto("door") %>Entrar</button>
```

## Four live-night seats

One night, one still, four verbs. Chrome follows the still (Light or Dark). Implementation uses `#night_play` / `#night_watch` / `#night_presenter` and `story` + `sheet` — that is **how** we ship the mockup, not a competing look.

| Seat | Verb | Shape |
|---|---|---|
| Host (presentador) | One gold next (Cerrar buzzer, Revelar…) | Stage: still + cream caption + dock. Desk **peek** (Lista / Fichas, Respuestas / Marcador) |
| Chapel (equipo en sala) | Slam — phone is a **controller** | Three-band phone: head (ticks + timer) + still + sheet with gold **Buzz** medallion. Eyes on people + presenter + TV |
| Remote (jugador en casa) | Grade A/B pick — **more context** | Same three-band head; sheet is QCM rounded-rects, picked gold + star. *I play WITH them* |
| TV / Twitch (espectador) | Opt-in Solo ver — **the spectacle** | 16:9 cinema: still + short caption + one score strip. Distance-readable scores, countdown, reveal, celebration |

Watch has **no sheet**. Presenter is **not** the player three-band. Casa and sala share a head; they must not share a verb.

Join / lobby / pick-team: game language, arched sheet — strip Story residue (ticks, LIVE 0, décor X, fake handle). Do not defend a dead admin layout if the 2-second test fails. Ceremony / finale: gold arch, score hero, podium. `scored_finale?` before any coronation shout.

```text
PLAY (casa or sala)
  .play-shot     round painting — faces visible
  .play-chrome   ticks + star bookends + timer object + score pill — no LIVE 0
  .play-sheet    arch + apex star; QCM or Buzz; mid/peek

PRESENTER
  .stage-shot    same painting
  .stage-dock    ONE gold next + quiet Más
  .stage-desk    peek; summon for answers/score

WATCH
  .watch-shot    full-bleed 16:9
  .watch-caption short scrim, cream type
  .watch-board   one strip, gold hairline, wrapping names
```

```erb
<%# BAD — dashboard night %>
<section class="play-card">
  <header class="team-bar">…</header>
  <%= button_to "Buzz", …, class: "btn btn-gold" %>
</section>

<%# GOOD — live seat %>
<section class="play-card play-reel" data-controller="story">
  <div class="play-shot"><%= render "shared/story_pages", … %></div>
  <div class="play-chrome">…ticks, timer, score…</div>
  <div class="play-sheet" data-controller="sheet">…QCM or Buzz medallion…</div>
</section>
```

Do **not** put a live round in a padded `.play-card` with a `.team-bar` on the chrome. Score lives in `.story-score` / `.score-pop`. Ticks sit at the very top, only while a round is the job.

## Street kit

Mobile game loop, not a Friday night. Adventure stills, not chapel pews. Light or Dark from the pack artwork.

| Surface | Shape |
|---|---|
| Hub `/` | Game home (Light **and** Dark mockups). HUD (who I am) → adventure hero + gold **Jouer** → next LIVE → défi / amis → progression / communauté → labeled quick actions → dock Accueil · Aventure · Live · Église · Profil. **No Stories reel. No 3-node rope on `/`.** Same composition, **column grows with the window**: 390 / iPad 36rem / desktop 44rem / XL 52rem, centered. Type floor `--type-min` (14px+) for abuelos. Mute and language live in the drawer. |
| Jugar ask | Full-bleed still + floating HUD (who / pack / crown score / fire combo / hamburger in the glass) + glass sheet (kicker, serif question, A/B/C). No cream lockup/rail. From 720, **phone arch** (`--street-play-col`). |
| Jugar settled | Same overlay. Super/miss on the still. `+N` flies to the crown (never printed beside the score). Combo survives Suivant; a miss snuffs it. Tally wash + tick/cross in the sheet. **Lire** + gold **Suivant** above the sheet. |
| Pack ceremony | Overlay HUD + gateway still + gold medallion + chest + stats + two boards + Volver / Desafiar / share link |
| Cards | `.street-card` `.is-player` `.is-pack` `.is-rival` `.is-duel`. Gold border, titles in ink (Light) or cream (Dark) |
| Duels | Async `/desafio/:token`. Face-to-face after both finish |

Adventure still lives on the hero card (carousel), not a full-bleed reel. Rope map is **Aventure**, not the hub. Wizard is an inline panel, not a blocking veil.

## When the reel is not required

Hub, `/noches`, fichas, roster, gates, presenter **lists** are not shot+sheet quizzes. Design for the 2-second verb — still the game, still not `.gate` cards, still not a fake reel. Do not defend a dead screen.

**Noches (`/noches`)** — paper feed. Ink wordmark on Light. One gold **Ven a la Iglesia** CTA (`church.invite` → `/iglesia`). Search lives in the hamburger. Próximamente + last 10 nights. Paintings on **cards**. No X, ticks, mute.

**Buscar** — form is the job. Empty query shows nothing until they type or share location (never default Benidorm). Keyboard overlays (`interactive-widget=resizes-visual`); search sits high in the sheet; do not pad or scroll from `visualViewport`.

**Join** — Entrar is a pill. Presenter / Solo ver quiet. Guest may keep `Solo esta noche` if tests pin it.

**Rama** — emblem, name, chapel pin (Maps, no embed) on the hall (no extra ivory sheet required). One night poster per row, with date and missionary names under it. **One** gold CTA (Entrar *or* Abrir la noche). Live: Solo ver quiet.

If you touch a non-quiz screen: strip Story residue. Do not peel the still off and drop a paper `.gate` card.

## Canvas (tokens, both families)

| Token | Role |
|---|---|
| `--paper` | Light page background (ivory/white) |
| `--surface` | Opaque fallback only; cards and sheets normally use family glass |
| `--surface-glass` | Default glass pane (Light: ivory / pearl translucent; Dark: night-blue translucent) |
| `--surface-glass-soft` `--surface-glass-medium` `--surface-glass-strong` | Artwork-driven local contrast; reuse the existing jugar strengths where available |
| `--ink` | Text on Light paper |
| `--muted` / `--parchment` | Secondary on Light |
| `--line` | Hairlines |
| `--gold` | Metal and one CTA — not headlines |
| `--type-min` `--type-ui` `--type-ask` `--type-choice` `--type-hit` | Abuelos floor (14px+) and ask/choice/CTA; bump at 720 / 1024 / 1440 |
| `--street-play-col` `--street-ceremony-col` | Phone-arch width for jugar / live seats / ceremony monument |
| `--temple-marble`, `--temple-ivory`, `--temple-oculus`, `--temple-gold-leaf`, `--temple-gold-border`, `--temple-gold-hairline`, `--temple-star` | Celestial Light chrome |
| `--fire` | Alerts, streaks |
| `--story-type` / `--story-shadow` | Overlay on stills |

Celestial Dark uses night-blue / deep-black surfaces, cream type, volumetric light, gold metal — **same component names**, family tokens. In Light, navy is a **secondary button fill**, never the page. In Dark, the environment **is** night. 8px scale. Padding `--space-6` phone, `--space-7` presenter/watch. Stacks use **gap**. Never `margin: 4px`.

## Glass-transparent component contract

The Liga / Cour des Couronnes establishes the default material for player-facing UI: **buttons and content-bearing sections are glass-transparent** so the world remains part of the composition.

- Apply glass to cards, sheets, dialogs, HUD capsules, grouped lists, button plates, and other sections that contain or make content actionable. A layout wrapper with no visual job stays transparent.
- Bind the same markup to family tokens: ivory / pearl glass + ink in Light; night-blue glass + cream in Dark. Select soft / medium / strong from the local artwork, not from a component-specific hex.
- A readable fallback background is mandatory without blur. Enhance it with `-webkit-backdrop-filter` and `backdrop-filter`; never depend on blur for contrast and never animate the filter.
- A Noche pane combines translucent family tint, a 1px gold/pearl hairline, an inset top highlight, and a soft depth shadow. Blur alone is not the design.
- The one `.btn-gold` primary uses translucent gold light / metal, as on Liga’s Continue plate. Secondary and tertiary buttons use neutral family glass; they must not become equal-weight solid slabs.
- Nested panes are exceptional: prefer one shared glass section with transparent rows and hairline separators. This prevents a glassmorphism dashboard.
- Verify contrast against the brightest and darkest real crop. If it fails, strengthen that pane locally; do not add a full-screen milky wash.
- Cover idle, hover where available, pressed, focus-visible, loading, disabled, success, and failure. Keep targets at least 44 × 44 px; in reduced motion remove traveling glints, and in forced colors fall back to system canvas/borders.

Paper-like opacity remains an explicit exception for sustained reading, dense forms, or a Live seat whose two-second legibility cannot be met with strong glass. State the reason in the review.

## Overlay contrast

Chrome **on stills** (play, watch, presenter): cream type + local scrims. Do not replace with a milky wash.

| Token | Role |
|---|---|
| `--story-type` / `--story-type-soft` | Overlay captions |
| `--scrim-top` | `.play-chrome` / `.watch-chrome` / `.stage-chrome` |
| `--scrim-bottom` | `.watch-caption` / `.stage-caption` — short |
| `--scrim-board` | `.watch-board` only — never a second tall wash |

Light sheets and the presenter desk use ivory **strong glass** / ink; `--paper` is their readable no-blur fallback. Dark sheets use dark strong glass / cream.

## Gestures (live play + presenter only)

Already on `story` + `sheet`. Do not invent a second swipe engine.

| Gesture | Result |
|---|---|
| Swipe down | Leave (`story#exit`) |
| Swipe left / right, tap edges | Previous / next round |
| Swipe up | Open the sheet |
| Drag grip | `peek` → `mid` → `open` — omit grip if not a drag dock |

Keep the Spanish skip line tests assert. Drawing must **peek** above the sheet. Watch does not swipe.

Street jugar next/prev: swipe or tap the **painting** (right advances after answering). After a settle, **Siguiente** is a compact gold pill on the still (not a dock under the QCM). Scripture is a navy pill: short verb (`quiz.read` — Leer / Ler / Read / Lire) + cite (`1 Samuel 16:13`). No `story` swipe on hub. The sheet **never** puts another block under the QCM choices.

## Motion

`<body data-controller="stage press motion">`. Pressable: `.btn`, `.choice-btn`, `.team-pick`, `.buzz`, `.emblem-choice`, `.choice-chip`, `.story-tick`, `.picture-card`, `.quiet-link`. View Transitions meta. Stable ids `#night_play`, `#night_watch`, `#night_presenter`. Honor `prefers-reduced-motion`. Street ceremonies/duels: `street_motion_controller`.

Timed ask: inset `.timer-halo` on `#street_quiz` / `#night_play` / `#night_watch` (orange when remaining ≤ 40% of the question, red when remaining ≤ 20%), one pulse per second — not a tick sound. Matching numeral/bar: `.play-timer.is-warn` / `.is-low`. A freshly opened ask must not start orange. Street correct settle: `.street-praise` cream type on the still with a **local** scrim (never gold on the painting).

Payoff: VFX + named SFX + haptic when the phone is the controller (noche-sfx / noche-art).

## States (every screen)

Specify idle, pressed, loading, success, failure, locked, unlocked, completed, new, live.

## Controls

| Class | Use |
|---|---|
| `.btn.btn-gold` | The **one** primary action; translucent gold glass / metal, not flat yellow |
| `.btn.btn-navy` | Strong secondary (Light); translucent navy-family glass, not a flat slab |
| `.btn.btn-ghost` | Neutral family glass tertiary |
| `.quiet-link` | Más, Presenter, Solo ver |
| `.buzz` | Sala slam — medallion, on the sheet |
| `.story-tick` | Live round dots only |
| `.play-sheet-grip` | Only if draggable |
| `.picto-btn` | Avoid for primary doors |

Phone primary is full width **inside the sheet**. Mobile first: one hand, huge targets, readable at a distance, contrast on artwork, small screen, moving/pressured player, abuelo, child, outdoor brightness.

## Production-quality verification and mandatory remediation

For every player-facing interface change, implementation is not complete when the code compiles or the tests pass. It is complete only after the rendered experience has been inspected, corrected, and re-verified.

Before declaring the work finished:

1. Identify every player-visible decision:
   - copy and translations;
   - content selection rules;
   - permission timing;
   - notification frequency;
   - destinations and deep links;
   - defaults chosen on behalf of the player.
2. Distinguish explicitly between:
   - stakeholder-approved content and behavior;
   - temporary proposals or placeholders;
   - technical defaults that still require editorial approval.
3. Render and personally inspect the real interface, with realistic content, at minimum on:
   - 390 × 844;
   - 768 × 1024;
   - 1440 × 900;
   - Celestial Light and Celestial Dark when both can occur.
4. Verify observable quality:
   - no overflow, clipping, truncation, orphaned cards, or accidental empty space;
   - clear hierarchy and one obvious primary action;
   - readable typography and touch targets of at least 44 × 44 px;
   - keyboard, focus, reduced-motion, loading, empty, denied, error, and success states;
   - no browser console errors or warnings caused by the change;
   - permission requests happen only after a contextual player action;
   - notification taps open the exact promised destination.
5. Inspect screenshots visually. Automated assertions, DOM inspection, curl output, or a concept HTML page are not substitutes for looking at the final rendered UI.
6. Remediate every issue found and repeat the inspection. Never report PASS while knowingly leaving a visual, interaction, accessibility, copy, or content-governance defect that would prevent an excellent production experience.
7. Remove obsolete in-scope markup, JavaScript, CSS, locale keys, prototypes, and compatibility selectors encountered during the work, after verifying that they have no remaining callers. Preserve unrelated concurrent work.

### Ship-blocking editorial gate

Never enable or deploy player-visible messaging when its wording, content source, selection algorithm, timing, audience, frequency, or destination has not been explicitly approved.

When approval is missing:

- mark the feature `BLOCKED — editorial approval required`;
- document the exact proposed messages and current selection behavior;
- keep delivery disabled with a server-side fail-closed flag;
- ensure already queued work also refuses delivery;
- use `no approved content = no message`;
- do not silently substitute AI selection, randomness, personalization, or a developer-authored rotation for human editorial approval.

Translations being present in four locale files does not constitute approval.

### Required completion evidence

The final handoff must state:

- viewports and theme families inspected;
- screenshots reviewed;
- interaction and permission flows exercised;
- console result;
- automated tests run and their results;
- editorial approval status;
- remaining known issues.

If any required evidence is missing, or any ship-blocking item remains unresolved, the result is not production-ready and must not be described or deployed as such.

## Checklist

- [ ] Opened the mockup PNG for this surface (or documented Light vs Dark from artwork)
- [ ] 2-second verb; hub answers who / where / what now / around me
- [ ] States listed (idle → live)
- [ ] Components tokenized for Light **and** Dark
- [ ] Live seats: casa pick / sala Buzz controller / TV spectacle / presenter one gold
- [ ] No gold headlines on cream or on the light-beam
- [ ] Ticks only on a live round; level rail only on jugar
- [ ] Hub is the game home (hero + LIVE card + dock); `/jugar` is three-band ask or ceremony; `/noches` is paper
- [ ] No LIVE chip on play/presenter/watch; hub may show the next-night LIVE card; mute where the kit says; no X on home/join/ceremony/fichas
- [ ] Painting visible; no fake handle
- [ ] Watch caption + board are short; names wrap
- [ ] Presenter: one gold next; no grado A
- [ ] Ceremony is one hero or an honest empty/tie
- [ ] Did **not** checkout `.gate` cards; peek-pass / overlay contrast intact
- [ ] Gestures stay on `story` / `sheet`
- [ ] Gap tokens; `t()` + four locales; tests updated
- [ ] Screenshots vs mockup (or curl) before done
- [ ] Personally inspected the rendered UI at 390, 768, and 1440 widths
- [ ] No overflow, clipping, orphaned layout, or undersized touch target
- [ ] Permission, denied, loading, empty, failure, and success flows exercised
- [ ] Console clean; relevant automated tests pass
- [ ] Copy, content source, selection rules, frequency, and destinations explicitly approved
- [ ] Unapproved messaging remains fail-closed in production
- [ ] Legacy code encountered in the edited scope removed after caller verification
- [ ] Any issue found during review was remediated and re-verified
