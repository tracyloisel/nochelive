# 043 — Hub tiles: défi visible, map on `/mapa`

Reviewed: 2026-08-26
Slice: street hub duel card was clipping its share/map CTA under the player card; the rope map ate the first fold
Tests: `bin/rails test` (see session)
Gate: street pack (not live-night seats) — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — `world_map_open` / `world_map_close` in es, pt-BR, en, fr
UI: `.cursor/skills/noche-ui/SKILL.md` — hub stays marble hall + tiles; rope lives on `/mapa`; no 5-tab dock

## Four seats

N/A (street, one phone). Hub job: see the défi, play, open the map. Map job: scroll the rope.

## Tension

N/A.

## Finale

Ceremony **Volver al mapa** now lands on `/mapa` (unlock animation stays on the rope).

## Languages

noche-i18n: **PASS**
- **es** — Abrir / Cerrar el mapa. tú.
- **pt-BR** — Abrir / Fechar o mapa. você, mapa da jornada already on the tile.
- **fr** — Ouvrir / Fermer la carte (carte du voyage). tu.
- **en** — Open / Close the map.

## Verdict

PASS WITH NOTES

## What works

- Hub is no longer a locked `100dvh` flex that hid the duel foot under the player card. The défi card keeps **Compartir** (ghost) and **Abrir el mapa** (quiet) inside the card. Gold on the hub stays **Jugar**.
- Rope map moved to `/mapa`. Hub shows a MAPA DE VIAJE tile. Close is a quiet link, not an X. The rope still scrolls inside the map page.

## What feels weak

- The mockup still drew the 3-node rope on the hub. Product chose tiles so a finished défi can breathe. Recapture hub-phone vs that PNG will disagree on purpose.
- Still no OS push when the friend finishes.

## Required before approval

- None.

## Evidence

UI: hub tiles + `/mapa` inner scroll. Copy: tú / você / tu / you.

## Night director

Would I see who won and still find the map? Yes. Would I ship this as a Friday four-seat round? No — street.
