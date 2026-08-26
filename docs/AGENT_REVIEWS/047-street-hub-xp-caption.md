# 047 — Hub player card: remaining to rank, not numbers on gold

Reviewed: 2026-08-26
Slice: street hub player card — XP `40 / 60` sat on the gold fill and could not be read
Tests: `bin/rails test` (see session)
Gate: street pack — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — `street.card_xp_left` / `street.card_xp_max` in es, pt-BR, en, fr
UI: `.cursor/skills/noche-ui/SKILL.md` — ink for words, gold for the metal rail only

## Four seats

N/A (street, one phone). Hub job: know where you stand, play.

## Tension

N/A.

## Finale

N/A.

## Languages

noche-i18n: **PASS**
- es — Faltan 20 para Guerrero (tú path, destination not a HUD fraction)
- pt-BR — Faltam 20 para Guerreiro (Brazilian, você)
- fr — Encore 20 pour Guerrier (tu, thin-space-free)
- en — 20 more to Warrior (family, not CMS)

## Verdict

PASS WITH NOTES

## What works

- The gold rail is metal only. Caption sits under it in ink at `--type-min`.
- Copy names the next rank and how many points remain, so 40/60 is a path not a fraction on leaf.
- Rank banner uses `rank_name`, so Explorateur / Guerreiro follow the locale.

## What feels weak

- Mockup still drew `7,850 / 10,000` above a thin bar. Type on gold failed in product; remaining-to-rank is the read.

## Required before approval

- None.

## Evidence

UI: gold fill, ink caption. Copy: tú / você / tu / you.

## Night director

Would I know how far to the next title without squinting at the bar? Yes. Friday four-seat? No — street.
