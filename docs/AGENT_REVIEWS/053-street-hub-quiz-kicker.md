# 053 — Hub pack tile: Quizz royal + Continuer

Reviewed: 2026-08-26
Slice: MAPA kicker became the pack’s quiz name (FR **Quizz royal**); ink verb is Continuer / Jugar, not Ouvrir la carte. Map stays in the hamburger.
Tests: `bin/rails test` (see session)
Gate: street pack — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — pack `kicker` in libre.yml + quizzes.{en,fr,pt-BR}
UI: `.cursor/skills/noche-ui/SKILL.md` — ink verb; gold Continuer stays the dock

## Four seats

N/A (street). Hub job: know which quiz, tap Continuer, play.

## Tension

N/A.

## Finale

N/A.

## Languages

noche-i18n: **PASS**
- es — Quiz real (Reyes, tú)
- pt-BR — Quiz real (Reis, você)
- fr — Quizz royal (the magazine spelling they asked for; tu)
- en — Royal quiz (family, not CMS)

## Verdict

PASS WITH NOTES

## What works

- Kicker names the quiz, not the journey map. Continuer on an open run goes to `/jugar`. Jouer starts the pack. Map is still Abrir el mapa in Más.

## What feels weak

- Dock and tile can both say Continuer. Same verb, ink vs gold metal — the dock is still the thumb hit.

## Required before approval

- None.

## Evidence

UI: ink Continuer. Copy: tú / você / tu / you.

## Night director

Would I know I’m in the kings quiz and tap Continuer? Yes. Friday four-seat? No — street.
