# 113 — Lectures qualifiées des chapitres

Reviewed: 2026-08-28
Slice: compter une lecture réelle, montrer la communauté de lecteurs, découvrir les chapitres les plus lus
Tests: ciblés `bin/rails test …` — 74 runs, 579 assertions, 0 failures; suite complète — 894 runs, 14 136 assertions, 1 failure préexistant hors slice (`UiChromeTest`, `quiz_controller.js` attend `overlaySession`)
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validés

## Feeling

Curiosité et appartenance : « d’autres personnes ont pris le temps de lire ce chapitre » puis envie de découvrir ce qui les a touchées.

## 1 — Game experience

La boucle reste calme : ouvrir → lire réellement → atteindre le cœur du chapitre → recevoir un feedback social discret → pouvoir découvrir les chapitres les plus lus. Une ouverture rapide ne devient pas une fausse récompense : il faut 10 secondes visibles et 50 % du contenu, avec une seule lecture par identité/appareil et par jour.

## 2 — UI design

Le compteur est secondaire sous le titre, en `--muted`, sans concurrencer la lecture. L’ordre des Écritures reste le défaut ; « Les plus lus » est un filtre secondaire, pas un tableau de bord. Les cibles du sélecteur restent confortables sur 390 × 844. États : zéro masqué, lecture en cours silencieuse, succès mis à jour par le serveur, échec réseau non bloquant, doublon stabilisé au compteur confirmé.

## 3 — Art direction

Celestial Light demeure une chambre de lecture ivoire. Aucun VFX n’est ajouté : le calme du texte est le moment. L’or reste sur la signature et les détails existants ; le compteur utilise l’encre secondaire. La preuve sociale enrichit la scène sans devenir un badge SaaS.

## Theme engine

N/A — ni le Hub ni son atmosphère ne changent.

## Four seats

N/A — lecture Street individuelle. La liseuse répond à « que lire maintenant ? » tandis que le classement ouvre une prochaine envie.

## Tension

La tension est éditoriale, pas chronométrée : curiosité devant les chapitres qui ont rassemblé le plus de lecteurs. Aucun rail Live ou artifice de manche n’est ajouté.

## Finale

N/A.

## Languages

PASS — es « lectura(s) », pt-BR « leitura(s) », fr « lecture(s) », en « read(s) ». Les séparateurs de milliers sont natifs (`1.284`, `1 284`, `1,284`) et les quatre fichiers ont leurs pluriels.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 9 |
| Progression | 8 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- La donnée reflète un engagement réel et résiste aux doubles ouvertures et aux courses concurrentes.
- Le compteur se met à jour sans interrompre la lecture.
- Le classement valorise la découverte sans casser l’ordre canonique.
- Le contrôle navigateur a confirmé `1 284 → 1 285 lectures` après qualification, sans erreur console.

## What feels weak

- Le classement est historique ; un futur filtre « ces 30 derniers jours » donnerait davantage de renouvellement.

## Required before approval

- None.

## Evidence

PostgreSQL garantit l’unicité par `reference + reader_digest + read_on`; le compteur agrégé est incrémenté dans la même transaction.

## Night director

Oui : le chiffre ne récompense pas un tap, il transforme une lecture calme en signe d’appartenance et propose naturellement le prochain chapitre à découvrir.
