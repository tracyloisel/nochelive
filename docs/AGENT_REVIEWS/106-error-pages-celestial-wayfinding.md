# M106 — Celestial wayfinding error pages

Reviewed: 2026-08-28
Slice: static 400 / 404 / 406 / 422 / 500 recovery screens
Tests: `bin/rails test test/integration/error_pages_test.rb` — 2 runs, 124 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr present and browser-validated

## Feeling

Reassurance, wonder, and the sense that the adventure is still close. A failure becomes a gentle detour rather than a dead end.

## 1 — Game experience

Loop: interruption → immediate recognition of the error family → one recovery action → return or retry → adventure resumes. The primary action is always visible and there are no diagnostic details or administrative decisions for the player.

## 2 — UI design

The 2-second verb is return for 4xx and retry for 500/406. Targets are 56 px high on mobile. The files are autonomous from Rails, keep a Spanish no-JavaScript fallback, detect the browser language, and offer an explicit four-language picker. The same composition supports Celestial Light and Celestial Dark through semantic page-family tokens.

States: idle, hover, focus-visible, pressed, localized, image-fallback, reduced-motion. Loading stays readable because the content and background do not depend on the illustration.

## 3 — Art direction

The 4xx family uses a hopeful luminous path that fades into cloud before the nearest portal. The 5xx family uses a night observatory whose astrolabe star is rekindling. Gold stays on the path, emblem, mechanism, and one CTA; titles remain ink on ivory or cream on night. The generated WebP illustrations are 96 KB and 140 KB.

## Theme engine

N/A — static recovery pages, not the hub.

## Four seats

N/A — these pages recover any seat without introducing a live-night interaction.

## Tension

N/A. The interruption is intentionally resolved without suspense; the next useful gesture is immediate.

## Finale

N/A.

## Languages

Copy is present in es, pt-BR, en, and fr. Browser checks confirmed French selection on every page and an English switch updates the document language, title, heading, and selected state.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 10 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 10 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Every error has one obvious recovery verb and keeps the adventure metaphor alive.
- Light and Dark feel authored from their illustrations, not recolored after the fact.
- Static CSS, JavaScript, icons, and optimized artwork remain available when Rails is unavailable.

## What feels weak

- The browser-language detection cannot read the HttpOnly locale cookie, so the explicit picker remains important when browser and player preferences differ.

## Required before approval

- None.

## Evidence

- 390 × 844: all five pages load their artwork, keep 56 px primary targets, and have no horizontal overflow.
- 1440 × 900: both visual families fit without scrolling.
- No browser console errors or warnings.

## Night director

Yes. Even after an interruption, the player sees a warm, immediate way back instead of a technical dead end.
