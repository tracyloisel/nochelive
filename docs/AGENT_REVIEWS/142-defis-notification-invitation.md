# M142 — L’invitation de défi devient le prochain battement social

Reviewed: 2026-08-29
Slice: `/desafios`, invitation contextuelle aux alertes entre l’envoi d’un défi et les rivaux
Tests: 24 runs Rails, 233 assertions, 0 failures, 0 errors; 8 tests Node pass
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — destination Street Celestial Dark, pas le Hub `/`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr présents et relus

## Feeling

Anticipation et lien social : le défi est parti, la prochaine émotion attendue est la réponse de l’ami. L’autorisation devient une manière de ne pas rater ce moment, pas une demande système abstraite.

## 1 — Game experience

La boucle est lisible : invitation envoyée → proposition d’alerte → rivaux suivants → réponse → prochain défi. Le prompt n’apparaît qu’après l’envoi réel d’un défi nommé, reste volontaire et peut être repoussé trente jours avec « Pas maintenant ». L’installation iPhone reste une étape séparée et ne chaîne jamais la permission push.

## 2 — UI design

Le verbe à deux secondes est « Activer les alertes de défi ». Une seule action or domine ; le refus calme reste accessible. Le panneau précède immédiatement « Rivaux de ta communauté », confirme brièvement le succès, puis disparaît. Il reste absent lors des visites suivantes si la catégorie et l’abonnement de cet appareil sont actifs. Les états idle, loading, success, failure, installation requise et réduit-motion sont conservés. Le panneau est mesuré à 390 × 844, 768 × 1024 et 1440 × 900 sans débordement, avec toutes les cibles à 44 px minimum. Celestial Light est N/A : la page Défis est une destination Celestial Dark déterministe.

## 3 — Art direction

Le panneau est un verre navy compact posé dans le Campus nocturne. La tranche or, le médaillon aux épées et les cercles de signal donnent un rythme de cérémonie sans concurrencer les rivaux ni le HUD. L’or est réservé à l’action et au signal actif.

## Theme engine

N/A — aucun changement du Hub `/`. La section consomme les tokens sémantiques existants de la destination Défis et n’introduit ni toggle ni branche de markup parallèle.

## Four seats

Street — qui : Tracy et l’ami défié ; où : Campus des Écritures ; quoi maintenant : activer les alertes ou continuer sans ; autour de moi : les rivaux et l’invitation qui vient d’être envoyée.

## Tension

Le défi envoyé crée l’attente ; la promesse « Ne manque pas sa réponse » la nomme. La permission ne fabrique pas une nouvelle tension : elle protège le retour vers le duel existant.

## Finale

N/A — aucune règle de manche, de score ou de cérémonie n’est modifiée.

## Languages

Les quatre versions es, pt-BR, en et fr ont la même intention : invitation partie, réponse à ne pas manquer, bénéfice concret même lorsque l’app est fermée, consentement explicite avant activation.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 10 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- Le prompt appartient désormais au flux de la page au lieu de flotter comme une bannière hors contexte.
- Il constitue la transition directe entre la confirmation d’envoi et « Rivaux de ta communauté ».
- Le bénéfice social précède la permission et le CTA ne promet que des alertes de défi.
- Une préférence active sur un autre appareil ne masque plus abusivement l’invitation locale ; seul un abonnement valide sur l’appareil courant la retire.
- Les variantes mobile, tablette et desktop restent compactes, lisibles et sans espace fantôme.
- Le CTA push reste caché dans le parcours d’installation iPhone ; aucune permission n’est chaînée.

## What feels weak

- La validation éditoriale finale des nouvelles formulations reste à consigner avant un déploiement de production.
- Le test de permission système réelle reste à faire dans un Chrome connecté : le navigateur intégré n’expose pas l’API Notifications et l’extension ChatGPT n’est pas installée dans Chrome.

## Required before approval

- Faire approuver explicitement les quatre formulations et confirmer le maintien de l’audience actuelle (après défi nommé), du snooze de 30 jours et de la destination alertes de défi avant activation en production.

## Evidence

- Captures inspectées : `tmp/push-shots/challenge-invitation-reduced-motion-390x844.png`, `768x1024.png`, `1440x900.png` et `challenge-invitation-activated-390x844.png`.
- Console fraîche sur `/notifications` et `/desafios` : 0 warning, 0 error.
- Parcours d’activation autorisé par l’utilisateur et exercé avec le navigateur système simulé ; le contrôle natif a correctement signalé `unsupported` au lieu de prétendre à une permission réelle.
- `bundle exec rails test test/services/notifications/prompt_eligibility_test.rb` : 4 runs, 12 assertions, green.
- `bundle exec rails test test/controllers/notification_experience_test.rb` : 8 runs, 62 assertions, green.
- `bundle exec rails test test/controllers/notifications_controller_test.rb` : 6 runs, 28 assertions, green.
- `bundle exec rails test test/system/web_push_experience_test.rb` : 6 runs, 131 assertions, green.
- `node --test test/javascript/service_worker_push_test.mjs` : 8 tests, green.
- État QA temporaire restauré après la prévisualisation.

## Night director

Oui. Après avoir défié quelqu’un, je veux connaître sa réponse ; la permission est maintenant la suite naturelle de ce désir, pas un détour administratif.
