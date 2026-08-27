# M097 — Jugar motion polish

Reviewed: 2026-08-28
Slice: `/jugar`, réponse puis passage à la question suivante
Tests: browser QA on the live local app; Rails suite reached pre-existing profile/run fixture failures unrelated to this slice
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: N/A

## Feeling

Impact puis continuité : le choix doit sembler toucher le monde avant que le résultat arrive, et Suivant doit tourner la page sans casser la scène.

## 1 — Game experience

La réponse garde maintenant un battement tactile de 140 ms : le choix se serre et les autres s'effacent avant la révélation. Suivant ferme la feuille et les actions en 160 ms, puis laisse le fondu existant changer le tableau. Le HUD, le score et la série restent visuellement stables.

## 2 — UI design

Les états `is-committing` et `is-advancing` rendent explicites les deux charnières de la boucle. Ils verrouillent les doubles actions via l'état existant, restent sous le seuil de latence perceptible et sont neutralisés avec `prefers-reduced-motion`.

## 3 — Art direction

Le mouvement reste local aux objets qui changent : choix, feuille, actions et peinture. Aucun zoom de caméra, voile global ou animation décorative permanente n'a été ajouté. L'or ne sert qu'à signer le choix et la récompense.

## Theme engine

N/A — les familles Celestial Light/Dark existantes sont conservées.

## Four seats

N/A street — un joueur, un choix, un résultat, une envie suivante.

## Tension

Le micro-silence avant révélation donne du poids au choix sans ralentir le quiz. La sortie courte de Suivant évite le cut technique.

## Finale

La cérémonie existante reste inchangée.

## Languages

N/A — aucune copie modifiée.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.6 |
| Clarté | 9.0 |
| Impact visuel | 8.8 |
| Feedback | 9.2 |
| Progression | 8.8 |
| Social | 8.0 |
| Immersion | 9.0 |
| Accessibilité | 9.0 |
| Cohérence NocheLive | 9.1 |
| Envie de continuer | 9.0 |

## Verdict

PASS

## What works

- La réponse est ressentie avant d'être remplacée par les résultats.
- La peinture change tandis que le HUD demeure une ancre stable.
- Aucun délai n'est imposé en mouvement réduit.

## What feels weak

- Le fondu natif de View Transitions peut durer davantage lors d'une capture outillée que dans l'interaction directe, mais la scène se stabilise correctement et sans erreur console.

## Required before approval

- None.

## Evidence

Boucle jouée sur `http://localhost:3091/jugar` : réponse correcte, résultats, Suivant, nouvelle question ; aucune erreur ou alerte console.

## Night director

Oui. Le choix a un impact, la révélation paie immédiatement et le prochain tableau arrive comme une continuité.
