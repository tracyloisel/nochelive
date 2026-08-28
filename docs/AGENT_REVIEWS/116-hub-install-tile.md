# M116 — Installer Noche Live depuis le hub

Reviewed: 2026-08-28
Slice: une invitation d’installation secondaire sur la home
Tests: hub + i18n — 38 runs, 753 assertions; visuel Light/Dark — 1 run, 8 assertions; 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr existants, relus et inchangés

## Feeling

Appartenance et sérénité : Noche Live peut rester à portée de main sans interrompre l’aventure.

## 1 — Game experience

Anticipation (garder l’aventure près de soi) → tap sur la tuile → prompt natif ou guide iOS → ajout à l’écran d’accueil → retour direct dans le hub. La tuile disparaît lorsque l’app est installée. Elle reste après l’aventure, le Live, le social et la progression : elle ne vole jamais le prochain geste de jeu.

## 2 — UI design

Verbe en deux secondes : « Installer Noche Live ». La carte entière est une cible tactile, avec focus visible, état pressé, prompt de chargement natif et disparition en succès/standalone. En échec ou navigateur non compatible, elle reste cachée. Les surfaces consomment les tokens sémantiques du hub dans les deux familles.

## 3 — Art direction

Émotion : garder une porte familière vers le monde Noche. Composition : emblème de l’app, titre en encre/crème, explication puis action secondaire. L’icône porte l’or ; aucun deuxième CTA doré ne concurrence « Jouer ». Pas de VFX supplémentaire : un léger glow au survol suffit pour cette fonction utilitaire.

## Theme engine

Une seule tuile et un seul markup. `--surface-primary`, `--surface-glass`, `--text-primary`, `--text-secondary`, `--border-gold`, `--gold-highlight` et `--shadow-card` s’adaptent au manifeste Light/Dark courant.

## Four seats

N/A street — qui : le joueur courant dans le HUD ; où : son monde courant ; maintenant : continuer l’aventure ; autour : Live, défis et communauté. L’installation reste une porte secondaire en fin de flux.

## Tension

N/A pour le Live. La tuile protège la boucle street : elle promet un retour plus rapide au prochain chapitre sans interrompre la session actuelle.

## Finale

N/A.

## Languages

Les clés `pwa.kicker`, `pwa.banner_title`, `pwa.banner_hint` et `pwa.install` sont présentes et naturelles en **es**, **pt-BR**, **fr** et **en**. Le test de parité reste requis.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Le prompt système existant est réutilisé, sans inventer une deuxième installation.
- L’app icon devient un emblème Noche dans une surface Light/Dark.
- La tuile est absente si l’app est déjà installée ou si l’installation n’est pas proposée.

## What feels weak

- Le feedback final appartient au système d’exploitation ; la tuile ne doit pas simuler une installation réussie.

## Required before approval

- None.

## Night director

Oui : installer réduit la distance jusqu’au prochain chapitre, sans détourner le joueur du geste « Jouer » maintenant.
