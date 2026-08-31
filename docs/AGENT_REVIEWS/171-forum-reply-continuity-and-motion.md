# M171 — Répondre sans quitter le fil du Forum

Reviewed: 2026-08-31
Slice: publier une réponse et la voir s’insérer dans la conversation ouverte, sans saut de page ni retour à l’inbox
Tests: `bundle exec rails test test/controllers/scripture_circle_posts_controller_test.rb test/services/scripture_circles/rama_refresh_test.rb test/services/scripture_circles/realtime_dispatch_test.rb test/system/scripture_circle_realtime_test.rb test/system/scripture_circle_visual_test.rb` — 18 runs, 218 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — le Forum conserve sa surface Celestial Light approuvée.
Copy: N/A — aucun texte joueur ni message éditorial n’a changé.

## Feeling

Continuité et présence : « ma réponse rejoint immédiatement la conversation que je suis en train de lire ; le produit ne m’expulse pas de cet échange. »

## 1 — Game experience

La boucle est maintenant `écrire → envoyer → voir ma réponse prendre place dans le thread → pouvoir continuer à lire ou répondre`. Le retour n’est ni une navigation, ni une reconstruction visible de la page. Le signal ActionCable de la publication porte l’identifiant du post ; lorsque la réponse est déjà arrivée avec la réponse Turbo du formulaire, le navigateur reconnaît ce signal comme redondant et ne recharge pas le frame une seconde fois.

Le composeur reste ancré à la même position visuelle pendant le remplacement Turbo. La nouvelle réponse apparaît juste au-dessus, entièrement visible. Une erreur de validation conserve son brouillon et les mises à jour distantes continuent d’attendre tant que ce brouillon doit être protégé.

## 2 — UI design

Le verbe en deux secondes reste « répondre ». L’état pressed réduit légèrement le bouton d’envoi ; l’état loading garde une cible de 44 px et compacte son ombre. Le succès anime uniquement la nouvelle ligne pendant 300 ms. Le frame complet ne pulse plus.

Le plan de mouvement est borné :

- ouvrir un échange : déplacement horizontal de 11 px, 220 ms, sans fondu ;
- revenir à l’inbox : déplacement inverse de 9 px, 200 ms, sans fondu ;
- filtrer l’inbox : transition locale de 180 ms ;
- publier ou recevoir une réponse : apparition locale de 300 ms ;
- mouvement réduit : aucune animation décorative.

La transition globale de document est neutralisée uniquement sur le Forum. Elle laissait auparavant l’ancien inbox/thread visible derrière le nouveau frame et produisait un effet de double page.

## 3 — Art direction

Le mouvement sert la parole au lieu de devenir un spectacle. L’or reste concentré sur le geste d’envoi et sur le bref fond lumineux de la réponse entrante. Aucun voile plein écran, flash global, SFX ou récompense artificielle n’est ajouté à cette conversation contemplative.

## Theme engine

N/A — le Forum rendu ici est la surface de rassemblement Celestial Light existante ; aucun toggle ni nouveau monde n’est introduit.

## Four seats

N/A — boucle communautaire asynchrone. La personne reste dans la conversation choisie.

## Tension

Tension douce : la réponse rejoint une parole réelle de la rama. Le feedback confirme l’action sans interrompre la lecture ni transformer la contribution en score.

## Finale

N/A — aucune mécanique Live n’est modifiée.

## Languages

N/A — aucun libellé n’a changé ; la parité existante est préservée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9.5 |
| Impact visuel | 8.5 |
| Feedback | 9.5 |
| Progression | 8 |
| Social | 9.5 |
| Immersion | 9 |
| Accessibilité | 9.5 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Une publication réussie produit un seul chargement du frame, pas un second rafraîchissement ActionCable.
- Le thread reste ouvert sur mobile ; l’inbox ne réapparaît pas.
- Le scroll ne remonte jamais pendant l’envoi et le composeur revient à moins de 3 px de son ancrage initial.
- La réponse publiée est visible juste au-dessus du composeur.
- Les brouillons et erreurs de validation restent protégés contre les mises à jour distantes.

## What feels weak

- Aucun son ni haptique n’accompagne l’envoi. C’est volontaire : le Forum est une surface de parole calme, pas une manche Live.

## Required before approval

- Aucun.

## Evidence

- Captures inspectées : `tmp/street-shots/scripture-circle-motion/forum-thread-390x844.png`, `forum-thread-768x1024.png`, `forum-1440x900.png` et `forum-reply-inserted-390x844.png`.
- QA responsive : 390 × 844, 768 × 1024 et 1440 × 900, sans débordement horizontal ni ancien écran visible derrière la transition.
- Le scénario de publication vérifie un seul `turbo:frame-load`, l’identifiant du signal temps réel, l’insertion locale, la visibilité de la réponse et la stabilité du scroll.
- Console runtime sans erreur liée au Forum ; l’amorçage isolé des tests filtre seulement la requête implicite `/favicon.ico` de Chrome, absente des vraies pages qui déclarent `/favicon-32.png`.

## Night director

Oui : je réponds, je vois ma parole rejoindre les autres, et je reste dans la conversation sans sentir la mécanique Turbo.
