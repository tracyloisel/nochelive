# Noche Live — plan intégral de refonte

**Statut :** plan directeur d’implémentation
**Date :** 28 août 2026
**Références visuelles :** [`tmp/night-shots/temple-mockups/`](../tmp/night-shots/temple-mockups/)
**Ordre de décision :** expérience → interface → direction artistique → validation

---

## 1. Ambition

Refondre l’intégralité de la soirée Noche Live pour qu’elle soit vécue comme un **game show biblique premium**, et non comme une application web à laquelle on se connecte avant de remplir des écrans administratifs.

La technologie doit disparaître derrière trois sensations :

1. **Immédiateté** — je touche Live et je suis déjà dans la soirée.
2. **Présence** — je joue avec les personnes dans la salle, même depuis chez moi.
3. **Spectacle partagé** — chaque écran raconte exactement le même moment, adapté au rôle qui le regarde.

La priorité absolue est l’élimination des frictions. Un code de session, une sélection d’équipe répétée, un bouton « prêt », un bouton « OK » après chaque réponse ou une création de profil avant de jouer sont considérés comme des défauts de conception.

---

## 2. Résultat attendu

À la fin de la refonte :

- un joueur connu rejoint la soirée en **un toucher** ;
- un nouveau joueur donne uniquement son **prénom**, puis joue ;
- l’équipe habituelle est retrouvée automatiquement ;
- le parcours normal n’affiche aucun code, PIN, QR ou URL à recopier ;
- le joueur en salle utilise son téléphone comme un contrôleur et regarde la salle ;
- le joueur à distance dispose d’une expérience autonome de niveau A ou B ;
- le présentateur contrôle tout le rythme avec une seule action principale ;
- le spectateur mobile peut suivre et réagir sans devenir un faux joueur ;
- la TV reste un spectacle 16:9 sans commandes tactiles ni feuilles de formulaire ;
- chaque révélation apporte feedback, score, VFX, SFX et progression sans clic administratif ;
- la finale peut encore changer le podium et se conclut par une cérémonie ;
- toutes les interfaces restent utilisables de 320 px à un grand écran 4K ;
- `prefers-reduced-motion`, les safe areas, le zoom texte et les contrastes sont pris en charge ;
- les quatre langues — espagnol, portugais brésilien, français et anglais — ont une voix naturelle.

---

## 3. Principes non négociables

### 3.1 Une soirée, cinq points de vue

Le produit distingue cinq expériences :

| Point de vue | Fonction essentielle | Test des deux secondes |
|---|---|---|
| Joueur en salle | Contrôler une action physique ou vocale | « Je dois buzzer / voter / montrer / crier. » |
| Joueur à distance | Jouer avec assez de contexte pour être autonome | « Je comprends la scène et je peux agir maintenant. » |
| Présentateur | Donner le rythme | « Cette unique action fait avancer tout le monde. » |
| Spectateur mobile | Suivre et encourager | « Je regarde et je peux réagir sans perturber le jeu. » |
| TV / diffusion | Raconter le spectacle | « Toute la salle comprend l’enjeu à plusieurs mètres. » |

Le spectateur mobile est ajouté explicitement au modèle d’expérience. Il ne remplace ni le joueur à distance ni la TV.

### 3.2 Une scène narrative partagée

Pour un même état de manche, tous les sièges utilisent :

- la même illustration narrative ;
- la même phase ;
- le même compte à rebours ;
- le même événement de révélation ;
- le même classement source.

Seuls changent la quantité de contexte, le geste disponible et la densité du HUD.

### 3.3 L’or possède une fonction

L’or est réservé à :

- l’objet Buzz ;
- l’emblème ;
- le score comme objet métallique ;
- l’état sélectionné ;
- le trophée ;
- l’unique action principale ;
- un accent de progression ou de récompense.

Les titres restent ivoire sur Celestial Dark et encre sur Celestial Light. Aucun empilement de titres dorés, aucun jaune plat, aucun texte doré posé directement dans le faisceau lumineux.

### 3.4 Le décor détermine le thème

Le thème n’est pas un réglage utilisateur.

- **Celestial Light** : ivoire, ciel, verre, ombres douces, architecture lumineuse.
- **Celestial Dark** : bleu nuit, noir profond, surfaces translucides, lumière volumétrique, particules.

Le choix vient du manifeste de l’illustration et du moment narratif. Les composants conservent les mêmes noms et changent uniquement de tokens.

### 3.5 Une boucle, jamais un écran mort

Chaque séquence doit compléter :

> anticipation → action → suspense → résultat → feedback → récompense → prochaine envie

Une attente passive doit au minimum montrer un état vivant et se résoudre automatiquement. Une révélation ne demande jamais de cliquer sur « OK ».

---

## 4. Diagnostic de l’expérience actuelle

### 4.1 Frictions d’accès

- Le code de soirée reste visible dans plusieurs interfaces.
- Le parcours de participation peut demander trop tôt une identité complète, une famille ou une année.
- Le joueur en salle doit parfois choisir ou recréer une équipe déjà connue.
- L’écran créé après l’ouverture d’une soirée ralentit le présentateur au lieu de l’envoyer à sa console.
- La destination Live n’est pas toujours résolue depuis le contexte déjà connu : paroisse, soirée active, joueur courant et appareil.

### 4.2 Confusion entre les sièges

- Le mode Watch mélange le spectateur mobile et la TV.
- Le joueur à distance peut être relégué à une attente au lieu de jouer.
- Certaines surfaces dupliquent un même layout alors que les verbes sont différents.
- La TV peut hériter d’éléments tactiles ou d’une composition de téléphone.

### 4.3 Style fragmenté

- Les écrans Live ne possèdent pas encore un moteur de thème cohérent dérivé de l’artwork.
- L’illustration, le chrome et les états finaux ne forment pas toujours un même arc lumineux.
- Le pipeline d’illustration ne produit pas systématiquement les cadrages portrait et 16:9 nécessaires.
- Des composants issus d’écrans SaaS ou de formulaires réapparaissent dans des moments de jeu.

### 4.4 Rythme et feedback

- Des boutons de confirmation ralentissent la soirée.
- Certains états de révélation ou d’attente n’offrent pas assez de tension, de récompense ou de prochaine envie.
- Les animations ne sont pas encore contractualisées par rôle et par transition.

---

## 5. Architecture cible du parcours d’entrée

### 5.1 La porte unique Live

Le bouton Live du hub ne mène jamais vers un catalogue intermédiaire si une destination plus directe est connue.

Ordre de résolution :

1. joueur déjà rattaché à une soirée active → reprendre exactement son siège ;
2. personne reconnue dans une paroisse avec une soirée active → proposer **Entrer maintenant** ;
3. nouveau visiteur arrivant par une porte joueur → demander uniquement le prénom ;
4. visiteur arrivant par une porte spectateur → ouvrir immédiatement le spectateur mobile ;
5. responsable de la soirée → ouvrir la console présentateur ;
6. aucune soirée active, paroisse connue → ouvrir la page de la paroisse ;
7. aucune paroisse connue → ouvrir la recherche de paroisse.

### 5.2 Reprise d’identité

Écran de référence : `mockup-night-entry-recognized.png`.

- Une identité connue est sélectionnée par défaut.
- **Entrer maintenant** est la seule action principale.
- « Changer de personne » et « Solo mirar » restent des liens calmes.
- Aucune confirmation supplémentaire après le toucher principal.

### 5.3 Première visite

Écran de référence : `mockup-night-entry-first-time.png`.

- Une seule information bloquante : le prénom.
- Aucun e-mail, mot de passe, nom de famille, date de naissance ou rattachement familial.
- Le joueur est créé comme participant de soirée, pas comme profil complet.
- La création ou l’enrichissement du profil est proposé après la finale et reste facultatif.

### 5.4 Attribution automatique de l’équipe

Ordre d’attribution :

1. équipe de cette même soirée déjà enregistrée sur l’appareil ;
2. équipe habituelle de la personne dans la paroisse ;
3. seule équipe en salle disponible ;
4. équipe avec la capacité la plus faible ou règle d’équilibrage définie par la soirée ;
5. choix manuel seulement si le système ne peut pas prendre une décision sûre.

Le changement d’équipe reste disponible comme action secondaire. Il n’est jamais une étape obligatoire.

### 5.5 Suppression des codes

Le plan supprime les codes de l’interface et du parcours normal, pas nécessairement le jeton technique utilisé dans les URL existantes.

- masquer le code dans l’entrée, le lobby, la console et la TV ;
- conserver temporairement les routes à jeton comme compatibilité pour les anciens liens ;
- transformer les anciens écrans de saisie en redirections intelligentes ;
- ne jamais utiliser un code comme identité visible de la soirée ;
- ajouter télémétrie et date de retrait avant de supprimer définitivement les routes historiques.

### 5.6 Ouverture d’une soirée par le présentateur

- La création redirige directement vers la console.
- La TV s’ouvre depuis une action calme « Abrir pantalla TV ».
- Aucun écran de succès intermédiaire avec code à recopier.
- Le lobby indique seulement les éléments utiles : TV connectée, équipes, joueurs salle, joueurs maison.

---

## 6. Parcours cible par phase

### 6.1 Avant la soirée

#### Joueur en salle

- entrée directe ;
- équipe auto-attribuée ;
- confirmation « Ya estás dentro » ;
- coéquipiers visibles ;
- démarrage automatique, aucun bouton « prêt ».

Référence : `mockup-night-sala-lobby-auto-team.png`.

#### Joueur à distance

- entrée directe dans le siège Casa ;
- test silencieux de connexion ;
- rappel bref qu’il recevra toute la question sur son téléphone ;
- démarrage automatique.

#### Présentateur

- état « Todo está listo » ;
- TV, équipes et joueurs résumés en trois confirmations ;
- une action dorée : **Comenzar la noche** ;
- participants et réglages dans un desk secondaire.

Référence : `mockup-night-presenter-lobby-ready.png`.

#### Spectateur mobile

- entrée anonyme et immédiate ;
- scène d’attente ;
- aucun roster et aucun score personnel ;
- réactions disponibles seulement quand la soirée commence.

#### TV

- scène d’anticipation pleine largeur ;
- titre de la soirée ;
- équipes et nombre de joueurs ;
- aucun QR, code ou mode d’emploi.

Référence : `mockup-night-tv-lobby-ready.png`.

### 6.2 Ouverture d’une manche

Toutes les surfaces reçoivent un même événement d’ouverture contenant :

- identifiant de manche ;
- phase et index ;
- artwork ;
- thème Light/Dark ;
- durée et heure de fin ;
- score courant ;
- cue sonore nommé.

Le changement de scène commence au même instant visuel, avec une tolérance de synchronisation définie dans la QA.

### 6.3 Action de manche

#### Joueur en salle

Référence : `mockup-night-sala-buzz-temple.png`.

- écran en trois bandes : HUD, scène, contrôleur ;
- gros médaillon Buzz ou action physique équivalente ;
- score compact sur la scène ;
- aucune longue explication ;
- vibration et cue sonore au contact ;
- état verrouillé immédiatement après l’action.

#### Joueur à distance

Référence : `mockup-night-casa-quiz-temple.png`.

- même scène et même chronologie ;
- question complète ;
- réponses pleine largeur ;
- état sélectionné par bordure dorée et étoile ;
- confirmation immédiate sans bouton supplémentaire ;
- indicateur social discret : la salle joue elle aussi.

#### Présentateur

Référence : `mockup-night-presenter-temple.png`.

- scène dominante ;
- contexte suffisant pour parler sans lire un script ;
- une seule action dorée correspondant à la phase : fermer, révéler, avancer ;
- « Más » ouvre pause, fin, interventions et réglages ;
- desk en aperçu pour réponses et classement.

#### Spectateur mobile

Référence : `mockup-night-spectator-mobile-celestial-dark.png`.

- scène et question ;
- classement compact ;
- réactions discrètes, accessibles au pouce ;
- aucun choix de réponse, aucun XP, aucune équipe implicite.

#### TV

Référence : `mockup-night-watch-temple.png`.

- scène 16:9 ;
- titre et question courts ;
- timer très lisible ;
- un seul bandeau de score ;
- aucun contrôle tactile, aucune feuille, aucun menu.

### 6.4 Verrouillage et suspense

- l’action joueur devient physiquement indisponible ;
- la scène se calme légèrement ;
- le timer disparaît ou se fige sans clignotement agressif ;
- le présentateur voit le nombre de réponses reçues ;
- la TV ne révèle encore rien ;
- Casa voit que sa réponse est enregistrée ;
- une brève respiration précède la révélation.

### 6.5 Révélation

#### Joueur

Référence : `mockup-night-player-reveal-correct.png`.

Ordre visuel :

1. réponse révélée ;
2. feedback personnel ;
3. gain de points ;
4. mouvement du score ;
5. explication narrative courte ;
6. progression automatique vers la scène suivante.

Aucun bouton « OK » ou « Continuer ».

#### TV

Référence : `mockup-night-tv-reveal-correct.png`.

- la réponse devient l’objet central ;
- l’équipe récompensée est annoncée ;
- le classement se met à jour dans le bandeau inférieur ;
- la narration reste dominante ;
- l’avancement automatique est suggéré par une ligne lumineuse.

#### Présentateur

- l’action principale devient **Siguiente escena** quand la révélation a eu le temps minimum requis ;
- un garde-fou empêche un double déclenchement ;
- le desk permet de vérifier le classement sans créer une seconde action forte.

#### Spectateur

- la même réponse et le même classement que la TV ;
- réactions temporairement amplifiées ;
- aucune personnalisation de points.

### 6.6 Finale

La dernière manche :

- possède des points suffisants pour changer le podium ;
- fait se lever ou agir la salle ;
- donne à Casa un enjeu équivalent ;
- verrouille les scores avant la cérémonie ;
- sépare l’anticipation du dévoilement.

#### Présentateur

Référence : `mockup-night-presenter-finale-ready.png`.

- résultats prêts, trophée encore voilé ;
- une action : **Mostrar ganadores** ;
- aucune action concurrente.

#### TV

Référence : `mockup-night-tv-finale.png`.

- passage de la nuit à l’aube ;
- trophée comme objet héroïque ;
- nom, emblème et score de l’équipe gagnante ;
- podium secondaire ;
- phrase de clôture communautaire.

#### Joueur

Référence : `mockup-night-player-finale.png`.

- victoire de l’équipe d’abord ;
- contribution personnelle ensuite ;
- une sortie : **Volver al barrio** ;
- partage secondaire ;
- création de profil facultative pour un invité.

#### Spectateur

Référence : `mockup-night-spectator-finale.png`.

- podium et victoire ;
- contribution exprimée par les réactions, jamais par de faux XP ;
- une sortie claire.

---

## 7. Direction artistique et système de thème Live

### 7.1 Manifeste de scène

Chaque manche doit déclarer ou résoudre :

- `theme_family` : `celestial_light` ou `celestial_dark` ;
- `atmosphere` : nuit royale, feu, tempête, aube, etc. ;
- artwork portrait ;
- artwork 16:9 ;
- point focal et zone de texte sûre ;
- intensité des particules ;
- couleur de scrim ;
- cue sonore ;
- comportement de transition.

Le fallback doit rester cohérent et ne jamais choisir un thème selon une préférence utilisateur.

### 7.2 Pipeline d’illustration

Le générateur média doit :

1. lire le style global de la soirée ;
2. fusionner ce style avec la description propre à la manche ;
3. produire une image maître sans UI ;
4. produire au minimum un cadrage portrait 9:16 et un cadrage paysage 16:9 ;
5. préserver personnages, costumes, heure, palette et direction du faisceau ;
6. enregistrer le point focal et les safe zones ;
7. refuser les bâtiments modernes lorsque la scène appartient au monde biblique ;
8. lancer un contrôle visuel avant l’intégration.

Les mockups sont des références de composition, pas des images à découper pour fabriquer l’artwork final.

### 7.3 Tokens Live

Introduire une couche de tokens sémantiques, par exemple :

- `--live-bg`, `--live-surface`, `--live-surface-strong` ;
- `--live-type`, `--live-type-soft`, `--live-line` ;
- `--live-metal`, `--live-metal-highlight`, `--live-metal-shadow` ;
- `--live-scrim-top`, `--live-scrim-bottom`, `--live-scrim-board` ;
- `--live-focus`, `--live-success`, `--live-danger` ;
- `--live-scene-focus-x`, `--live-scene-focus-y` ;
- `--live-phone-column`, `--live-tv-safe` ;
- `--live-motion-fast`, `--live-motion-base`, `--live-motion-scene`.

Aucun écran ne doit définir des couleurs de thème arbitraires à l’intérieur de son composant.

### 7.4 Typographie et iconographie

- serif expressive pour titres narratifs et cérémonies ;
- sans-serif très lisible pour commandes, timer et microcopie ;
- taille minimale de 14 px sur téléphone, augmentée selon le viewport ;
- chiffres de score traités comme objets, avec chiffres tabulaires ;
- pictogrammes simples, nommés et accompagnés de texte lorsqu’ils ne sont pas universels ;
- aucune rangée de boutons mystérieux uniquement iconographiques.

---

## 8. Architecture d’interface

### 8.1 Racines stables

Conserver des identifiants stables pour les remplacements temps réel et les View Transitions :

- `#night_play` ;
- `#night_presenter` ;
- `#night_spectator` ;
- `#night_watch`.

### 8.2 Composants partagés

Créer ou consolider :

- `live-scene` — image, focal point, scrims et VFX ;
- `live-wordmark` — lockup compact ;
- `live-progress` — ticks uniquement pendant une manche ;
- `live-timer` — objet timer et halo ;
- `live-score-object` — score métallique ;
- `live-scoreboard-strip` — classement compact, TV et spectateur ;
- `live-team-crest` — emblème et nom ;
- `live-primary-action` — unique CTA doré ;
- `live-quiet-action` — action secondaire ;
- `live-buzz-medallion` — contrôleur salle ;
- `live-choice` — réponse Casa ;
- `live-stage-desk` — desk présentateur ;
- `live-reaction` — réaction spectateur ;
- `live-ceremony` — finale et podium.

Les composants partagent leur sémantique et leurs tokens, pas nécessairement leur composition.

### 8.3 États obligatoires

Chaque composant interactif doit définir :

- idle ;
- hover lorsque pertinent ;
- pressed ;
- focus-visible ;
- loading ;
- success ;
- failure ;
- disabled/locked ;
- reconnecting ;
- offline ;
- reduced-motion.

---

## 9. Responsive et media queries

### 9.1 Stratégie

Le responsive ne consiste pas à réduire uniformément une maquette. Il préserve la priorité du rôle :

- contrôleur salle toujours atteignable au pouce ;
- question Casa toujours lisible sans masquer l’artwork ;
- CTA présentateur toujours visible avec le desk en aperçu ;
- réactions spectateur toujours secondaires ;
- TV toujours 16:9 et broadcast-safe.

### 9.2 Matrice de viewports

| Famille | Viewports minimaux à contrôler |
|---|---|
| Petit téléphone portrait | 320×568, 360×640 |
| Téléphone courant | 375×667, 390×844, 393×852 |
| Grand téléphone | 430×932 |
| Téléphone paysage | 667×375, 844×390, 932×430 |
| Tablette portrait | 768×1024, 820×1180 |
| Tablette paysage | 1024×768, 1180×820 |
| Ordinateur | 1280×720, 1366×768, 1440×900 |
| TV | 1920×1080, 2560×1440, 3840×2160 |

### 9.3 Règles téléphone portrait

- utiliser `100dvh` avec fallback sûr ;
- intégrer `env(safe-area-inset-*)` ;
- placer l’action principale dans la zone de pouce ;
- ne pas laisser le clavier couvrir le prénom ;
- garder l’artwork visible, même sur 568 px de haut ;
- condenser les éléments secondaires avant de réduire la taille de la commande principale ;
- masquer l’aide non essentielle sur les écrans très courts ;
- permettre le scroll uniquement sur les écrans de contenu, jamais sur le Buzz principal.

### 9.4 Téléphone paysage

- passer à une composition scène/action en deux colonnes lorsque la hauteur est insuffisante ;
- conserver le Buzz circulaire et non elliptique ;
- réduire les ticks ou utiliser une rail compacte ;
- garder les boutons hors des encoches et des zones gestuelles ;
- éviter que le timer recouvre le sujet de l’illustration.

### 9.5 Tablette et desktop

- limiter le téléphone de jeu à une arche centrale plutôt que d’étirer la feuille ;
- agrandir l’artwork autour de la colonne ;
- augmenter graduellement la typographie avec `clamp()` ;
- conserver la hiérarchie mobile ;
- sur présentateur, permettre un desk plus informatif sans créer de dashboard.

### 9.6 TV

- conteneur strictement 16:9 ;
- safe margin de diffusion ;
- aucun texte critique dans les 5 % périphériques ;
- tailles basées sur `vmin`/`clamp()` ;
- noms d’équipe capables de passer sur deux lignes sans déformer le score ;
- bandeau inférieur de hauteur stable ;
- cadrage guidé par le point focal du manifeste.

### 9.7 Zoom, texte long et langues

- tester à 200 % de zoom navigateur ;
- tester les chaînes françaises et portugaises plus longues ;
- interdire les hauteurs fixes sur les blocs textuels ;
- utiliser `minmax(0, 1fr)` et `overflow-wrap` pour les noms ;
- conserver les cibles tactiles même lorsque le texte enveloppe ;
- ne pas tronquer une consigne de jeu critique.

---

## 10. Plan d’animation et de transition

### 10.1 Principes

- le mouvement explique un changement d’état ;
- le mouvement narratif est plus lent que le feedback interactif ;
- une action pressée répond en moins de 100 ms ;
- les surfaces synchronisées partagent un même événement, mais pas forcément la même chorégraphie ;
- aucune animation ne bloque la prochaine action ;
- `prefers-reduced-motion` remplace les déplacements par des fondus courts ou aucun effet.

### 10.2 Durées de base

| Usage | Durée cible |
|---|---|
| Press / haptic visuel | 70–110 ms |
| Sélection de réponse | 160–220 ms |
| Entrée HUD / panneau | 240–360 ms |
| Changement de scène | 500–800 ms |
| Révélation | 900–1 400 ms en séquence |
| Cérémonie finale | 2 500–4 000 ms, non bloquante |

### 10.3 Entrée reconnue

1. apparition douce du décor ;
2. pulse Live discret ;
3. identité glissant de 8–12 px ;
4. reflet métallique unique sur **Entrar ahora** ;
5. pression : enfoncement léger, halo bref, transition vers lobby.

### 10.4 Première visite

- focus clavier sans déplacer brutalement la composition ;
- contour de saisie qui passe de hairline à focus doré ;
- validation locale immédiate ;
- bouton activé par une transition de matière, sans saut de layout.

### 10.5 Lobby joueur

- arrivée successive des coéquipiers ;
- halo respirant très lent autour de l’état d’attente ;
- aucune roue de chargement ;
- ouverture de manche : halo absorbé par le faisceau, puis transition de scène.

### 10.6 Lobby présentateur

- confirmations TV/équipes/Casa en cascade courte ;
- CTA qui devient actif seulement quand l’état minimum est atteint ;
- les arrivées tardives mettent à jour les nombres sans faire remonter tout le layout.

### 10.7 Joueur en salle

- ouverture : HUD, scène, puis médaillon qui monte depuis le bas ;
- Buzz idle : respiration métallique subtile ;
- pressed : compression + vibration ;
- envoyé : onde circulaire et verrouillage ;
- gagné/perdu : feedback distinct mais bienveillant ;
- ne pas répéter un pulse envahissant chaque seconde.

### 10.8 Joueur à distance

- choix en léger stagger ;
- sélection : bordure dorée tracée, étoile qui se pose ;
- verrouillage : les autres choix perdent du contraste ;
- résultat : tick/croix local, pourcentage éventuel, puis score.

### 10.9 Présentateur

- CTA séquentiel morphant de « Fermer » à « Révéler » puis « Suivant » ;
- desk tiré par geste avec snap `peek` / `mid` / `open` ;
- changement de phase confirmé par un signal visuel bref ;
- blocage anti-double-clic visible immédiatement.

### 10.10 Spectateur mobile

- réactions en particules limitées qui montent puis disparaissent ;
- compteur mis à jour sans secouer le layout ;
- classement interpolé lorsqu’une équipe change de place ;
- aucune vibration de joueur.

### 10.11 TV

- entrée de question par fondu de scène et lower-third ;
- timer par halo intégré, pas par clignotement ;
- verrouillage par respiration et silence ;
- révélation : réponse, équipe gagnante, score, puis classement ;
- transitions conçues pour rester lisibles en compression vidéo.

### 10.12 Finale

- ciel passant progressivement de la nuit à l’aube ;
- trophée dévoilé par lumière et matière ;
- nom du gagnant après le trophée, pas avant ;
- podium en cascade 3 → 2 → 1 ou selon la dramaturgie validée ;
- contenu interactif disponible sans attendre la fin de toute la cérémonie.

### 10.13 Mode mouvement réduit

- désactiver parallaxe, déplacements importants, particules et flash veils ;
- remplacer les morphs par des changements instantanés ou fondus ≤ 150 ms ;
- conserver les changements de couleur, texte et état ;
- ne pas couper le son automatiquement : le mute reste un réglage distinct.

---

## 11. Son et haptique

Le système existant de cues nommés reste l’unique source sonore. Aucun second AudioContext.

### 11.1 Carte des moments

| Moment | Cue / comportement |
|---|---|
| Entrée dans la soirée | cue chaleureux court, une fois |
| Ouverture de manche | `round_open` |
| Changement de question | `question_change` |
| Buzz / action physique | `buzzer_hit` + haptic téléphone |
| Verrouillage | `round_lock` |
| Révélation | `reveal` |
| Gain de points | `correct_gold` |
| Finale | `royal_fanfare` ou cue de cérémonie validé |

### 11.2 Règles

- les hits se superposent, les stingers se croisent, le bed se fond ;
- un cue ne doit avoir qu’un seul chemin de déclenchement ;
- pas de tick audio à chaque seconde ;
- le halo visuel porte la tension du compte à rebours ;
- la TV, le joueur et le présentateur suivent le même pulse ;
- le mute persiste sur l’appareil ;
- sons instrumentaux, chaleureux, sans voix, orgue ou agressivité de stade.

---

## 12. Localisation et ton

### 12.1 Source et stockage

- espagnol comme source de vérité ;
- toute nouvelle chaîne de chrome dans les fichiers de locales ;
- textes de manche dans les définitions de jeu et leurs traductions ;
- aucune phrase visible écrite directement dans un contrôleur ou service.

### 12.2 Ton par langue

- **es** : chaleureux, `tú` pour Casa, `vosotros` pour l’équipe ;
- **pt-BR** : brésilien naturel, `ala`, `equipe`, `você/vocês` ;
- **fr** : `tu` pour le joueur, `vous` pour l’équipe, ponctuation française ;
- **en** : soirée familiale chaleureuse, pas concours télévisé froid.

### 12.3 Critères

- aucun calque mécanique ;
- verbes courts et actionnables ;
- aucune chaîne manquante ;
- contrôleur de langue toujours disponible pendant le Live sans devenir une action dorée ;
- noms bibliques localisés ;
- tests de longueur et de retour à la ligne dans les quatre langues.

---

## 13. Accessibilité

- contrastes conformes WCAG AA au minimum ;
- cibles tactiles de 44×44 px minimum, Buzz nettement plus grand ;
- focus visible et ordonné ;
- annonces `aria-live` pour connexion, réponse enregistrée, révélation et score ;
- ne jamais coder correct/incorrect uniquement par couleur ;
- libellés accessibles pour son, réactions et contrôles iconographiques ;
- support clavier pour la console présentateur ;
- prévention du double envoi côté client et serveur ;
- compatibilité lecteurs d’écran sans annoncer chaque particule ;
- texte redimensionnable ;
- mouvement réduit ;
- la TV conserve une lisibilité suffisante pour enfants et personnes âgées.

---

## 14. Architecture technique proposée

### 14.1 Routage

Introduire une porte Live contextuelle et séparer explicitement :

- entrée joueur ;
- jeu ;
- présentateur ;
- spectateur mobile ;
- TV.

Les anciennes routes à code redirigent vers ces destinations tant que la télémétrie montre qu’elles sont utilisées.

### 14.2 Résolveur d’entrée

Créer un service unique chargé de déterminer :

- soirée active ;
- paroisse ;
- identité reconnue ;
- participant existant ;
- rôle ;
- équipe ;
- destination.

Ce service doit être idempotent et testé séparément. Les contrôleurs ne reproduisent pas cette logique.

### 14.3 Participant invité

Le participant temporaire :

- possède un prénom d’affichage ;
- peut jouer sans profil complet ;
- reçoit les scores de la soirée ;
- peut être converti en profil après la finale ;
- ne crée pas de doublon si l’utilisateur recharge ou se reconnecte ;
- expire ou est anonymisé selon la politique de données.

### 14.4 Séparation Watch / Spectator

- la TV ne crée pas de joueur spectateur ;
- le spectateur mobile ne partage pas le layout TV ;
- les deux consomment le même état de spectacle ;
- seules les réactions appartiennent au spectateur mobile ;
- l’ancienne route Watch est conservée comme alias ou redirection pendant la migration.

### 14.5 État Live

Définir un payload de rendu commun contenant au minimum :

- phase de soirée ;
- phase de manche ;
- horodatage serveur ;
- fin du timer ;
- contenu localisé ;
- média et manifeste de thème ;
- réponses/participation agrégées selon le rôle ;
- scores ;
- pulse SFX/VFX ;
- token d’idempotence de transition.

Chaque rôle dérive sa vue du même état sans exposer les réponses secrètes avant la révélation.

### 14.6 Temps réel et reconnexion

- Turbo/Cable reste le mécanisme de diffusion ;
- chaque remplacement conserve la racine stable ;
- au retour réseau, récupérer un snapshot autoritaire avant d’appliquer de nouveaux événements ;
- ignorer les pulses déjà consommés ;
- afficher un état « Reconnexion… » local, sans sortir le joueur de la soirée ;
- mettre en file une action critique seulement si l’idempotence serveur est garantie ;
- la TV ne doit jamais créer une nouvelle session en rechargeant.

### 14.7 Sécurité

- un lien sans code visible ne signifie pas une route publique sans contrôle ;
- séparer les capacités joueur, présentateur et TV ;
- protéger les actions présentateur par un claim/secret approprié ;
- ne jamais exposer la bonne réponse dans le DOM avant la révélation ;
- limiter et dédupliquer les réactions ;
- valider les transitions de phase côté serveur.

---

## 15. Fichiers et zones de travail probables

La liste exacte sera confirmée au début de l’implémentation, mais la refonte touchera principalement :

- `config/routes.rb` ;
- contrôleurs d’entrée, joueurs, jeu, présentateur et Watch ;
- services d’identité, de participation et de rounds ;
- vues `app/views/play/` ;
- vues `app/views/presenter/` ;
- vues `app/views/watch/` ;
- nouvelles vues spectateur ;
- composants partagés Live ;
- `app/assets/stylesheets/application.css` ou feuilles Live extraites ;
- contrôleurs Stimulus de stage, countdown, motion, press et réactions ;
- `config/games/*.yml` ;
- `config/media/chapel_world.yml` et manifestes associés ;
- pipeline `script/generate_story_media.rb` ;
- `config/media/sfx.yml` et mapping des cues si nécessaire ;
- locales `es`, `pt-BR`, `fr`, `en` ;
- tests contrôleurs, services, intégration, système et visuels.

Toute modification doit préserver les changements déjà présents dans le worktree ; aucune feuille de style partagée ne sera remplacée en bloc.

---

## 16. Ordre d’implémentation

### Lot 0 — Baseline et protection

- inventorier les modifications existantes ;
- capturer tous les écrans actuels aux viewports de référence ;
- figer les mockups comme références ;
- relever les temps et gestes du parcours actuel ;
- créer la matrice de tests et les seuils de comparaison visuelle.

**Sortie :** baseline reproductible, aucune régression cachée.

### Lot 1 — Accès sans code

- porte Live contextuelle ;
- reprise d’identité ;
- entrée prénom seul ;
- participant invité ;
- équipe automatique ;
- redirection directe du présentateur ;
- retrait des codes de l’interface ;
- compatibilité des anciens liens.

**Sortie :** joueur connu en un toucher, nouveau joueur en un champ.

### Lot 2 — Séparation des rôles

- spectateur mobile dédié ;
- TV dédiée sans création de participant ;
- destinations explicites ;
- payload Live commun ;
- permissions et reconnexion.

**Sortie :** cinq sièges cohérents, aucune confusion Watch/Casa.

### Lot 3 — Thème et scène partagés

- manifeste Live ;
- tokens Light/Dark ;
- composant scène ;
- cadrages portrait/TV ;
- correction du pipeline d’illustration ;
- intégration de la scène Salomon comme référence.

**Sortie :** une même histoire réellement partagée entre les sièges.

### Lot 4 — Interfaces de manche

Ordre conseillé :

1. joueur salle ;
2. joueur Casa ;
3. présentateur ;
4. TV ;
5. spectateur mobile.

Chaque siège est livré avec ses états idle, action, locked, reconnecting et error avant de passer au suivant.

**Sortie :** conformité aux cinq mockups de manche.

### Lot 5 — Révélation et finale

- révélation automatique ;
- animation des scores ;
- narration courte ;
- finale capable de renverser le podium ;
- préparation présentateur ;
- cérémonie TV ;
- finales joueur et spectateur.

**Sortie :** boucle complète, aucune fin administrative.

### Lot 6 — Motion, SFX et haptique

- chorégraphies par rôle ;
- cues nommés et pulses uniques ;
- timer halo ;
- press feedback ;
- haptique du contrôleur ;
- mode reduced-motion ;
- contrôle du mute.

**Sortie :** feedback complet sans doublons ni fatigue sensorielle.

### Lot 7 — Responsive et convergence pixel

- implémenter les règles de taille et d’orientation ;
- capturer toute la matrice de viewports ;
- superposer produit et mockup ;
- corriger géométrie, rythme, typographie, contraste et cadrage ;
- tester quatre langues, zoom, clavier et safe areas ;
- répéter jusqu’aux seuils de validation.

**Sortie :** interfaces stables, sans débordement ni rupture de hiérarchie.

### Lot 8 — Validation finale et migration

- suite de tests complète ;
- répétition réelle avec cinq appareils/sièges ;
- test réseau lent et reconnexion ;
- revue Conseil Noche ;
- télémétrie des anciennes routes ;
- activation progressive ;
- retrait ultérieur des chemins historiques inutilisés.

**Sortie :** fonctionnalité déployable, mesurée et réversible.

---

## 17. Méthode de convergence « pixel près »

Pour chaque écran :

1. capturer le produit au ratio exact du mockup ;
2. normaliser les dimensions ;
3. produire une superposition à 50 % ;
4. produire une image de différence ;
5. corriger d’abord les grandes masses : scène, arche, feuille, bandeau ;
6. corriger ensuite typographie, espaces, rayons et traits ;
7. corriger enfin ombres, métal, VFX et micro-alignements ;
8. répéter sur le viewport maître ;
9. vérifier que la fidélité ne casse aucun autre viewport ;
10. documenter les divergences volontaires liées aux données réelles ou à l’accessibilité.

Le pixel-perfect n’autorise pas :

- du texte figé dans l’image ;
- des données factices dans l’application ;
- une taille de police inaccessible ;
- un layout qui fonctionne uniquement au ratio du mockup ;
- la duplication de composants par viewport.

### Seuils de validation visuelle

- aucune différence structurelle non expliquée ;
- hiérarchie et proportions perçues équivalentes ;
- aucun débordement ou chevauchement ;
- cadrage du sujet correct ;
- une seule action principale visible ;
- contraste et focus conformes ;
- données dynamiques plus longues supportées.

---

## 18. Plan de tests

### 18.1 Tests fonctionnels

- reprise directe du participant ;
- création d’invité avec prénom ;
- conversion facultative en profil ;
- attribution et changement d’équipe ;
- autorisations présentateur ;
- accès spectateur sans création de joueur ;
- TV sans mutation de présence ;
- ancien lien redirigé ;
- réponse idempotente ;
- score et finale ;
- reconnexion à chaque phase.

### 18.2 Tests temps réel

- ouverture simultanée des cinq sièges ;
- verrouillage ;
- révélation ;
- pulse sonore unique ;
- changement de score ;
- arrivée tardive ;
- rafraîchissement TV ;
- retour après perte de réseau ;
- absence de fuite de la bonne réponse.

### 18.3 Tests visuels

- captures de tous les viewports de la matrice ;
- Light et Dark ;
- écran court et téléphone paysage ;
- noms d’équipe longs ;
- score à trois chiffres ;
- 2, 3, 4 et davantage d’équipes ;
- égalité ;
- soirée sans score ;
- français, portugais, anglais et espagnol ;
- mode mouvement réduit ;
- zoom 200 %.

### 18.4 Tests de performance

- poids des artworks portrait et paysage ;
- LCP de la première scène ;
- absence de layout shift à l’arrivée des polices et scores ;
- fluidité sur téléphone moyen/bas de gamme ;
- animations limitées à transform/opacity autant que possible ;
- mémoire après quinze manches ;
- comportement de la TV après plusieurs heures.

### 18.5 Répétition humaine

Organiser une soirée test avec :

- un présentateur ;
- au moins deux équipes en salle ;
- un joueur Casa ;
- un spectateur mobile ;
- une TV ;
- un enfant ;
- une personne âgée ;
- une connexion volontairement dégradée.

Mesurer : temps d’entrée, erreurs, demandes d’aide, regards vers le téléphone, hésitations du présentateur, latence ressentie, compréhension de la révélation et envie de rejouer.

---

## 19. Indicateurs de réussite

### Accès

- médiane joueur reconnu : un toucher ;
- médiane nouveau joueur : un champ + un toucher ;
- aucun code saisi dans le parcours standard ;
- taux de retour arrière avant lobby fortement réduit ;
- erreurs d’équipe corrigibles sans quitter la soirée.

### Expérience

- présentateur capable d’enchaîner sans lire une procédure ;
- joueur salle regardant majoritairement la salle/TV hors action ;
- joueur Casa actif à chaque manche ;
- spectateur distinctement compris comme spectateur ;
- finale comprise et célébrée sans instruction orale supplémentaire.

### Qualité

- aucun écran avec une note Conseil Noche inférieure à 8/10 ;
- zéro overflow sur la matrice supportée ;
- zéro double action critique ;
- aucune chaîne manquante ;
- aucune animation obligatoire en reduced-motion ;
- aucun cue sonore joué deux fois pour un même événement.

---

## 20. Risques et garde-fous

| Risque | Garde-fou |
|---|---|
| Entrée trop automatique vers la mauvaise personne | identité visible, changement calme, aucune donnée irréversible |
| Mauvaise équipe auto-attribuée | règle explicable et changement secondaire immédiat |
| Invités dupliqués | identité d’appareil + opération de join idempotente |
| Suppression trop rapide des codes | alias historiques, télémétrie et migration progressive |
| Artworks trop lourds | variantes responsives, préchargement ciblé, budget média |
| Or omniprésent | revue sémantique : métal, focus, score, récompense ou CTA seulement |
| TV illisible | tests réels à distance et safe zones broadcast |
| Animations fatigantes | budgets de durée, réduction de mouvement, particules limitées |
| Présentateur bloqué | snapshot autoritaire, reconnexion et action idempotente |
| CSS global fragile | extraction progressive de primitives Live et comparaison de diff |
| Traductions longues | tests de layout dans les quatre langues dès chaque lot |

---

## 21. Critères de validation par écran

Chaque écran doit répondre positivement à ces questions :

1. Quelle émotion précise doit-il provoquer ?
2. Quel est le verbe compris en moins de deux secondes ?
3. L’utilisateur doit-il réellement agir ici ?
4. Si non, l’état progresse-t-il automatiquement ?
5. Existe-t-il plus d’une action visuellement dominante ?
6. La scène narrative reste-t-elle visible ?
7. Le thème vient-il de l’artwork ?
8. L’or a-t-il une fonction claire ?
9. Le siège respecte-t-il son rôle ?
10. Le même état est-il cohérent sur les autres sièges ?
11. Le texte fonctionne-t-il dans les quatre langues ?
12. L’écran fonctionne-t-il sur petit téléphone, paysage, tablette et grand écran ?
13. Le focus, le lecteur d’écran et le mouvement réduit fonctionnent-ils ?
14. Le son est-il nommé, unique et désactivable ?
15. Les données affichées sont-elles réelles ?

Toute réponse négative bloque la validation.

---

## 22. Grille Conseil Noche

Chaque lot est noté sur 10 :

- Fun ;
- Clarté ;
- Impact visuel ;
- Feedback ;
- Progression ;
- Social ;
- Immersion ;
- Accessibilité ;
- Cohérence Noche Live ;
- Envie de continuer.

Une note inférieure à 8 entraîne une nouvelle passe. Le verdict est enregistré dans `docs/AGENT_REVIEWS/`.

---

## 23. Définition de terminé

La refonte est terminée uniquement lorsque :

- les cinq sièges sont séparés et cohérents ;
- les parcours connus et nouveaux fonctionnent sans code ;
- les équipes sont attribuées automatiquement dans les cas sûrs ;
- l’intégralité de la boucle lobby → manche → révélation → finale est implémentée ;
- les illustrations existent dans les ratios requis ;
- le thème vient des manifestes de scène ;
- les interfaces correspondent aux mockups sans sacrifier données, accessibilité ou responsive ;
- les animations et sons sont présents, synchronisés et réductibles ;
- la matrice responsive est validée ;
- les quatre langues sont validées ;
- la suite de tests passe ;
- une répétition humaine multi-appareils est concluante ;
- toutes les dimensions Conseil Noche atteignent au moins 8/10 ;
- les anciennes portes n’ajoutent plus de friction et disposent d’un plan de retrait mesuré.

Le résultat recherché n’est pas une interface plus jolie. C’est une soirée où les joueurs entrent sans réfléchir, comprennent immédiatement leur rôle, vivent ensemble le même récit et terminent avec l’envie de recommencer.
