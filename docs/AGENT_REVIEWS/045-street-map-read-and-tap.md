# 045 — Map page: readable rope, tap to resume

Reviewed: 2026-08-26
Slice: `/mapa` clipped pack titles and the current ivory card; tapping a node did nothing except on finished packs
Tests: `bin/rails test` (see session)
Gate: street pack (not live-night seats) — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — `pack_ordinal` in es, pt-BR, en, fr
UI: `.cursor/skills/noche-ui/SKILL.md` — dedicated map keeps the hub rope; ink titles; one gold Continuer

## Four seats

N/A (street, one phone). Map job: read every pack name, tap a playable step, resume or replay that pack.

## Tension

N/A.

## Finale

N/A. Ceremony **Volver al mapa** still lands on `/mapa`.

## Languages

noche-i18n: **PASS**
- **es** — Pack %{n}. tú. Coronas stays ink on the current card.
- **pt-BR** — Pack %{n}. você.
- **fr** — Pack %{n}. tu.
- **en** — Pack %{n}. you.

## Verdict

PASS WITH NOTES

## What works

- Rope sits left (~32%) so the name column can wrap at `--type-ui`. Kicker and title are two lines, not `Pack n — title` with nowrap.
- Path is a 3px gold thread that curves through occasional left/right sways, not a braided brown pole or a straight spine.
- Each pack is one ivory plaque: the still sits in the left of the chip so title and picture read as one. Locked packs wear a gold lock seal, not a black glyph.
- Playable nodes POST `StartPack` (resume open run, fresh run if finished). Locked stays inert. `/jugar` pins the tapped run in session so a later pack still open is not stolen by id order.
- Gold on the map stays the dock Continuer. COURONNE is ink.

## What feels weak

- Hub mockup still drew the 3-node rope on `/`. Product map is the full catalog on `/mapa`.
- Two open runs after a replay is an edge; the pin is the honest fix, not closing the other pack.

## Required before approval

- None.

## Evidence

UI: left rope, wrapping titles, tap-to-play. Copy: tú / você / tu / you.

## Night director

Would I read Pack 4 and still tap Pack 1 to play it again? Yes. Friday four-seat? No — street.
