# M136 — L'attente du duel devient une promesse de revanche

Reviewed: 2026-08-29
Slice: `/desafios/:id` — face-à-face asynchrone, attente et verdict résolu
Tests ciblés: contrôleur 1 run / 30 assertions ; attente visuelle 1 run / 54 assertions ; verdict résolu 1 run / 5 assertions, 0 échec
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: N/A — aucune chaîne ajoutée ou modifiée ; clés existantes réutilisées

## Feeling

Sentir que mon score est posé, que Carmen doit maintenant répondre et que le duel
continue même pendant l'attente. L'écran doit créer de l'anticipation et donner envie
de rejouer, pas ressembler à un reçu administratif.

## 1 — Game experience

La boucle devient lisible : parcours terminé → score et pack nommés → rival encore
sans parcours → attente explicite → continuer à jouer → retour futur au verdict.

Le message principal ne se contente plus de dire « en attente ». Il confirme le score
déjà gagné et nomme la personne dont c'est le tour. Le CTA permet de continuer
l'aventure pendant l'attente au lieu de laisser un écran mort. Le verdict résolu garde
sa revanche et ne nomme aucun pack, puisque des parcours différents restent valides.

## 2 — UI design

Verbe à deux secondes : **continuer à jouer pendant que Carmen répond**.

- deux adversaires lisibles, avatars, noms, pack actif et couronnes ;
- `VS` explicite à la place d'un ornement ambigu ;
- tiret et « Aucun pack lancé » pour le rival, sans faux score ;
- plaque de statut : « Score posé », attente, puis score et prochain joueur ;
- un seul CTA or ; retour au Campus en lien calme ;
- score toujours accompagné de son unité ;
- région nommée par le verdict, aucun `<main>` imbriqué ;
- CTA et retour mesurés à au moins 44 px ;
- carte entièrement au-dessus du dock aux trois viewports de référence.
- illustration pleine page mesurée bord à bord et prolongée derrière la carte jusqu'au dock.

États couverts : actif/en attente, résolu, pressed via le contrôleur partagé, entrée
motion, mouvement réduit et destinations de navigation. Aucun chargement, permission
ou notification n'est introduit par cette tranche.

## 3 — Art direction

Celestial Light découle du master lumineux du Campus. L'illustration n'est plus un
hero séparé : elle devient le monde pleine page, bord à bord et jusqu'au dock. Les
recadrages gardent les amis sur les deux passerelles et le rayon central visible aux
trois formats. Les scrims restent locaux au HUD et au titre ; aucune voile laiteux ne
couvre le monde.

La feuille ivoire devient un verre céleste translucide accroché au décor par un petit
sceau des Écritures : le chemin et les bibliothèques continuent derrière elle sans
affaiblir la lecture. L'or reste la signature du filet, de l'unité de score et de
l'unique CTA ; les titres sur ivoire restent en encre. Le léger souffle autour du `VS`
crée l'anticipation et disparaît avec `prefers-reduced-motion`.

## Theme engine

N/A — cette tranche Street n'est pas le Hub `/`. La famille reste néanmoins déterminée
par l'illustration, sans interrupteur utilisateur.

## Four seats

N/A — boucle Street asynchrone.

| Rôle | Verbe maintenant |
|---|---|
| Moi | Lire mon score posé puis continuer à jouer |
| Carmen | Voir qu'un parcours l'attend |
| Le duel | Garder la tension jusqu'au second score |
| Le Campus | Ramener vers les autres défis sans voler le CTA |

## Tension

Le score réel, le tiret adverse et le souffle du `VS` matérialisent une course encore
ouverte. Aucun faux countdown ni urgence artificielle. Le mouvement est borné,
silencieux et désactivé en préférence réduite.

## Finale

Inchangée. Le verdict résolu conserve le score des deux personnes et l'action de
revanche sans sélectionner ni imposer un pack.

## Languages

Aucune nouvelle formulation. Les clés déjà présentes en **es**, **pt-BR**, **en** et
**fr** sont réutilisées. Les captures de référence ont été inspectées en français,
avec les libellés les plus longs de cette surface.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.8 |
| Clarté | 9.8 |
| Impact visuel | 9.8 |
| Feedback | 9.2 |
| Progression | 9.4 |
| Social | 9.7 |
| Immersion | 9.5 |
| Accessibilité | 9.7 |
| Cohérence NocheLive | 9.8 |
| Envie de continuer | 9.3 |

## Verdict

PASS WITH NOTES — implémentation locale, non déployée.

## What works

- la prochaine action, le score et la personne attendue se lisent sans décoder l'écran ;
- l'illustration est réellement le monde pleine page, la feuille de verre reste l'interface ;
- aucun contenu n'est tronqué ou caché par le dock en français ;
- le verdict résolu garde son contrat de parcours libres ;
- les liens pointent vers `/jugar` et `/desafios`, et la revanche POST reste couverte ;
- aucune erreur console sévère, aucun débordement horizontal ;
- aucun Story tick, faux LIVE, faux score ou deuxième CTA or.

## What feels weak

- la respiration du `VS` est volontairement subtile et gagnerait à être validée sur
  un écran OLED et un téléphone Android d'entrée de gamme ;
- la surface reste un moment asynchrone : aucune notification supplémentaire n'est
  activée pour faire revenir le rival.

## Required before production approval

- Contrôle tactile final sur iPhone et Android physiques.

## Evidence

- captures inspectées : `duel-waiting-390x844.png`,
  `duel-waiting-768x1024.png`, `duel-waiting-1440x900.png` et
  `duel-result-phone.png` ;
- 390×844, 768×1024 et 1440×900 vérifiés en Celestial Light et en français ;
- artwork mesuré bord à bord et jusqu'au dock ; carte, CTA et retour mesurés avant le
  dock ; cibles ≥ 44 px ;
- mouvement réduit : animation du `VS` calculée à `none` ;
- console : 0 erreur sévère dans le scénario d'attente ;
- tests ciblés : 3 runs, 89 assertions, 0 échec, 0 erreur ;
- aucune permission, notification, fréquence, sélection éditoriale ou destination
  externe modifiée ; aucun nouveau texte soumis à validation.

## Night director

Oui. Mon score existe, Carmen est clairement la prochaine joueuse et le bouton or me
permet de repartir dans l'aventure sans casser la tension du duel.
