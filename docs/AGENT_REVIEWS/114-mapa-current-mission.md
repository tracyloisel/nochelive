# 114 — Mission actuelle sur la carte céleste

Reviewed: 2026-08-28
Slice: `/mapa`, premier écran et reprise de l’aventure
Tests: ciblés controller + système + parité i18n — 10 runs, 320 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — aucune nouvelle copie ; clés es, pt-BR, en et fr existantes validées

## Feeling

Fierté de voir le chemin déjà parcouru, curiosité devant les paliers futurs et envie immédiate de reprendre la mission actuelle.

## 1 — Game experience

La boucle devient explicite dès le premier écran : reconnaître son pack courant → voir l’étape et la progression → toucher **Continuer l’aventure** → jouer → revenir voir le nœud et la jauge avancer. Le nœud courant ne déclenche plus un saut de scroll lorsqu’il est déjà visible. Les cadenas gardent leur retour haptique et leur indice contextuel sans encombrer la page au repos.

## 2 — UI design

Les quatre grandes statistiques de type dashboard sont remplacées par une seule carte de mission : médaillon du pack, titre, étape, jauge, récompenses et unique CTA doré. Les catégories restent secondaires et deviennent sticky sous le HUD pendant l’exploration. États couverts : idle, pressed, focus, catégorie active/atténuée, pack courant, terminé, verrouillé, indice de verrou, déverrouillage et mouvement réduit. Les libellés utiles respectent le plancher `--type-min`.

## 3 — Art direction

Celestial Light reste dicté par l’artwork : route lumineuse, îles sacrées et nuages ivoire. Le décor redevient visible entre les blocs ; l’or se concentre sur le médaillon, la progression et l’unique action principale. Le titre reste en encre et la carte de mission utilise un verre ivoire local, sans voile plein écran.

## Theme engine

N/A — `/mapa` est un monde d’aventure Celestial Light dédié, pas un thème utilisateur.

## Four seats

N/A street — qui : HUD joueur ; où : pack et palier courants ; quoi maintenant : Continuer l’aventure ; autour : catégories, coffres, paliers et classement.

## Tension

Le prochain nœud, les cadenas, les coffres de dizaine et les paliers futurs donnent la prochaine envie. Le CTA lance le pack ; les filtres servent ensuite à explorer, sans concurrencer l’action principale.

## Finale

N/A.

## Languages

PASS — aucune nouvelle chaîne. `hub.continue`, `street.pack_step`, `street.pack_here`, les catégories et les libellés de progression sont présents en es, pt-BR, en et fr ; test de parité vert.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 10 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 10 |

## Verdict

PASS

## What works

- Le joueur sait quoi faire en moins de deux secondes.
- La mission, le premier palier et le pack courant tiennent dans le premier écran téléphone.
- La barre de catégories reste accessible pendant le scroll sans recouvrir le HUD.
- Le rendu conserve zéro débordement horizontal à 390, 804 et 1440 px.

## What feels weak

- Le fond reste volontairement Celestial Light pour toute la carte ; un futur catalogue multi-mondes pourrait faire varier l’atmosphère par palier sans changer la structure.

## Required before approval

- None.

## Evidence

Contrôle navigateur : 390 × 844, 804 × 1100 et 1440 × 900 ; zéro erreur console. Capture système signée-in : `tmp/street-shots/map-phone.png`.

## Night director

Oui : la prochaine action n’est plus cachée dans un nœud anonyme. Le joueur voit sa mission, son gain de progression et le prochain chemin avant de lancer une nouvelle série de questions.
