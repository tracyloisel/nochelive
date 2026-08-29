# M126 — La course amicale devient vivante pendant le quiz

Reviewed: 2026-08-29  
Slice: réponse → projection multi-défis → écart → égalité/dépassement live → résultat confirmé  
Tests: 17 tests / 111 assertions ; contrôleur complet 8 / 159 ; visuel 1 / 37, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Copy: `.agents/skills/noche-i18n/SKILL.md` — 189 clés `duel_campus` à parité en es, pt-BR, en et fr

## Feeling

Une tension douce et humaine : « ma réponse vient de me rapprocher d’un ami ». Le
joueur doit sentir la présence de ses défis sans quitter l’apprentissage ni subir une
interface d’arène.

## 1 — Game experience

Chaque bonne réponse met à jour le score brut provisoire. Le moteur choisit la course
qui raconte le mieux la partie : événement de dépassement, comparaison la plus proche,
score cible, ami en train de jouer, attente, puis défi prêt. Une revanche sans score ne
masque plus un objectif chiffré. L’égalité et le dépassement sont distingués. Le score
reste explicitement provisoire jusqu’à la fin, bonus de série compris ; la résolution
émet ensuite un état officiel séparé.

Les runs ouverts avant l’acceptation d’un défi ne sont jamais appliqués rétroactivement.
Un même run éligible peut en revanche nourrir plusieurs défis, sur le même pack ou non,
conformément à la comparabilité des scores bruts.

## 2 — UI design

Le verbe en deux secondes est `rattraper` ou `dépasser`. Le rail ne montre plus trois
visages et un compte abstrait : il focalise un ami, l’écart exact, les deux scores et le
nombre total de défis actifs. Il reste entre le HUD et la question, sans toucher le
chrono ni la sheet. Les mises à jour Turbo remplacent uniquement ce rail et ne
rechargent jamais le quiz.

États couverts : cible, poursuite, égalité, avance, attente, ami live, revanche prête,
progression distante, dépassement local ou distant, résultat officiel gagné, perdu ou
à égalité. Le mouvement réduit supprime les animations ; `aria-live`, libellés de score
et cible de remplacement stable restent disponibles.

## 3 — Art direction

Le verre vert profond et le filet or restent lisibles sur les peintures Celestial Light
et Dark. Le rail compact laisse l’art biblique porter l’émotion. Un reflet or très bref
récompense le dépassement ; l’activité adverse garde un feedback plus doux. Aucun code
visuel de combat, rouge punitif ou grande bannière ne concurrence les Écritures.

## Theme engine

N/A — surface Street. Le mode Light/Dark continue de venir du manifeste de l’illustration,
sans toggle ni duplication du markup.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Répondre et voir immédiatement qui je rattrape |
| Mon ami | Voir ma progression sans rechargement s’il joue aussi |
| Autour de moi | Garder plusieurs défis actifs sans perdre le duel important |
| Prochaine envie | Marquer les points manquants puis ouvrir le résultat confirmé |

## Tension

L’écart exact descend après chaque bonne réponse. L’égalité, le dépassement puis le
résultat confirmé sont des paliers distincts. Les mauvaises réponses ne fabriquent pas
de drame artificiel et aucun score provisoire n’est présenté comme acquis.

## Finale

Le bonus final peut encore renverser la course. Le joueur qui termine retrouve ses
impacts dans la cérémonie existante ; l’ami connecté reçoit un état `Score confirmé`
sur le rail, même si le bonus a provoqué le dépassement. Sa prochaine interaction rend
ensuite la priorité au défi actif suivant.

## Languages

Les textes de cible, écart, égalité, dépassement, progression distante et résultat
officiel ont été relus dans les quatre langues. Les fichiers YAML se chargent et les
189 clés `duel_campus` sont strictement à parité.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9.0 |
| Clarté | 9.4 |
| Impact visuel | 8.8 |
| Feedback | 9.4 |
| Progression | 9.2 |
| Social | 9.3 |
| Immersion | 8.9 |
| Accessibilité | 9.1 |
| Cohérence NocheLive | 9.3 |
| Envie de continuer | 9.3 |

## Verdict

PASS — livraison locale, validation physique à deux appareils encore requise avant le
pilote de production.

## What works

- priorité fondée sur la valeur de course, plus sur le flag revanche ;
- projections honnêtes et indépendantes des packs ;
- égalité, dépassement et bonus final traités sans mentir sur le caractère provisoire ;
- mise à jour ciblée chez l’ami, sans refresh de sa partie ;
- rail centré pendant toute sa transition, après suppression du conflit global
  `.is-arriving` ;
- même anatomie lisible en Celestial Light et Dark, de 390 à 1440 px.

## What feels weak

- le vrai simultané reste à exercer sur deux téléphones et une connexion dégradée ;
- aucun son dédié n’a été ajouté : le rail utilise seulement des haptics existants ;
- la présence live conserve sa fenêtre stricte existante.

## Required before production approval

- Jouer le même duel sur deux appareils physiques et vérifier progression, égalité,
  dépassement, arrière-plan/reprise et bonus final.
- Vérifier VoiceOver/TalkBack sur les annonces `aria-live` en situation réelle.

## Evidence

- captures inspectées : `duel-race-390x844-light`, `duel-race-390x844-dark`,
  `duel-race-768x1024-dark`, `duel-race-1440x900-dark` ;
- géométrie automatisée : rail sous le HUD, au-dessus de la sheet, dans le viewport ;
- console Chrome : 0 entrée `SEVERE` ;
- tests moteur, fan-out, contrôleur et page : 17 / 111, verts ; contrôleur de quiz
  complet : 8 / 159, vert ;
- test visuel Light/Dark et trois viewports : 1 / 37, vert ;
- Ruby, JavaScript et quatre YAML parsés ; parité i18n 189/189.

## Night director

Oui. Une bonne réponse n’augmente plus seulement un compteur : elle réduit une distance
humaine visible, peut créer un petit renversement et donne immédiatement envie de jouer
la question suivante.
