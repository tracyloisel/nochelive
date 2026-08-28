# M107 — Un seul HUD, deux modes célestes

Reviewed: 2026-08-28
Slice: HUD joueur partagé sur le hub, l’aventure, la ligue, la Parole, l’Église, la rama et les parties
Tests: `bin/rails test` — 876 runs, 11742 assertions, 0 failures; couverture 93.41%
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — aucune copie joueur déplacée

## Feeling

Confiance et continuité. Le joueur doit reconnaître instantanément son identité, sa progression et ses ressources, quel que soit le monde illustré derrière lui.

## 1 — Game experience

Le HUD maintient la boucle de rue : identité → progression du pack → couronnes et série → menu → prochaine action. La structure ne change plus entre les routes ni entre les illustrations. Les états utiles restent présents — invité, joueur, quiz, progression, série et montée de rang — sans créer de troisième apparence.

## 2 — UI design

Le verbe en deux secondes reste celui de la page ; le HUD répond immédiatement aux questions « qui suis-je ? », « où en suis-je ? » et « qu’ai-je gagné ? ». Le même composant expose uniquement `celestial-light` et `celestial-dark`. Chaque palette déclare localement ses surfaces, textes, bordures, boutons et ombres afin qu’aucun token de page ne puisse modifier le contraste par héritage.

Le mode Light utilise une surface ivoire opaque et de l’encre bleu nuit. Le mode Dark utilise une surface bleu nuit dense et du texte crème. Les contrôles conservent leur anatomie, leur taille et leurs états tactiles dans les deux modes.

## 3 — Art direction

Le HUD reste un chrome Noche Live reconnaissable : sceau, bleu nuit, ivoire et ponctuation or. Light et Dark sont choisis depuis l’œuvre, jamais par l’utilisateur. Le décor nocturne de Bethléem est désormais correctement déclaré sombre ; il ne peut plus produire le HUD noir translucide et illisible observé en production.

## Theme engine

Même Home, même markup, tokens uniquement. Le manifeste choisit `light` ou `dark`, le composant normalise vers `celestial-light` ou `celestial-dark`, et toute valeur absente ou invalide revient de façon sûre à Light. Les scènes testées gardent un seul Hub et une seule structure HUD.

## Four seats

N/A street.

| Question | Réponse visible |
|---|---|
| Who | avatar, nom et rang |
| Where | pack et étape courante |
| What now | progression et menu |
| Around me | couronnes et série |

## Tension

La rail de progression, le score et la série continuent de porter la tension de la rue et des parties. La correction de thème ne retire aucun feedback de jeu ; elle rend ces signaux constants sur tous les décors.

## Finale

N/A — le HUD de cérémonie conserve sa composition compacte, alimentée par les mêmes deux palettes.

## Languages

N/A — aucune chaîne de traduction modifiée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 10 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 10 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Une seule anatomie HUD et exactement deux valeurs de thème autorisées.
- Contraste du texte principal vérifié à au moins 7:1 sur des zones d’illustration noires et blanches dans les deux modes.
- Hub, aventure, ligue, Parole, Église et rama testés dans un viewport mobile commun.
- Les anciens skins Rama, Défis, carte et Parole ne peuvent plus supplanter la palette du composant.

## What feels weak

- Les pages très lumineuses de la carte et de la ligue gardent volontairement leur direction artistique pâle ; le HUD y reste lisible mais le contraste du contenu de page sort du périmètre de cette correction.

## Required before approval

- None.

## Evidence

- `tmp/street-shots/hud-celestial-light.png`
- `tmp/street-shots/hud-celestial-dark.png`
- `tmp/street-shots/hud-route-hub.png`
- `tmp/street-shots/hud-route-adventure.png`
- `tmp/street-shots/hud-route-league.png`
- `tmp/street-shots/hud-route-word.png`
- `tmp/street-shots/hud-route-church.png`
- `tmp/street-shots/hud-route-ward.png`
- `bin/rails test test/system/street_quiz_visual_test.rb -n /layout_chrome_keeps_one_viewport_contract/` — 1 run, 108 assertions, 0 failures.

## Night director

Oui. Le joueur n’a plus à réapprendre ou à déchiffrer le HUD quand le monde change ; son identité, sa progression et ses gains restent immédiatement disponibles.
