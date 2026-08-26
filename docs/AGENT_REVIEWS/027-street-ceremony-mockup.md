# 027 — Street pack ceremony vs mockup

Reviewed: 2026-08-26
Slice: rebuild `/jugar` pack-complete as a trophy **in the hall** to match `tmp/street-shots/temple-mockups/mockup-street-ceremony-temple-victory.png`
Tests: `bin/rails test test/controllers/quiz_answers_controller_test.rb test/system/street_quiz_visual_test.rb`
Gate: mockup (validated). Stacked iOS cards retired — monument is `.street-ceremony-monument` (trophy stele + plinth).
Copy: existing keys only (Mejores / Tu rama). No fake wards.

## Four seats

N/A — street pack, not a live night.

## Tension

N/A.

## Finale

Street pack complete only. Night play/watch/presenter ceremony untouched (`--temple-hall-scrim` + `shared/_ceremony`).

## Languages

noche-i18n: PASS — no new strings. es Mejores / Tu rama; pt-BR Melhores / Sua ala; fr Meilleurs / Ta paroisse; en Top / Your ward.

## Gap closed

| Mockup | Now |
|---|---|
| Hall is the scene | `--temple-ceremony-hall-bg` (`marble-hall-victory.jpg`) + god-ray overlay |
| Monument, not two cards | `.street-ceremony-monument` = narrower `.street-ceremony-trophy` on a full-width marble `.street-ceremony-plinth` |
| Double gold arch | Stele `box-shadow` double gold stroke; square join to plinth |
| 3 stars on the crown | Absolute arc on the trophy, center larger |
| Brush title + score | Kalam; visual tests `fonts.load` |
| Chest wood + starburst | `ceremony-chest.png` + `.street-ceremony-starburst`; laurels as multiply gold-leaf |
| Plinth + CTAs on-fold | Hex medals, people names; pointed gold Volver + gold-outline Desafiar |
| Bee lockup | Ink Noche / Live / Quiz callejero |

Left column uses **people** in the rama, not invented wards. Ceremony chest cannot use class `.chest`.

## Verdict

PASS WITH NOTES — first fold is a stele-on-plinth in the hall (not a card stack). Night ceremony not restyled.

## Evidence

`tmp/street-shots/temple-themed/ceremony-phone.png`, `ceremony-challenge-phone.png`, `jugar-ceremony-desktop.png`.
Mockup: `tmp/street-shots/temple-mockups/mockup-street-ceremony-temple-victory.png`.
