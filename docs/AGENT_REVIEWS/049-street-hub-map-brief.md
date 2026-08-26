# 049 — Hub map door: step, pack promise, two verbs

Reviewed: 2026-08-26
Slice: street hub MAPA tile was a pill with “Rois” and a text link; now a briefing with step, pack lede, **Ouvrir la carte** + **Continuer**
Tests: `bin/rails test` (see session)
Gate: street pack — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — pack `lede` in libre.yml + quizzes.{en,fr,pt-BR}; `street.pack_step` / `pack_here` in four locales
UI: `.cursor/skills/noche-ui/SKILL.md` — navy open, gold play; dock gold Continuer stays pinned

## Four seats

N/A (street). Hub job: know which etapa, what you’ll be asked, open the map or play.

## Tension

N/A.

## Finale

N/A.

## Languages

noche-i18n: **PASS**
- es — Etapa 1 · David, Saúl y Salomón… tú path, no exam paper.
- pt-BR — Etapa 1 · Davi, Saul, Salomão… você.
- fr — Étape 1 · David, Saül, Salomon… tu (not *allez-vous*).
- en — Step 1 · David, Saul, Solomon… family, not CMS.

## Verdict

PASS WITH NOTES

## What works

- The tile is no longer a whole-card link. Two real buttons: navy **Abrir el mapa**, gold **Jugar / Seguir jugando**.
- Title is the pack name at `--type-ui`. Lede says what the pack tests, without spoiling answers.
- Open run names the question: Etapa 1 · pregunta 4 de 10.
- Dock gold Continuer stays for the thumb (046). Same job as the card gold, not a second gold défi.

## What feels weak

- Two gold Continuer (card + dock). Same verb twice so the briefing can sit next to play without losing the pinned bar.

## Required before approval

- None.

## Evidence

UI: briefing tile + dock gold. Copy: tú / você / tu / you.

## Night director

Would I know what Rois is testing before I tap? Yes. Friday four-seat? No — street.
