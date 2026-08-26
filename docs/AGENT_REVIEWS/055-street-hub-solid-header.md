# 055 — Hub header is a solid cream section

Reviewed: 2026-08-26
Slice: street hub chrome — lockup was a translucent overlay; the ficha faded into it. Header is now an ivory slab above the feed.
Tests: `bin/rails test test/controllers/street_hub_controller_test.rb` (see session)
Gate: street pack — `.cursor/skills/noche-night/SKILL.md`
Copy: N/A
UI: `.cursor/skills/noche-ui/SKILL.md` — ink lockup, gold stays Jugar; cream head like jugar, no vaulted phone-arch on the hall

## Four seats

N/A (street). Hub job: read the tiles. The header is a bar, not atmosphere.

## Tension

N/A.

## Finale

N/A.

## Languages

N/A.

## Verdict

PASS

## What works

- `.street-hub-brand` is a full chrome-head ivory slab (`z-index: 12`, gold hairline). No oculus rings, no hall, no ficha in that bar.
- Feed no longer masks the first card into the lockup. Continuer stays pinned.

## What feels weak

- Avatar and hamburger stay `position: fixed` discs on the bar (same chrome as jugar). They are not inside the `<header>` markup.

## Required before approval

- None.

## Evidence

UI: solid cream head on hub and `/mapa`. Copy unchanged.

## Night director

Would I still see Noche Live as the roof of the hall? Yes. Friday four-seat? No — street.
