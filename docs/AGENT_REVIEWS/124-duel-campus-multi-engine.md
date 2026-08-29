# M124 — Le défi devient un Campus d’apprentissage partagé

Reviewed: 2026-08-29  
Slice: invitation honnête → défi actif multi-runs → quiz multi-défis → résultat → revanche amicale  
Tests: Rails 981/981, 15 175 assertions ; Service Worker 6/6 ; système, captures et mouvement réduit verts  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Hub theme: même Hub, une tuile Campus, aucun toggle ni Home dupliqué  
Copy: `.agents/skills/noche-i18n/SKILL.md` — 124 clés Campus à parité en es, pt-BR, en et fr

## Feeling

Appartenance, curiosité et fierté douce : « mes amis apprennent avec moi et ma
prochaine partie compte ». La tension vient d’une personne réelle et d’un résultat
attendu, jamais d’une arène ou d’une humiliation.

## 1 — Game experience

La boucle est lisible et reproductible : invitation → choix libre du parcours → score
universel → impact sur N défis → résultat → revanche ou propagation. Une seule partie
peut faire avancer plusieurs relations, ce qui rend chaque run plus vivant sans
ajouter de clic administratif. L’invitation et le duel sont désormais deux objets
distincts ; l’attente avant acceptation n’est plus présentée comme une compétition
active.

## 2 — UI design

Le verbe prioritaire tient en deux secondes : accepter et jouer, ouvrir son défi, ou
inviter un ami. Le Campus groupe invitations, défis actifs, résultats, amis et accusés
honnêtes. Le rail du quiz annonce le nombre d’amis concernés sans pousser la question.
La cérémonie garde le score personnel en premier puis affiche toutes ses conséquences
sociales dans une surface dédiée. Notifications et CTA vivent au-dessus du dock avec
safe areas explicites.

États couverts : envoyé, handoff, lien ouvert, livré, vu, accepté, refusé, expiré,
actif, un score posé, résolu, résultat non vu, revanche, mouvement réduit et erreur de
partage. Le contenu critique reste visible si JavaScript ou l’observateur manque.

## 3 — Art direction

Trois compositions dédiées installent le Campus biblique dans une forêt elfique
lumineuse : monde principal, invitation et cérémonie. Les personnes sont humaines,
souriantes et placées dans la bande haute ; la moitié basse reste sacrifiable pour les
sheets et le dock. Ivoire, vert profond et or conservent la signature Noche Live sans
codes de combat. Les mouvements utilisent rapprochement, lumière et élévation douce.

## Theme engine

Le Hub conserve son markup et sa famille Celestial issue du backdrop. La tuile Campus
est une destination sociale dans le même feed. Le Campus possède une surface Light
cohérente avec son artwork ; aucun toggle utilisateur ni seconde Home n’a été créé.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Jouer le parcours qui me plaît et voir tous les défis concernés |
| Mon ami | Recevoir, comprendre, accepter ou remettre à plus tard |
| Autour de moi | Voir les amis disponibles et l’activité du Campus |
| Prochaine envie | Revanche amicale ou invitation issue de mon propre score |

## Tension

Elle monte par preuve humaine : invitation préparée → arrivée ou ouverture réelle →
acceptation → premier score posé → résultat. Le moteur n’invente ni livraison ni
lecture à partir d’une feuille de partage. Plusieurs défis donnent du poids à la
partie ; un ami focal garde l’histoire compréhensible.

## Finale

La cérémonie célèbre d’abord la performance biblique, puis révèle combien de défis
elle a fait avancer. Chaque ligne donne l’ami, l’état et les deux scores bruts. Le CTA
principal ouvre la propagation avec le score ; le Campus et la carte restent des
sorties secondaires explicites.

## Languages

Les quatre fichiers YAML se chargent. Les 124 clés `duel_campus` et toutes leurs
interpolations sont à parité en espagnol, portugais brésilien, anglais et français.
Les anciens libellés d’arène, adversaire, pack imposé et rivalité ont été retirés de la
couche défi.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.7 |
| Clarté | 9.2 |
| Impact visuel | 9.0 |
| Feedback | 8.8 |
| Progression | 8.7 |
| Social | 9.4 |
| Immersion | 9.1 |
| Accessibilité | 8.3 |
| Cohérence NocheLive | 9.2 |
| Envie de continuer | 9.0 |

## Verdict

PASS — livraison locale. Le domaine, le cutover, la suppression legacy, les surfaces
Campus et leur géométrie mobile sont validés. Le pilote de production garde un gate
distinct sur les appareils physiques et la mesure virale réelle.

## What works

- séparation nette invitation / duel / run et fan-out transactionnel ;
- un seul défi actif par paire, créations répétées et claims convergents, avec ordre
  de verrous commun et expiration transactionnelle des paires anciennes ;
- revanche sans pack imposé et scores bruts comparables ;
- reçus nommés et externes distincts, monotones et honnêtes ;
- forêt biblique amicale avec visages hauts et zone basse sacrifiable ;
- notification temps réel au-dessus du dock avec Push de secours différé ;
- CSS Campus isolé et suppression des styles legacy, y compris la dernière tuile
  `hub-invitations` devenue morte ;
- funnel jusqu’au retour D7 et à la première invitation sortante acquise.

## What feels weak

- le rendu réel sur WebKit/iOS et Android physique n’est pas encore observé ;
- la chorégraphie réemploie les cues Noche existants et reste volontairement sobre ;
- la vérité « livré » d’un Push dépend toujours du meilleur signal permis par la
  plateforme ; le produit ne la déduit jamais d’un simple partage.

## Required before production pilot

- Effectuer un parcours réel à deux appareils pour livré → vu → accepté → résultat.
- Vérifier WebKit/iOS et Android physique, rotation, reprise après arrière-plan et Push.
- Exécuter l’A/A analytics, puis lire conversion, refus, blocages, K et temps de
  génération avant de conclure sur la viralité.

## Evidence

- `rails zeitwerk:check` vert ; Ruby, JavaScript, ERB, CSS et quatre YAML parsés ;
- parité i18n : 124 clés sur 124 dans les quatre langues ;
- Service Worker : 6 tests, 6 succès ;
- suite Rails complète : 981 tests, 15 175 assertions, 0 échec, 0 erreur ;
- cutover : 29 invitations, 19 défis, 0 paire active dupliquée, 0 origine manquante,
  0 relation invitation → défi incohérente ;
- captures : Campus 390×844, 768×1024, 1440×900, invitation froide et connue,
  signal, résultat et mouvement réduit ;
- QA navigateur intégrée : aucun warning/erreur console, aucun overflow horizontal,
  CTA d’invitation à 27,7 px du dock après correction ;
- contrat d’architecture interdisant fichiers, colonnes, styles et clés mono-duel ;
- artworks : `campus-scriptures-master-v1`, `campus-invitation-friends-v1` et
  `campus-ceremony-friends-v1`, PNG + WebP.

## Night director

Oui. Une partie supplémentaire a désormais une conséquence sociale visible auprès de
plusieurs amis, et le résultat ouvre une nouvelle envie sans forcer la répétition du
même contenu.
