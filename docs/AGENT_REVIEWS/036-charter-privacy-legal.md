# 036 — Carta gabarit for privacy and legal

Reviewed: 2026-08-26
Slice: `/privacidad` and `/legal` on a new hall reading sheet (Carta). Copy matches what the app actually stores. Spanish LSSI / RGPD / LOPDGDD shape, not chapel slogans on the marble.
Tests: `bin/rails test test/controllers/pages_controller_test.rb test/i18n/locale_files_test.rb test/integration/ui_chrome_test.rb`
Gate: `.cursor/skills/noche-ui/SKILL.md` — leftover family, not a quiz reel
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr

## Four seats

N/A. Paper hall reading, not a live night.

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage |
| Equipo en sala | Unchanged Buzz |
| Jugador en casa | Unchanged remote A/B |
| Espectador | Unchanged *Solo ver* |

## Tension

N/A.

## Finale

Unchanged.

## Languages

noche-i18n: **PASS**
- es: tú, ficha / rama, DNI named as what we do *not* ask; AEPD named
- pt-BR: você, ala, RG; no ficheiro / ecrã
- fr: tu for one phone, paroisse; thin space; *saisir l’Agence*
- en: ward, play name, favourite year — not *please select your unit*

## Verdict

PASS WITH NOTES

## What works

- Ivory `.charter-sheet` so ink sits on paper, not on the oculus.
- Cookie table is first-party names and durations from `Identity`.
- Copy refuses the lie “no personal data”; says no civil ID and no third-party cookies.

## What feels weak

- Google Fonts still phones home; the policy says so. Self-hosting would make the third-party sentence shorter.
- No mockup PNG for Carta — invented in the leftover-hall family.

## Required before approval

- None for this tick. Lawyer eyes on the US transfer line if the site goes fully public in Spain.

## Night director

Would I play another round? Yes — the legal page is no longer unreadable grey on the windows.
