# M105 — Vidéothèque officielle Celestial Sanctuary

Reviewed: 2026-08-28
Slice: de la tuile du hub à une vidéo regardée sans quitter Noche Live
Tests: ciblés Rails + i18n — verts ; système Chrome — vert ; suite complète — couverture 93,16 %, avec 28 échecs et 23 erreurs préexistants hors de ce slice
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validés par le test de parité

## Feeling

Curiosité calme, confiance et sentiment d’être en famille. La tuile ressemble à une fenêtre lumineuse dans le monde du hub ; la page devient un petit sanctuaire de cinéma, pas un clone de YouTube.

## 1 — Game experience

Boucle : apercevoir l’œuvre → entrer dans la vidéothèque → choisir une histoire → comprendre la connexion tierce → ouvrir le lecteur → regarder → fermer → vouloir découvrir la suivante. Le visionnage ne donne aucun point et ne détourne pas la progression du jeu.

## 2 — UI design

Verbe en deux secondes : « regarder ». La home ne fait aucun appel à YouTube. Le répertoire porte les états complet, vide, indisponible, page précédente/suivante, consentement et lecteur. Les cartes sont de vrais boutons, le dialogue est natif, Échap fonctionne et le focus revient à la carte. Mobile et desktop sont couverts par captures Chrome.

## 3 — Art direction

Illustration originale : livre ouvert, ruban de lumière cinématographique, familles, service et horizon de temple. Aucun texte, logo ou visage réel. La médiathèque tire son Celestial Dark du manifeste `config/media/church_youtube.yml`; la tuile reste compatible avec les tokens Light/Dark du hub.

## Theme engine

Même hub, même grille, aucun sélecteur de thème. La tuile est une porte secondaire après les boucles sociales et de progression. La destination utilise `mode: dark`, `atmosphere: sanctuary`, `accent: gold` parce que l’œuvre est nocturne.

## Four seats

N/A pour une nuit live. En street, le téléphone choisit et contrôle ; une famille peut regarder ensemble sur son écran sans gagner d’avantage de jeu.

## Tension

N/A. C’est volontairement un sas calme entre deux boucles de jeu. La tension vient seulement de la promesse visuelle et du choix de la prochaine histoire.

## Finale

N/A. Aucun effet sur les manches, les points, les rangs ou la couronne.

## Languages

Copy lue en espagnol, portugais brésilien, anglais et français. La chaîne officielle est sélectionnée par locale et la parité des clés est verte.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.0 |
| Clarté | 9.2 |
| Impact visuel | 9.4 |
| Feedback | 8.7 |
| Progression | 8.0 |
| Social | 8.1 |
| Immersion | 9.3 |
| Accessibilité | 8.8 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 8.6 |

## Verdict

PASS WITH NOTES

## What works

- Une identité visuelle immédiatement Noche Live.
- Un répertoire complet paginé, sans clé API dans le navigateur.
- Miniatures internes et iframe absente avant consentement.
- Un seul CTA or dans le consentement, là où la décision est réelle.

## What feels weak

- Le contenu réel dépend du secret `YOUTUBE_API_KEY` sur Render.
- Le premier consentement ajoute une étape, assumée au profit de la confidentialité.

## Required before approval

- None.

## Evidence

- `tmp/street-shots/temple-mockups/mockup-church-videos-mobile.png`
- `tmp/street-shots/temple-mockups/mockup-church-videos-consent.png`
- `tmp/street-shots/temple-mockups/mockup-church-videos-player.png`
- `tmp/street-shots/temple-mockups/mockup-church-videos-desktop.png`
- `tmp/street-shots/temple-mockups/mockup-hub-official-videos-tile.png`

## Night director

Oui : après une vidéo, le répertoire reste visible et donne envie d’en ouvrir une autre. La page offre un changement de rythme sans se faire passer pour une manche.
