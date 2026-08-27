# M84 — Liga avec HUD et dock partagés

Reviewed: 2026-08-27
Slice: `/liga` — continuité de navigation avec le hub
Tests: 21 runs, 249 assertions, 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md`

## Feeling

Continuité : le joueur conserve son identité, sa progression et ses portes de sortie pendant qu’il compare les scores.

## Experience → UI → Art → Theme

- Experience: le classement n’est plus une impasse ; Accueil, Aventure, Live, Église et Profil restent accessibles.
- UI: le composant HUD partagé est fixé au-dessus du titre ; le dock partagé est fixé en bas ; « Ta position » se place au-dessus du dock.
- Art: le chrome Celestial Light reste cohérent avec la cour du classement.
- Theme: aucune duplication de skin ou de tokens ; HUD et dock consomment les composants sémantiques existants.

## Scores (/10)

Fun 8 · Clarté 10 · Impact visuel 9 · Feedback 9 · Progression 9 · Social 9 · Immersion 9 · Accessibilité 9 · Cohérence Noche Live 10 · Envie de continuer 9

## Verdict

PASS

