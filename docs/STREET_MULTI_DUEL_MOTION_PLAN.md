# Campus des Écritures multi-défis — plan CSS d'animation et de transition

Statut : implémenté et validé après cutover dans `duel_campus.css`  
Date : 2026-08-29  
Document parent : [STREET_MULTI_DUEL_ENGINE_PLAN.md](STREET_MULTI_DUEL_ENGINE_PLAN.md)

## 1. Intention

Le mouvement doit raconter l'émulation amicale et l'apprentissage partagé sans voler
l'attention à la question.

Chaque animation doit remplir une fonction :

- rendre un défi personnel immédiatement compréhensible sur un appareil froid ;
- annoncer que plusieurs amis attendent ou jouent ;
- faire sentir une évolution relative des scores sans humilier ;
- verrouiller une performance ;
- révéler l'impact social d'un score ;
- donner envie d'une revanche amicale ou d'une nouvelle invitation selon le contexte.

Une animation purement décorative, répétitive ou bloquante est rejetée.

## 2. Principes non négociables

1. **La question reste le héros.** Aucun événement social pendant la lecture ou le
   choix d'une réponse.
2. **Une respiration, un événement.** Une seule animation sociale par transition de
   question.
3. **Le contrôle reste au joueur.** Aucune séquence longue ne bloque un CTA.
4. **CSS possède le mouvement.** Stimulus pose des classes et écoute les fins ; il
   ne dessine pas image par image.
5. **Le serveur possède l'état.** Une classe visuelle ne décide jamais d'un gagnant.
6. **Transform et opacity d'abord.** Éviter les animations de layout, de grandes
   ombres ou de blur plein écran.
7. **Light et Dark partagent la chorégraphie.** Seuls les tokens de surface, texte,
   lumière et or changent.
8. **Mouvement réduit complet.** L'information reste identique sans translation,
   zoom, stagger ni flash.
9. **Le froid privilégie le verbe.** Ami, score et CTA sont lisibles et
   interactifs dès le premier rendu ; aucune intro ne retarde la conversion.
10. **Aucun faux succès social.** Un handoff de partage ne déclenche ni confettis de
    livraison, ni animation « reçu » ou « lu ».
11. **Le Campus accueille.** Aucun shake de combat, slash, choc rouge, pose de duel ou
    couronne écrasée. Les transitions utilisent lumière traversant les feuilles,
    rapprochement de portraits, livre qui s'ouvre et trait d'or doux.
12. **Les visages restent hors chrome.** Les personnages importants vivent dans la
    bande haute `18–36 %` et ne glissent jamais sous une sheet. Le décor peut respirer
    en parallax léger ; les visages ne changent pas de zone pendant une transition.

## 3. Organisation du CSS

Le nouveau système vit dans un fichier dédié :

```text
app/assets/stylesheets/duel_campus.css
```

Il est chargé explicitement avec le shell Street. Il ne doit pas être ajouté comme
un troisième bloc tardif dans `application.css`.

Au cutover :

- supprimer toutes les règles legacy `.street-duel-*` remplacées ;
- supprimer le bloc actuel de « cascade lock » ;
- supprimer les keyframes mono-duel sans appel ;
- ne conserver aucun override de compatibilité ;
- vérifier qu'un seul fichier définit chaque composant du Campus.

Les tokens généraux peuvent rester dans `:root`. Les tokens spécifiques restent
scopés sous `.duel-campus` ou `.duel-campus-shell`.

## 4. Tokens de mouvement

```css
:root {
  --duel-motion-instant: 100ms;
  --duel-motion-fast: 160ms;
  --duel-motion-ui: 240ms;
  --duel-motion-event: 380ms;
  --duel-motion-hero: 560ms;
  --duel-motion-screen: 420ms;

  --duel-ease-out: cubic-bezier(.16, 1, .3, 1);
  --duel-ease-spring: cubic-bezier(.2, 1.3, .3, 1);
  --duel-ease-mark: cubic-bezier(.2, .8, .2, 1);
  --duel-ease-linear: linear;

  --duel-stagger-avatar: 55ms;
  --duel-stagger-result: 85ms;
}
```

Budget :

- micro-feedback : 100–240 ms ;
- événement social : 300–420 ms ;
- transition d'écran : 360–560 ms ;
- séquence automatique totale : 1,8 seconde maximum ;
- jamais plus de quatre lignes staggered individuellement ; les suivantes entrent
  ensemble pour ne pas pénaliser un joueur ayant dix duels.

## 5. Contrat DOM et classes d'état

### 5.1 Invitation froide

```html
<main class="duel-invitation"
      data-state="available"
      data-origin="cold">
  <div class="duel-invitation-friends">…</div>
  <strong class="duel-invitation-score">87</strong>
  <p class="duel-invitation-promise">…</p>
  <button class="btn btn-gold duel-invitation-play">Relever le défi</button>
</main>
```

États autorisés :

```text
data-state="available | claiming | claimed | taken | expired | revoked | error"
data-origin="cold | named | returning"
```

Le score, la promesse et le CTA ne démarrent jamais à `opacity: 0`. Le mouvement est
une amélioration après rendu, pas une condition d'accès au contenu.

### 5.2 Shell du quiz

```html
<aside class="duel-campus-rail"
       data-state="collapsed"
       data-event="idle">
  <div class="duel-campus-friends">…</div>
  <p class="duel-campus-callout">…</p>
</aside>
```

États autorisés :

```text
data-state="entering | expanded | collapsed | hidden"
data-event="idle | incoming | score-crossed | friend-ahead | score-arrived | score-shared"
```

### 5.3 Ami

```html
<article class="duel-friend"
         data-friend-id="42"
         data-position="ahead"
         data-focus="true">
```

Positions :

```text
leading | trailing | tied | waiting | unresolved
```

### 5.4 Écran du Campus

```html
<section id="duel_campus_result_<run-id>"
         class="duel-campus-screen"
         data-state="ready | entering | revealing | complete"
         data-next-desire="propagate | rematch | play">
```

### 5.5 Ligne résultat

```html
<article class="duel-result-row"
         data-outcome="victory | defeat | tie | waiting"
         data-reveal-index="0">
```

Les classes décrivent uniquement la présentation. `data-outcome` vient du serveur.

## 6. Orchestration Stimulus

Un seul contrôleur coordonne les classes de mouvement sur la landing, le quiz et
le Campus :

```text
app/javascript/controllers/duel_motion_controller.js
```

Responsabilités limitées :

- lire la séquence sérialisée par le serveur ;
- poser `data-state` et `data-event` ;
- écouter `animationend` / `transitionend` ;
- retirer les classes transitoires ;
- déclencher un cue SFX ou haptique nommé au bon battement ;
- permettre `skip()` sur tap, navigation ou mouvement réduit ;
- annoncer le résultat final dans une live region après la transition.

Le partage réseau et son instrumentation peuvent vivre dans un contrôleur de
comportement séparé. Ce contrôleur ne possède aucune timeline CSS et ne transforme
jamais un handoff en accusé de livraison.

Interdictions :

- pas de calcul du gagnant en JavaScript ;
- pas de chaîne de `setTimeout` pour chorégraphier l'écran ;
- pas de styles inline générés par JS, sauf l'index de stagger borné ;
- pas de second moteur de swipe ;
- pas de dépendance à la fin d'une animation pour enregistrer un résultat serveur.
- pas d'émission de `human_opened` dépendante d'une animation ; la mesure de visibilité
  doit fonctionner même en mouvement réduit ou CSS désactivé.

La séquence avance par événements CSS. Un timeout de sécurité unique peut rendre
l'état final si `animationend` n'arrive pas, mais il ne constitue pas la timeline.

## 7. Chorégraphies par événement

### 7.1 Ouverture froide d'une invitation

Objectif : en moins de deux secondes, comprendre qui invite, quel score l'ami a posé
et quoi faire. Le contenu critique est présent avant le premier frame animé.

```text
0 ms    portrait, score, promesse et CTA déjà lisibles et CTA activé
80 ms   anneau des deux portraits : contraste .88→1
140 ms  score : translateY 4px→0, sans compteur artificiel
220 ms  trait de complicité se dessine localement
300 ms  reflet métallique unique sur le CTA, puis arrêt
```

Durée maximale : 420 ms. Aucun autoplay sonore, haptique, intro plein écran ou délai
avant clic. Un second rendu, un retour arrière ou `prefers-reduced-motion` affiche
directement l'état final.

### 7.2 Claim → identité légère → première question

Le bouton passe immédiatement à `data-state="claiming"` avec feedback de pression,
mais la navigation ne dépend d'aucun `animationend`.

- si une ficha existe, View Transition relie portrait et score au rail de `/jugar` ;
- si une identité légère est requise, le formulaire entre de 8 px maximum et conserve
  ami et score au-dessus ;
- après validation, le quiz remplace l'étape dans la même direction visuelle, sans Hub ;
- l'entrée multi-duels suivante absorbe le duel réclamé, sans deuxième cérémonie.

Budget de transition visuelle : 360 ms par navigation, skip immédiat au tap ou en
mouvement réduit. Une erreur réseau restaure le CTA et annonce le problème sans perdre
le token de reprise.

### 7.3 Entrée dans un run avec N duels

Objectif : anticipation, sans retarder la première question.

Timeline :

```text
0 ms    écusson du Campus : opacity 0→1, scale .92→1
70 ms   compteur « TON SCORE COMPTERA POUR 5 DÉFIS AMICAUX »
120 ms  portraits : entrée latérale, stagger 55 ms, maximum 4
700 ms  maintien lisible
1 050 ms rail expanded → collapsed
1 290 ms question totalement prioritaire
```

CSS :

```css
@keyframes duel-campus-enter {
  from { opacity: 0; transform: translateY(-.65rem) scale(.96); }
  to   { opacity: 1; transform: none; }
}

@keyframes duel-friend-enter {
  from { opacity: 0; transform: translateX(.75rem) scale(.9); }
  to   { opacity: 1; transform: none; }
}
```

Le rail ne doit jamais pousser la question par changement de hauteur : expanded et
collapsed vivent dans une couche réservée ou utilisent un conteneur de hauteur fixe.

### 7.4 Nouveau défi pendant le run

Objectif : informer sans interrompre.

```text
badge +N : scale .8→1.08→1
halo or : opacity 0→.45→0
callout après réponse : « 3 nouveaux défis · prochain run »
```

Durée : 320 ms. Aucun son si plusieurs défis arrivent pendant la lecture ; un seul
cue agrégé à la transition sûre suivante.

### 7.5 Changement d'ami focal

Objectif : déplacer l'attention, pas la disposition.

- ancien ami focal : scale `1 → .94`, opacity `1 → .72` ;
- nouvel ami focal : scale `.94 → 1`, anneau or `0 → 1` ;
- utiliser FLIP via View Transitions seulement si l'ordre DOM change ;
- sinon conserver l'ordre DOM et déplacer uniquement le marqueur focal.

Durée : 240 ms. Aucun reflow animé par `left`, `width` ou `margin`.

### 7.6 Le score rejoint puis dépasse celui d'un ami

Objectif : progrès, proximité et suspense partagé.

Séquence :

```text
les deux portraits se rapprochent de 4 px
un trait de lumière traverse le symbole commun
les deux valeurs s'alignent une respiration
callout « TU REJOINS CARMEN À 87 »
haptique doux au croisement
```

```css
@keyframes duel-score-cross {
  0%   { transform: translateX(0) scale(1); }
  55%  { transform: translateX(.65rem) scale(1.06); }
  100% { transform: translateX(0) scale(1); }
}

@keyframes duel-gold-sweep {
  from { transform: scaleX(0); transform-origin: left; opacity: 0; }
  35%  { opacity: 1; }
  to   { transform: scaleX(1); opacity: 0; }
}
```

Durée : 380 ms. Une seule exécution par ami et par run pour éviter le ping-pong
si le score provisoire change plusieurs fois autour de la même valeur.

### 7.7 Un ami pose son score

Objectif : anticipation chaleureuse.

- portrait : anneau bref de feuilles et d'or lorsque le score arrive ;
- valeur : roule d'un placeholder `…` vers le nombre par crossfade, pas par compteur
  fictif ;
- callout : `CARMEN A TERMINÉ · 91` ;
- rail revient au repos en 420 ms.

Si l'événement arrive pendant un choix, seule une pastille silencieuse change. La
révélation attend le settle.

### 7.8 Score du run verrouillé dans plusieurs duels

Objectif : puissance et compréhension du fan-out.

Séquence :

```text
score final pulse une fois
un trait d'or se divise vers les portraits
les portraits concernés passent successivement en « engagé »
compteur : « 87 PARTAGÉ DANS 5 DÉFIS »
```

Le trait divisé est un pseudo-élément CSS ou un SVG décoratif non sémantique. Il ne
doit pas générer un canvas ni une physique JavaScript.

Durée totale : 720 ms, quel que soit N. À partir du quatrième portrait, le compteur
`+N` absorbe la suite.

### 7.9 Cérémonie personnelle → État du Campus

La transition est déclenchée par l'unique CTA or `Voir le Campus`. Elle
n'est jamais automatique tant que le joueur lit son score personnel.

Utiliser l'API View Transitions lorsqu'elle existe :

```css
.street-ceremony-score { view-transition-name: run-score; }
.duel-campus-score      { view-transition-name: run-score; }

::view-transition-old(run-score),
::view-transition-new(run-score) {
  animation-duration: var(--duel-motion-screen);
  animation-timing-function: var(--duel-ease-out);
}
```

Chorégraphie :

```text
ancienne cérémonie : opacity 1→0, scale 1→.985
score : morph de sa position cérémonie vers le héros du Campus
nouveau Campus : opacity 0→1, translateY 14px→0
arche et portraits : apparition locale
```

Fallback sans View Transitions : crossfade de 320 ms entre deux régions stables du
même overlay. Aucun blanc intermédiaire, aucun retour au Hub.

### 7.10 Entrée de l'écran du Campus

Objectif : transformer un score en événement social.

```text
0 ms    forêt et passerelles apparaissent
80 ms   score commun se pose comme métal
170 ms  résumé « 2 amis derrière · 1 devant · 1 même score · 2 attentes »
320 ms  première ligne commence sa révélation
```

Le CTA final est présent dans le DOM dès le début, mais prend sa pleine opacité à
`data-state=complete`. Un tap pendant la séquence appelle `skip()` et affiche l'état
complet immédiatement.

### 7.11 Révélation « tu es devant »

- les deux portraits entrent depuis leur côté ;
- les scores se posent sans compteur artificiel ;
- le lien commun reçoit un sweep or ;
- `TU ES DEVANT` apparaît en encre sur Light ou crème sur Dark ;
- une feuille métallique monte de 6 px puis se stabilise ;
- haptique doux et cue `result_ahead` au moment du sweep.

Durée : 460 ms.

### 7.12 Révélation « ton ami est devant »

- mêmes portraits et mêmes scores : pas de traitement humiliant ;
- l'ami en tête reçoit l'or, le joueur reste à pleine lisibilité ;
- le texte `CARMEN EST DEVANT` remplace tout vocabulaire de défaite ;
- la prochaine envie `Rejouer quand tu veux` entre discrètement après le résultat.

Durée : 420 ms. Aucun shake, flash rouge plein écran ou son d'échec punitif.

### 7.13 Révélation d'un même score

- les portraits convergent symétriquement ;
- le symbole de lien devient `=` par crossfade ;
- un anneau or commun se dessine ;
- libellé `MÊME SCORE · BIEN JOUÉ À VOUS DEUX`.

Durée : 420 ms.

### 7.14 Score en attente

- score du joueur visible ;
- côté ami reste `…` ;
- un reflet de feuille indique « attente vivante », sans boucle distrayante ;
- après 1,2 seconde, toute animation s'arrête ;
- texte explicite `ON ATTEND CARMEN`.

Pas de spinner infini.

### 7.15 Résolution multiple

Pour N résultats :

- révéler individuellement les quatre événements les plus importants ;
- afficher le reste en groupe avec fade/translate commun ;
- ne jouer qu'un seul cue `duel_multi_resolve` ;
- afficher le résumé dès le départ pour que l'information ne dépende pas de la
  séquence ;
- durée totale plafonnée à 1,8 seconde ;
- toute interaction termine la séquence.

### 7.16 Revanche amicale activée

Objectif : prochaine envie, sans prétendre choisir un pack.

- les deux portraits tournent légèrement vers le centre ;
- le symbole commun reçoit une lueur douce ;
- un trait relie les deux joueurs ;
- texte `REVANCHE AMICALE · TON PROCHAIN SCORE COMPTE` ;
- aucun artwork ou nom de pack n'apparaît.

Durée : 380 ms.

### 7.17 Accusés par canal

Deux timelines partagent l'anatomie, jamais les libellés :

```text
Noche nommé : envoyé → reçu → vu → accepté
lien externe : partage prêt → lien ouvert → réclamé
```

- le segment suivant se remplit de gauche à droite ;
- le point passe de contour à métal or ;
- le libellé change par crossfade ;
- aucune étape précédente ne se désactive visuellement ;
- une mise à jour Turbo ne rejoue que le dernier segment ajouté ;
- `partage prêt` ne saute jamais visuellement vers `reçu` ;
- le préchargement d'un aperçu ne déclenche aucun segment humain.

Durée : 220 ms. Pas de son pour reçu, vu ou lien ouvert ; haptique légère seulement
pour accepté/réclamé si le challenger regarde déjà l'écran.

### 7.18 Handoff de partage honnête

Le navigateur système possède sa propre feuille : Noche anime uniquement le bouton
avant et après son retour.

```text
press          métal descend de 1 px
share pending  libellé stable, indicateur local non bloquant
handoff natif  « Partage remis à l'app choisie »
copie          « Lien copié »
annulation     retour silencieux à l'état idle
échec          fallback copie ou message d'erreur actionnable
```

Pas de confettis, portrait qui « part » vers Carmen, coche `reçu` ou son de livraison.
Le feedback disparaît après lecture mais l'invitation reste accessible depuis la boîte.

### 7.19 Invitation prise, expirée ou révoquée

Objectif : transformer une impasse potentielle en prochaine envie sans faire croire
que le duel reste disponible.

- les deux portraits restent visibles mais leur trait de connexion s'éteint en 180 ms ;
- le score reste lisible comme contexte, jamais barré ou secoué ;
- le verdict d'état apparaît directement ;
- l'unique CTA or devient `Lancer un défi amical` ou `Jouer`, selon la projection serveur ;
- aucune couleur d'erreur plein écran ni animation punitive.

### 7.20 Résultat acquis → propagation

Quand `data-next-desire="propagate"`, le score fini devient l'objet partageable :

```text
0 ms    résultat et lien amical entièrement lisibles
120 ms  médaillon du score reçoit un sweep or unique
220 ms  trait court du score vers le sceau de partage
320 ms  CTA « Inviter un ami » atteint sa pleine emphase
```

Le CTA est présent et activable dès 0 ms. La revanche reste une action calme, jamais
un second CTA or. Après handoff, l'écran indique seulement l'état réel décrit en 7.18.
Le mouvement réduit conserve la hiérarchie sans sweep ni translation.

## 8. Stagger borné

Le serveur peut fournir `data-reveal-index`, mais le CSS borne l'index :

```css
.duel-result-row { --reveal-index: 0; }
.duel-result-row[data-reveal-index="1"] { --reveal-index: 1; }
.duel-result-row[data-reveal-index="2"] { --reveal-index: 2; }
.duel-result-row[data-reveal-index="3"] { --reveal-index: 3; }

.duel-campus-screen[data-state="revealing"] .duel-result-row {
  animation-delay: calc(var(--reveal-index) * var(--duel-stagger-result));
}
```

Tout index supérieur à 3 utilise `3`. Une personne ayant dix duels n'attend donc pas
dix animations successives.

## 9. Mouvement réduit

```css
@media (prefers-reduced-motion: reduce) {
  .duel-campus-rail,
  .duel-friend,
  .duel-campus-callout,
  .duel-campus-screen,
  .duel-result-row,
  .duel-receipt-step {
    animation: none !important;
    transition-duration: 1ms !important;
    scroll-behavior: auto !important;
  }
}
```

Comportement réduit :

- état final immédiat ;
- changement de bordure, texte et icône conservé ;
- aucune information transmise uniquement par mouvement ;
- aucun autoplay sonore déclenché par une animation supprimée ;
- live region annoncée une seule fois.

## 10. Performance mobile

- animer `transform` et `opacity` ;
- réserver la géométrie du rail pour éviter le layout shift ;
- ne pas animer `height`, `top`, `left`, `box-shadow` massif ou `backdrop-filter` ;
- `will-change` uniquement pendant `[data-state=entering]` ou `[data-event]`, puis le
  retirer ;
- limiter les particules à des pseudo-éléments locaux ;
- aucune vidéo ou canvas pour un dépassement ;
- maximum quatre avatars animés simultanément ;
- vérifier 60 fps sur un appareil Android milieu de gamme, pas seulement sur desktop.

## 11. Safe areas et collisions

Le rail :

- vit sous le HUD ;
- reste au-dessus de la feuille sans la recouvrir ;
- n'approche jamais le dock inférieur ;
- utilise `env(safe-area-inset-top)` et les dimensions réelles du HUD ;
- conserve un z-index unique documenté dans l'échelle de chrome ;
- ne dépend pas d'une valeur magique répétée dans plusieurs media queries.

L'écran du Campus :

- possède son propre scroller interne entre HUD et dock ;
- garde le résumé et le premier défi amical dans le premier viewport ;
- garde le CTA final accessible sans masquer la dernière ligne ;
- accepte 1, 5 et 10 résultats sans débordement horizontal.

## 12. Synchronisation SFX et haptique

Les battements sont nommés dans la séquence serveur :

```text
campus_enter
score_crossed
score_shared
result_ahead
result_behind
result_tie
multi_resolve
rematch_active
```

Stimulus déclenche le cue sur `animationstart` de l'élément porteur, pas avec un
timeout approximatif. `prefers-reduced-motion` ne coupe pas automatiquement le son,
mais le réglage mute de Noche reste autoritaire.

Une résolution multiple produit un cue et une haptique, pas N.

## 13. Tests d'animation

### Structure

- chaque état d'invitation produit le bon `data-state` sans masquer score ou CTA ;
- `data-next-desire` vient de la projection serveur ;
- chaque événement serveur produit le bon `data-event` ;
- chaque outcome produit le bon `data-outcome` ;
- les ids Turbo restent stables ;
- aucune classe legacy n'est rendue.

### CSS calculé

- rail sous le HUD et au-dessus de la question ;
- z-index supérieur au contenu, inférieur aux dialogues système ;
- durée totale ≤ 1,8 seconde ;
- stagger borné à quatre ;
- seules `transform` et `opacity` animent les grands composants ;
- mode réduit : durée effective quasi nulle et état final visible.
- landing froide : CTA interactif dès le premier rendu et aucun contenu critique à
  `opacity: 0` ;
- aucun sélecteur d'animation ne transforme `share_handoff` en reçu ou vu.

### Navigateur

- ouverture froide avec invitation disponible, prise, expirée et révoquée ;
- claim direct puis claim avec ficha légère, sans passage par le Hub ;
- partage natif réussi, annulé, échoué puis fallback copie ;
- retour de feuille de partage sans faux accusé ni confettis ;
- propagation après premier résultat et revanche en action secondaire ;
- capture de l'entrée avec 1, 5 et 10 duels ;
- capture d'un rapprochement puis d'un passage devant ;
- transition cérémonie → Campus ;
- devant, derrière, même score et attente ;
- résolution multiple ;
- tap pour passer la séquence ;
- Turbo update pendant état collapsed ;
- rotations portrait/paysage sans animation fantôme ;
- arrière-plan puis retour sans rejouer un résultat déjà vu.

### Audit de suppression

- aucun écran ou CSS de landing mono-duel restant après cutover ;
- aucun feedback legacy « envoyé/reçu » déclenché par la seule feuille de partage ;
- aucune référence aux anciens keyframes ;
- aucun doublon de sélecteur entre `application.css` et `duel_campus.css` ;
- aucun bloc de cascade lock ;
- aucune capture ou spec visant `_street_duel_ribbon` ou `_duel_result` ;
- aucun contrôleur Stimulus mono-duel inutilisé.

## 14. Ordre d'implémentation

1. valider les écrans M01–M25, la feuille de composants et les dix storyboards du
   gate 12.5 du plan parent ;
2. créer les tokens, le shell `duel_campus.css` et le contrôleur de mouvement unique ;
3. construire la landing froide statique et tous ses états sans animation ;
4. construire claim, reprise de ficha et transition vers `/jugar` ;
5. brancher le partage honnête et ses fallbacks sans timeline de livraison ;
6. construire le rail statique dans les deux thèmes ;
7. brancher tous les états serveur sans animation ;
8. ajouter mouvement réduit et tests ;
9. ajouter entrée, focus et événements de quiz ;
10. construire l'écran du Campus et la propagation statiques ;
11. ajouter View Transition, fallback, révélations et skip ;
12. synchroniser seulement les SFX/haptiques autorisés ;
13. supprimer en une fois anciens partials, contrôleurs, sélecteurs, keyframes et specs ;
14. vérifier conversion, performances et captures sur appareils réels.

## 15. Critères de sortie

- chaque mouvement exprime un changement métier réel ;
- une invitation froide est comprise et actionnable avant la fin de son animation ;
- le claim mène à la question sans Hub ni cérémonie intermédiaire ;
- annulation, handoff, ouverture et claim ont quatre feedbacks honnêtes distincts ;
- aucune animation ne masque ou ne retarde une question ;
- la transition cérémonie → Campus reste sous contrôle du joueur ;
- cinq résultats sont compris avant la fin de la séquence ;
- dix résultats ne créent pas dix secondes d'attente ;
- mouvement réduit conserve toute l'information ;
- Light et Dark utilisent la même anatomie ;
- aucun CSS, keyframe, contrôleur ou spec legacy ne subsiste ;
- les captures 390×844, iPad et desktop passent sans collision ;
- la boucle donne envie de lancer une revanche ou une nouvelle invitation selon la
  prochaine envie serveur, sans imposer de pack.

## 16. Correspondance avec l’implémentation

- `duel_campus.css` possède seul les écrans, rail, notification, résultat et motion du
  Campus ; `application.css` ne contient plus les sélecteurs ou keyframes mono-duel.
- `duel_motion_controller.js` pose uniquement des états de présentation, utilise
  `IntersectionObserver` et les fins CSS, et expose un `skip()` sans timeline réseau.
- Une landing froide affiche score, promesse et CTA avant toute animation ; les sheets
  ne passent jamais à `opacity: 0`.
- `prefers-reduced-motion` conserve l’état final, les textes et les actions.
- Le rail reste en couche absolue sous le HUD, et la notification reste en zone haute
  au-dessus du dock.
- La QA calculée et les captures 390×844, 768×1024 et 1440×900 sont validées, avec
  captures dédiées invitation froide, destinataire connu, résultat et mouvement réduit.
- Sur une invitation mobile avec dock, la zone d’actions devient un plateau fixe
  au-dessus du dock. Elle ne dépend d’aucun ancêtre transformé et sa géométrie est
  couverte par un test : règle au-dessus des actions, actions au-dessus du dock.
