# 044 — Hub tiles: one rhythm, one gold

Reviewed: 2026-08-26
Slice: street hub tiles (défi, ficha, map door, liga) were different heights; gold **Jouer le défi** fought **Continuer**; map lede was tiny wrap
Tests: `bin/rails test` (see session)
Gate: street pack (not live-night seats) — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — no new keys; verbs already in es / pt-BR / en / fr
UI: `.cursor/skills/noche-ui/SKILL.md` — hub tiles share padding + `--type-min`; gold stays the dock Jugar

## Four seats

N/A (street, one phone). Hub job: read the défi, open the map, play. Same type on every tile.

## Tension

N/A.

## Finale

N/A.

## Languages

noche-i18n: **PASS** (no new copy). Hub verbs stay Abrir el mapa / Jugar el desafío / Aceptar at the same ink weight as the map door.

## Verdict

PASS WITH NOTES

## What works

- Défi, map door, player, liga share `--space-2` / `--space-3` padding and `--type-min` titles.
- Incoming défi is a row tile (faces + one line + ink verb). Gold on the hub is only **Jugar / Continuar**.
- Map door drops the wrapping lede; pack title is the body. Close still lives on `/mapa`.

## What feels weak

- Compact result still uses a VS pair, so it is a little taller than the map door. Scores are the story.
- Mockup still drew the 3-node rope on the hub (see 043).

## Required before approval

- None.

## Evidence

UI: hub row tiles + dock gold. Copy: tú / você / tu / you.

## Night director

Would I know the next tap without a second gold shouting over Continuer? Yes. Friday four-seat? No — street.
