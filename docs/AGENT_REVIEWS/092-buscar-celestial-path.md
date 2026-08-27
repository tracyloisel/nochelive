# M092 — Buscar, le chemin vers les siens

Reviewed: 2026-08-27
Slice: `/buscar` et `/buscar?cambiar=1`
Tests: `bin/rails test test/controllers/searches_controller_test.rb test/i18n/locale_files_test.rb` — 13 runs, 235 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A — écran Buscar, Celestial Light dicté par son artwork
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validés

## Feeling

Appartenance et émerveillement : la recherche ouvre un chemin vers une communauté, au lieu de ressembler à un formulaire administratif posé dans un hall vide.

## 1 — Game experience

Anticipation (la vallée et son chemin) → action unique (chercher ou se localiser) → résultat immédiat → branche mise en valeur → envie d’entrer jouer avec les siens. Aucun résultat n’est injecté avant une action du joueur.

## 2 — UI design

Le verbe Buscar est compris en moins de deux secondes. Le titre vit dans le monde et la console compacte ne contient que l’action ; les résultats deviennent des portes horizontales dans cette même pièce. La feuille ne saute pas avec le clavier. États validés : vide, focus/pressed, chargement, résultat, aucun résultat et localisation disponible. Cibles principales ≥ 48 px, texte en encre sur ivoire, recherche autonome au clavier.

## 3 — Art direction

Celestial Light. Une vallée méditerranéenne, plusieurs chapelles et un chemin d’or racontent la destination. L’or est métal, apex et trajectoire ; les titres restent en encre. Blur local sur la feuille, rayons et profondeur dans le monde, sans voile laiteux global.

## Theme engine

N/A.

## Four seats

N/A street. Qui : le profil demeure dans le chrome. Où : la paroisse recherchée. Maintenant : chercher ou utiliser sa position. Autour de moi : les résultats par pieu et la paroisse suggérée.

## Tension

Micro-boucle street : le chemin visible promet une destination, puis le résultat apparaît dans la même feuille sans interrompre le monde.

## Finale

N/A.

## Languages

`street.gate_search_ph` relu dans les quatre langues. Le faux défaut Benidorm disparaît : « Tu pueblo o tu rama… », « Sua cidade ou ala… », « Ta ville ou ta paroisse… », « Your town or congregation… ».

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 8 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- La recherche est l’unique geste dominant.
- Le chemin d’or est immédiatement identifiable comme la signature Noche.
- Le décor reste visible dans les états vide, chargement et résultat ; aucun grand panneau blanc ne le décapite.

## What feels weak

- La permission de géolocalisation dépend toujours du navigateur et ne peut pas être démontrée sans consentement explicite.

## Required before approval

- None.

## Evidence

- Mobile 390 × 844 : vide, chargement et résultat contrôlés dans le navigateur, zéro erreur console.
- Capture finale : `tmp/street-shots/temple-mockups/mockup-street-buscar-celestial-light-v2.png`.

## Night director

Oui : le joueur voit une destination avant même de chercher, puis un résultat concret l’invite à rejoindre les siens.
