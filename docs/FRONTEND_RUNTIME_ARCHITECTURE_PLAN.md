# Architecture du runtime frontend

## JavaScript, chargement, médias, audio, mouvement et transitions

Statut : architecture mise en œuvre et vérifiée dans le périmètre local. La mise en
production reste conditionnée uniquement par les gates qui exigent des appareils,
des réseaux régionaux ou l'infrastructure CDN réels.

Date de référence : 29 août 2026.

État d'exécution : le runtime, le manifeste contextuel, le loader autonome, le
préfetch borné, le lifecycle, HTTP partagé, le découpage CSS complet, la PWA
offline, le pipeline responsive de 434 médias, la sortie des masters de l'arbre
public, le port audio sans global, les catalogues par contexte, le backend Motion
isolé et les gates CI sont implémentés. Le backend natif reste l'unique moteur audio
de production ; Howler est vendored uniquement comme spike tant que sa matrice
iOS/iPadOS/Android/PWA physique n'est pas verte. Les preuves, métriques et écarts
externes sont consignés dans
[FRONTEND_RUNTIME_EXECUTION_REPORT.md](FRONTEND_RUNTIME_EXECUTION_REPORT.md) ; ce
rapport, et non une simple case de phase, fait foi sur ce qui est réellement livré.

Documents parents et contrats associés :

- [ARCHITECTURE.md](ARCHITECTURE.md) pour l'autorité serveur et les couches Rails ;
- [PERFORMANCE_ARCHITECTURE.md](PERFORMANCE_ARCHITECTURE.md) pour les budgets de rendu,
  réseau et temps réel ;
- [STREET_MULTI_DUEL_MOTION_PLAN.md](STREET_MULTI_DUEL_MOTION_PLAN.md) pour la
  chorégraphie du Campus ;
- `noche-conseil`, `noche-ui` et `noche-sfx` pour les contrats d'expérience,
  d'accessibilité, de mouvement et de son.

---

## 1. Résumé exécutif

Noche Live conserve Rails, Hotwire, Turbo Streams et Stimulus. Le projet ne devient
ni une SPA, ni une application React, et le navigateur ne devient pas l'autorité du
jeu.

Le changement consiste à construire un **runtime de présentation frontend** avec des
frontières explicites :

```text
Rails / Turbo Streams
        |
        | état métier et projections HTML autoritaires
        v
Contrôleurs Stimulus
        |
        | adaptateurs DOM et cycle de vie
        v
Modules de fonctionnalité
        |
        | quiz, Écritures, cérémonie, partage, push
        v
Services de plateforme
        |
        +-- HTTP et annulation
        +-- cycle de vie des effets
        +-- chargement contextuel et manifeste de ressources
        +-- shell de navigation et reprise réseau
        +-- médias responsifs et cache
        +-- audio Noche sur port unique (backend natif ; Howler derrière gate)
        +-- motion Noche sur backend Motion
        +-- politique de cadence et budget de frame
        +-- stockage et horloge
```

Décisions principales :

1. **Rails reste l'autorité.** Score, gagnant, phase, droits et progression ne sont
   jamais décidés par JavaScript.
2. **Stimulus reste le shell.** Un contrôleur adapte le DOM, délègue et nettoie ; il
   n'est pas un moteur, un dépôt réseau ni une timeline.
3. **Le chargement est un contrat de runtime.** Le shell, les surfaces, les médias,
   les cues et les recettes déclarent quand et pourquoi ils sont chargés. Le code
   critique reste minuscule ; le reste est contextuel, visible ou prédictif borné.
4. **Le port audio Noche est stable et le backend natif est le choix de production.**
   Howler Core reste un candidat encapsulé : il ne remplace le backend natif qu'après
   réussite des gates physiques. La politique `hit / stinger / bed` reste à Noche.
5. **Motion for JavaScript est le candidat backend d'animation.** Il prend les
   séquences narratives, springs, staggers, géométries dynamiques et interruptions.
6. **CSS reste le premier outil.** Press, hover, focus, états finaux, transitions
   simples et fallback sans JS restent en CSS.
7. **Turbo et la View Transition API possèdent les navigations.** Motion ne remplace
   pas le mécanisme déjà activé pour Turbo Drive.
8. **Les bibliothèques sont isolées.** Aucun contrôleur ne dépend directement de
   Howler ou Motion. Une migration ou un remplacement reste possible.
9. **Chaque effet a un propriétaire.** Timers, RAF, listeners, requêtes et animations
   sont annulés ou terminés explicitement à la déconnexion Stimulus.
10. **Chaque rendu a une cadence déclarée.** Le mouvement continu suit le taux réel de
   l'écran ; les compteurs, états réseau et effets invisibles ne tournent pas à chaque
   frame.

Le résultat attendu n'est pas seulement moins de code. Il doit donner un langage
audio-visuel plus cohérent, plus interrompable, plus testable et plus fiable sur
mobile.

---

## 2. Problème actuel

L'audit du 29 août 2026 constate :

- 59 contrôleurs Stimulus ;
- 6 419 lignes dans `app/javascript` ;
- `stage_controller.js` à 958 lignes ;
- `scripture_controller.js` à 753 lignes ;
- `stats_reveal_controller.js` à 415 lignes ;
- `quiz_controller.js` à 335 lignes ;
- un seul module partagé hors contrôleurs, `haptics.js` ;
- 17 sites d'appel à `fetch()` dans les contrôleurs ;
- aucune politique commune `AbortController` ;
- 88 sites planifiant timeout, interval ou RAF pour 44 sites d'annulation ;
- un singleton mutable `window.NocheLiveAudio` consommé transversalement ;
- un seul fichier de test JavaScript natif, consacré au service worker.
- cinq contrôleurs montés sur chaque `<body>`, dont `stage_controller.js` et
  `scripture_controller.js`, soit plus de 53 Ko de source à eux deux ;
- une feuille `application.css` d'environ 1 Mo brut et `duel_campus.css` chargé sur
  toutes les surfaces ;
- 437 Mo sous `public/media` pour 858 fichiers ;
- 783 images sur 852 entre 1 281 et 1 920 px sur leur plus grand côté ;
- cinq usages de `srcset`, dédiés au choix de format et non au choix de largeur ;
- aucune variante AVIF ni pipeline commun de résolutions responsives ;
- un service worker dont le handler `fetch` ne fournit ni shell local ni fallback ;
- après le premier geste, le moteur audio actuel précharge tous les cues non-bed au
  lieu du seul contexte actif ;
- le HTML dynamique servi depuis une région unique alors que les joueurs se trouvent
  notamment en Europe et en Amérique centrale.

Ces nombres ne prouvent pas seuls un défaut. Ils montrent cependant que le runtime
repose sur des conventions implicites et sur la discipline individuelle de chaque
contrôleur.

### 2.1 Risques concrets

- callbacks exécutés après un remplacement Turbo sur un élément détaché ;
- listeners globaux conservant d'anciens contrôleurs ;
- réponses réseau tardives modifiant une vue devenue obsolète ;
- duplication de CSRF, formats de réponse et gestion d'erreur ;
- dépendances cachées entre contrôleurs via recherche directe ou globals ;
- audio difficile à tester autrement que par inspection du texte source ;
- timings et easings divergents entre écrans ;
- séquences `setTimeout` non interrompables ;
- mouvement réduit traité écran par écran ;
- ajout d'une nouvelle animation ou d'un nouveau cue risquant un double déclenchement.
- téléchargement d'un média surdimensionné pour son slot réel ;
- attente vide ou loader infini sur un réseau intermittent ;
- préchargement spéculatif concurrençant le CTA, le HTML ou l'image LCP ;
- CSS et contrôleurs globaux consommés par une surface qui ne les utilise pas ;
- cache PWA présentant un état de jeu durable obsolète si sa portée est mal définie.

### 2.2 Ce qui est déjà juste

- l'état durable est serveur ;
- Turbo Streams distribue les projections ;
- une page GET peut reconstruire l'état ;
- les contrôleurs sont chargés selon leur présence dans le DOM ;
- l'importmap marque les contrôleurs et `haptics` en `preload: false` ;
- les plans de motion protègent le CTA et le contenu critique ;
- les cues sont nommés côté domaine ;
- la majorité des JPEG/PNG ont déjà un équivalent WebP sensiblement plus léger ;
- les assets GCS ont des durées de cache explicites ;
- la présence temps réel utilise Action Cable ;
- `prefers-reduced-motion` est déjà pris en compte dans de nombreux écrans.

La migration doit renforcer ce socle, pas le remplacer.

---

## 3. Portée et non-objectifs

### 3.1 Dans la portée

- structure des modules JavaScript ;
- cycle de vie Stimulus et Turbo ;
- accès HTTP client ;
- politique globale de chargement et de préchargement ;
- découpage CSS par shell et surface ;
- manifeste de ressources par contexte ;
- pipeline de médias responsifs et art-directed ;
- shell de navigation, reprise réseau et cache service worker ;
- runtime audio ;
- runtime de motion ;
- tokens et recettes de mouvement ;
- tests JavaScript et contrats d'architecture ;
- budgets de performance frontend ;
- migration des gros contrôleurs ;
- suppression des chemins legacy après cutover.

### 3.2 Hors portée

- déplacer l'autorité métier de Rails vers JavaScript ;
- introduire React, Vue, Svelte, Redux ou un routeur client ;
- construire un moteur physique, un canvas ou un moteur 3D ;
- remplacer Turbo Streams par un store client ;
- ajouter un bundler uniquement pour adopter Howler ou Motion ;
- réécrire tous les contrôleurs en une seule livraison ;
- modifier la direction artistique ou le gameplay sous couvert de refactor ;
- faire dépendre une écriture serveur de la fin d'une animation.

---

## 4. Autorité et responsabilités

| Sujet | Propriétaire | Interdit ailleurs |
| --- | --- | --- |
| Score, gagnant, phase, droits | Rails | calcul ou correction en JS |
| Projection d'un écran | Rails + ERB/Turbo | store client comme source de vérité |
| Navigation de page | Turbo Drive + View Transitions | routeur SPA |
| Remplacement partiel | Turbo Frame/Stream | fetch + innerHTML dispersé |
| Événement DOM | Stimulus | logique métier durable |
| État visuel local | module de fonctionnalité | modèle Active Record implicite côté client |
| Effets et annulation | `EffectScope` | timers/listeners orphelins |
| Décision de chargement | `ResourcePolicy` | prefetch, import ou preload dispersé |
| État de navigation lente | `LoadingDirector` | spinner propre à chaque contrôleur |
| Variantes d'un média | manifeste de médias + helper Rails | URL raster brute dans une vue |
| CSS d'une surface | feuille de surface Turbo dynamique | règles feature dans le shell global |
| Lecture audio bas niveau | backend Howler | appels Howler dans les contrôleurs |
| Mixage Noche | `NocheMixer` | logique `hit/stinger/bed` dans les vues |
| Transition simple | CSS | timeline JS inutile |
| Séquence narrative | recette Motion | chaîne de `setTimeout` |
| Transition de navigation | Turbo/View Transition | `animateView()` global concurrent |
| Mouvement réduit | runtime central + CSS | variation ad hoc par écran |

### 4.1 États serveur et états client

Les états suivants restent serveur :

```text
pending -> intro -> open -> locked -> answering -> revealed -> completed
```

Les états client décrivent uniquement la présentation :

```text
idle -> entering -> active -> exiting -> complete
```

Un état client peut être annulé, sauté ou réduit sans modifier le résultat serveur.

---

## 5. Structure cible

```text
app/javascript/
  application.js
  controllers/
    *_controller.js

  platform/
    loading/
      resource_loader.js
      network_policy.js
      fake_loader.js
    lifecycle/
      effect_scope.js
    http/
      client.js
      turbo_stream.js
    audio/
      backend.js
      howler_backend.js
      fake_backend.js
    motion/
      backend.js
      motion_backend.js
      fake_backend.js
    storage/
      safe_storage.js
    time/
      clock.js

  runtime/
    loading/
      director.js
      resource_manifest.js
      prefetch_policy.js
      contexts.js
    audio/
      catalog.js
      noche_mixer.js
      stage_sync.js
    motion/
      director.js
      render_policy.js
      preferences.js
      tokens.js
      recipes/
        ceremony_enter.js
        result_reveal.js
        score_flight.js
        list_stagger.js
        shared_hero.js

  features/
    quiz/
      presentation.js
      answer_command.js
    scripture/
      selection.js
      highlight_repository.js
      read_qualification.js
    push/
      subscription_service.js
    street/
      share_service.js
```

Les noms exacts peuvent évoluer pendant les spikes. Les frontières ne changent pas.

Structure CSS cible :

```text
app/assets/stylesheets/
  shell/
    tokens.css
    reset.css
    typography.css
    chrome.css
    loading.css
  surfaces/
    hub.css
    street_play.css
    live_play.css
    presenter.css
    watch.css
    study.css
    church.css
    campus.css
```

Le shell est commun et petit. Une feuille de surface est ajoutée au `<head>` seulement
par les réponses qui l'utilisent, avec `data-turbo-track="dynamic"`, afin que Turbo la
retire lorsqu'elle est absente de la réponse suivante. Le découpage suit des surfaces
produit stables, pas un fichier par partial.

### 5.1 Importmap

Les modules applicatifs sont épinglés par répertoire et restent chargés à la demande.
Les dépendances tierces sont :

- verrouillées à une version exacte ;
- téléchargées ou vendorizées localement ;
- absentes des CDN runtime ;
- importées uniquement par leur backend ;
- chargées seulement sur les écrans qui les utilisent.

Le projet n'ajoute pas de bundler tant qu'une mesure ne le justifie pas.

---

## 6. Contrat des contrôleurs Stimulus

Un contrôleur Stimulus peut :

- déclarer des targets, values, classes et outlets ;
- traduire un événement DOM en commande ;
- lire un résultat de module et appliquer un état visuel ;
- ouvrir ou fermer une ressource dans `connect()` / `disconnect()` ;
- émettre un événement DOM local documenté.

Un contrôleur Stimulus ne doit pas :

- contenir une bibliothèque ou un moteur complet ;
- effectuer un `fetch()` brut ;
- posséder une timeline faite de timeouts chaînés ;
- écrire dans un global mutable ;
- calculer un résultat métier ;
- coordonner plusieurs fonctionnalités sans façade ;
- conserver un listener global anonyme ;
- ignorer une promesse ou une animation après déconnexion.

Budget de revue : au-delà d'environ 200 lignes, le contrôleur doit justifier ses
responsabilités. Ce seuil déclenche une revue ; ce n'est pas une métrique de qualité
automatique.

### 6.1 Communication entre contrôleurs

Ordre de préférence :

1. service de module importé lorsque la dépendance n'est pas visuelle ;
2. Stimulus Outlets pour une relation structurelle explicite ;
3. événement DOM nommé et local pour une notification découplée ;
4. recherche directe d'un contrôleur uniquement comme compatibilité transitoire.

Il n'y aura pas d'event bus global générique.

---

## 7. Cycle de vie des effets

Chaque contrôleur créant des effets possède un `EffectScope`.

Interface cible :

```js
const scope = new EffectScope()

scope.listen(window, "keydown", handler)
scope.timeout(callback, 240)
scope.interval(callback, 1_000)
scope.frame(callback)
scope.animation(controls)
scope.abortable(controller)

scope.dispose()
```

Le scope :

- retire les listeners ;
- annule timeouts et intervals ;
- annule les RAF ;
- annule ou termine les animations selon leur politique ;
- annule les requêtes non `keepalive` ;
- est idempotent ;
- ne dépend pas de Stimulus et se teste avec une fausse horloge.

`disconnect()` doit pouvoir se résumer à `this.scope?.dispose()` pour la majorité des
contrôleurs.

### 7.1 Politique d'interruption

| Effet | Navigation/remplacement | Mouvement réduit |
| --- | --- | --- |
| effet décoratif | annuler | omettre |
| information finale | terminer immédiatement | état final immédiat |
| commande réseau | abort si devenue obsolète | identique |
| télémétrie `keepalive` | laisser terminer | identique |
| bed audio | resynchroniser avec le nouveau stage | identique |
| stinger | terminer ou crossfade selon le nouveau cue | identique |
| CTA | ne jamais rester verrouillé par l'animation | toujours actif |

---

## 8. Client HTTP commun

Les contrôleurs n'appellent plus directement `fetch()`.

API cible :

```text
request.json(url, options)
request.turboStream(url, options)
request.telemetry(url, payload, { keepalive: true })
```

Le client centralise :

- jeton CSRF ;
- `credentials: same-origin` ;
- `Accept` et `Content-Type` ;
- contrôle `response.ok` ;
- parsing JSON ou Turbo Stream ;
- erreurs structurées ;
- signal d'annulation ;
- timeout lorsque pertinent ;
- protection contre une réponse appliquée à une vue déconnectée.

Il ne transforme pas les contrôleurs en clients API riches. Les formulaires et Turbo
restent préférés lorsque le comportement natif suffit.

---

## 9. Architecture globale de chargement

### 9.1 Décision

Le runtime possède une politique de ressources explicite. Son objectif n'est pas de
faire du lazy loading partout, mais de livrer dans cet ordre :

1. le shell, le contenu utile et le CTA ;
2. les ressources indispensables à la surface active ;
3. les ressources révélées par une interaction ou l'approche du viewport ;
4. au maximum la prochaine étape probable, sans concurrencer l'étape active.

Une ressource sans classe, contexte, budget et propriétaire de cache est refusée en
revue. Le pays du joueur ne change jamais la qualité fonctionnelle ou l'identité
Noche. L'adaptation utilise le slot réel, le terminal, les préférences de données et
les timings observés, afin de servir la même expérience avec une fidélité progressive.

### 9.2 Classes de chargement

| Classe | Exemples | Déclencheur | Règle |
| --- | --- | --- | --- |
| `critical` | shell CSS, loader, CTA, HTML utile, média LCP | réponse initiale | chargé immédiatement, budget strict |
| `contextual` | CSS Street, backend audio d'un écran sonore, recette utilisée | surface présente | chargé une fois pour la surface active |
| `interaction` | lecteur d'Écritures, partage, guide PWA, dialogue secondaire | intention explicite | importé avant ou au premier geste selon contrainte d'unlock |
| `viewport` | cartes, peintures et vidéos sous la ligne de flottaison | approche du viewport | `loading=lazy` ou IntersectionObserver borné |
| `predictive` | prochaine question, prochain cue probable | écran stable et budget disponible | un seul futur proche, annulable |
| `idle` | décor optionnel, télémétrie non critique | thread et réseau libres | omis si le budget n'existe pas |

`critical` n'est pas synonyme de global. Une peinture LCP est critique pour sa réponse,
pas pour toutes les routes. `predictive` n'est pas synonyme de précharger toute une
session.

### 9.3 Manifeste de ressources par contexte

Rails produit un manifeste déclaratif pour la surface rendue. Il référence des clés
logiques et jamais des imports ou chemins tiers depuis les vues.

Exemple conceptuel :

```json
{
  "context": "street.quiz.ask",
  "styles": ["shell", "street_play"],
  "controllers": ["quiz", "countdown"],
  "media": {
    "lcp": "quiz.jehova.mar_rojo",
    "next": "quiz.jehova.jared_padre_hijo"
  },
  "audio": {
    "unlock": true,
    "cues": ["round_open", "correct_gold", "wrong_soft"],
    "bed": "timer_tension"
  },
  "motion": ["question-enter", "score-flight"],
  "prefetch": { "nextScreen": true, "maxBytes": 180000 }
}
```

Le manifeste est validé côté Rails puis projeté en données HTML minimales. Il permet
à `ResourcePolicy` de répondre à quatre questions : nécessaire maintenant, nécessaire
après un geste, candidat au prefetch ou interdit dans ce contexte.

Le manifeste ne devient pas un store métier client. Il ne contient ni score, ni phase
autoritaire, ni droit, et il peut être reconstruit par un GET normal.

### 9.4 LoadingDirector et formes de chargement

`LoadingDirector` possède l'état visuel des navigations et requêtes longues :

```text
idle -> pending -> visible -> slow -> offline|failed -> resolved
```

Il écoute les événements Turbo de requête, rendu et erreur. Il conserve l'ancien écran
jusqu'au nouveau rendu, désactive seulement la commande à risque de double soumission et
annule proprement l'état lors d'un retour cache ou d'une navigation concurrente.

Seuils initiaux, à recalibrer par la télémétrie réelle :

- `0-150 ms` : aucun loader afin d'éviter le flash ;
- `150-1 200 ms` : formes Noche silencieuses ;
- `> 1 200 ms` : état lent explicite mais non alarmiste ;
- `> 4 s` ou erreur réseau : retry et retour disponibles ;
- événement offline : fallback immédiat lorsque le shell local existe.

Les formes de chargement :

- appartiennent à `shell/loading.css` ;
- utilisent un SVG local ou du CSS de quelques kilo-octets ;
- n'importent ni Motion, ni illustration, ni font distante, ni audio ;
- n'animent que `transform` et `opacity` ;
- ont un état statique équivalent sous `prefers-reduced-motion` ;
- ne montrent pas de faux pourcentage lorsque la progression est inconnue ;
- ne masquent jamais indéfiniment une erreur ou un écran utile déjà disponible.

Une première visite navigateur ne peut afficher le shell Noche avant les premiers
octets HTML. Elle dépend donc d'un TTFB court et du CSS critique. Une PWA déjà installée
peut, elle, servir le shell versionné depuis le service worker. Ces deux chemins sont
testés séparément.

Tout nouveau texte de loading, lenteur, offline ou erreur reste soumis à la validation
éditoriale et aux quatre locales avant activation.

### 9.5 JavaScript global, contextuel et interactif

Stimulus conserve `lazyLoadControllersFrom` et `preload: false`. En complément :

- aucun contrôleur de fonctionnalité lourd n'est monté sur `<body>` ;
- le bootstrap global applicatif se limite au shell, au chargement, à l'accessibilité
  commune et aux petits adaptateurs réellement universels ;
- `stage_controller` est remplacé par un adaptateur audio contextuel ;
- `scripture_controller` est séparé entre un lanceur léger et le lecteur chargé quand
  son Turbo Frame entre dans le DOM ;
- le guide PWA, les flows de partage et les dépôts de highlights sont chargés à
  l'interaction ;
- Howler et Motion ne sont importés que par leur backend et jamais par
  `application.js` ;
- un import dynamique est mémorisé, dédupliqué et annulable dans son effet aval ; il
  ne crée pas plusieurs instances d'un service.

Exception audio : une surface sonore arme un port minuscule avant le geste. Le geste
déverrouille synchroniquement l'élément gate et l'`AudioContext`, puis importe le
backend natif. Les fichiers MP3 restent contextuels et ne sont pas téléchargés avant
l'unlock. Le catalogue est un bloc JSON de document, jamais un global `window`.

### 9.6 Découpage CSS par surface

`application.css` est démantelé en deux niveaux :

1. **shell** : tokens, reset, typographie de fallback, chrome commun, accessibilité,
   loader et états sans JS ;
2. **surface** : Hub, Street Play, Live Play, Presenter, Watch, Study, Church, Campus.

Le serveur inclut la feuille de surface dans la réponse qui en dépend. Les liens de
surface utilisent `data-turbo-track="dynamic"` pour que Turbo les retire quand la
réponse suivante ne les déclare plus. Les scripts n'utilisent pas cette stratégie :
retirer une balise `<script>` ne décharge pas son code déjà évalué.

Règles :

- une surface ne dépend pas de l'ordre accidentel d'une autre feuille ;
- les tokens partagés vivent dans le shell, pas en copie dans chaque surface ;
- aucune vue ne construit une feuille par requête ; les assets restent compilés et
  fingerprintés ;
- la réponse contient son CSS avant le rendu Turbo afin d'éviter un flash non stylé ;
- le CSS critique n'est pas obtenu par un `@import` bloquant en cascade ;
- le poids compressé est mesuré par route et thème, pas seulement fichier par fichier ;
- une règle player-facing supprimée n'est retirée du global qu'après inspection Light,
  Dark et des trois largeurs de référence.

### 9.7 Pipeline de médias responsifs

Les masters haute définition sortent de l'arbre servi publiquement. Un build
déterministe produit les dérivés et un manifeste versionné.

Familles initiales :

| Rôle | Largeurs candidates | Composition |
| --- | --- | --- |
| miniature/carte | `160, 320, 640` | crop de carte avec point focal |
| peinture téléphone portrait | `384, 768, 1152` | portrait protégé |
| tablette/colonne large | `768, 1152, 1536` | portrait ou paysage selon le slot |
| desktop/TV paysage | `768, 1280, 1920` | master/crop paysage validé |

Chaque dérivé possède :

- AVIF et WebP, plus un fallback JPEG lorsque nécessaire ;
- largeur, hauteur, poids, ratio, point focal et famille Light/Dark ;
- clé logique stable, hash de contenu et cache immutable ;
- placeholder couleur ou miniature très basse définition pour le shell ;
- seuil de qualité validé visuellement, jamais une compression uniforme aveugle.

Le helper Rails `noche_picture` émet `picture`, `source`, `srcset`, `sizes`, dimensions,
`loading`, `decoding` et `fetchpriority`. Les écrans utilisent une clé et un rôle, pas
une URL raster brute. Le navigateur choisit la largeur avant le téléchargement.

Une illustration pleine surface critique est un `<picture>` positionné sous le chrome,
pas un `background-image` opaque à la politique de chargement. Les backgrounds
secondaires peuvent employer `image-set()` et des media queries. L'art direction
portrait/paysage utilise des sources distinctes ; elle ne se réduit pas à étirer le
même fichier.

Le preload d'une image LCP utilise `imagesrcset` et `imagesizes`. Les images sous le
viewport sont lazy. Le prefetch d'une prochaine question référence le manifeste et ne
crée plus un `new Image()` sur une URL fixe.

Le build échoue lorsqu'un média player-facing référencé :

- n'a pas de variante adaptée à son rôle ;
- dépasse le plafond de poids sans exception mesurée ;
- ne déclare pas ses dimensions ;
- utilise un master PNG/JPEG de production alors qu'un dérivé existe ;
- possède une variante paysage automatique dont le sujet ou le CTA devient illisible.

### 9.8 Chargement audio par contexte

Le catalogue audio global devient un catalogue logique fractionné :

```text
core-unlock
quiz
live
study
ceremony
```

La couche `core-unlock` ne contient que ce qui est indispensable au geste mobile. Une
surface sonore arme le port audio avant le premier geste attendu, déverrouille la
session dans le chemin synchrone du geste, puis charge le backend validé et :

- précharge après unlock les cues probables du contexte actif ;
- charge le bed courant juste à temps et le conserve pendant les swaps Turbo qui ne
  changent pas `ends_at` ;
- charge un cue rare à sa première demande avec fallback silencieux non bloquant ;
- ne précharge jamais tous les one-shots du produit après n'importe quel geste ;
- déduplique cue, token et promesse de chargement ;
- respecte mute sans empêcher le halo visuel ou l'état final ;
- ne retarde ni le résultat serveur, ni le CTA, ni le rendu pour une erreur MP3.

La politique `hit / stinger / bed`, les gains, fades et triggers nommés restent dans
`NocheMixer`. Fractionner le téléchargement ne crée ni second moteur, ni second
AudioContext.

### 9.9 Chargement de Motion

Le loader de navigation et les transitions CSS simples fonctionnent sans Motion.
`motion_backend.js` est importé lorsqu'une surface déclare au moins une recette
complexe. Le director peut préparer le module après le rendu utile mais avant la
recette prévisible ; en cas de retard ou d'échec, l'état final CSS est appliqué sans
bloquer l'écran.

Les recettes d'une surface peuvent partager le même import et scheduler. Il n'existe
pas un chunk, import ou scheduler par composant animé.

### 9.10 Prefetch adaptatif

`PrefetchPolicy` autorise une anticipation seulement lorsque :

- le HTML, le CSS, le média LCP et les interactions critiques sont stables ;
- aucune commande joueur ni requête autoritaire n'est en vol ;
- le document est visible ;
- le budget de bytes et la limite d'un seul écran futur sont disponibles ;
- `Save-Data` ou un historique de requêtes lentes ne demandent pas l'économie ;
- la ressource n'est pas déjà en cache ou en vol.

La politique peut annuler `turbo:before-prefetch`, les imports et les fetch prédictifs.
`navigator.onLine`, `effectiveType` et `Save-Data` sont des indices, jamais une preuve.
Les erreurs et durées réelles des requêtes ont priorité. Aucune adaptation ne dépend
d'une géolocalisation ou d'un pays.

### 9.11 Service worker et mode intermittent

Le service worker reçoit une responsabilité limitée et testable : rendre le shell et
l'explication d'une panne disponibles, pas inventer un jeu offline autoritaire.

| Ressource | Stratégie |
| --- | --- |
| shell fingerprinté, loader, icônes | cache-first versionné |
| dérivés médias déjà visités | cache/HTTP immutable, plafond de stockage |
| navigation GET authentifiée | network-first, fallback offline générique |
| POST, Turbo Stream, Action Cable | network-only, erreur explicite |
| score, phase, droits, résultat | jamais servis depuis un snapshot obsolète |

L'installation ne précache ni les 437 Mo de médias, ni tous les cues, ni toutes les
surfaces. L'activation supprime les anciens caches de shell. Une réponse dynamique
mise en cache accidentellement est un défaut de sécurité et de cohérence.

### 9.12 Livraison mondiale et télémétrie

Les dérivés médias et assets fingerprintés passent par une vraie couche CDN/edge
devant le stockage objet, avec cache immutable. Un hostname GCS direct n'est pas tenu
pour une preuve de couverture edge : la topologie et les en-têtes sont vérifiés en
production.

Le HTML reste serveur et autoritaire. Avant toute complexité multi-région, la décision
se fonde sur du RUM agrégé :

```text
TTFB, LCP, INP, bytes transférés, cache hit, échec navigation
par surface, classe de terminal, type de connexion indicatif et grande région
```

Les données restent grossières, sans contenu joueur ni localisation précise. Les
gates sont vérifiés au minimum avec une connexion Europe stable, une forte latence,
un débit mobile contraint, des pertes intermittentes et une reprise après offline.

---

## 10. Architecture audio

### 10.1 Décision

Le candidat est `howler.core` version exacte `2.2.4`, sous réserve du spike mobile.
Le module spatial n'est pas inclus.

Howler prend en charge :

- Web Audio et fallback HTML5 Audio ;
- cache et décodage ;
- pooling de voix ;
- plusieurs lectures simultanées ;
- fade, loop, volume et mute ;
- événements de lecture et erreurs ;
- déverrouillage et reprise du contexte mobile.

Noche reste propriétaire de :

- la taxonomie des cues ;
- les couches `hit / stinger / bed` ;
- le ducking ;
- les priorités et exclusivités ;
- la déduplication pulse + clic ;
- les tokens de rejeu ;
- la synchronisation Turbo ;
- la décision de préchargement ;
- le mapping serveur `pulse -> cue`.

### 10.2 Backend isolé

Seul `platform/audio/howler_backend.js` importe Howler.

Interface conceptuelle :

```text
load(name, url, options)
play(name, options) -> playbackId
stop(playbackId)
fade(playbackId, from, to, duration)
setLoop(playbackId, enabled)
isPlaying(playbackId)
mute(enabled)
unlock()
unload(name)
```

`fake_backend.js` permet de tester le mixer sans navigateur ni sortie son.

Si le spike Howler échoue, un `native_backend.js` extrait du code actuel implémente la
même interface. L'architecture n'est donc pas jetée.

### 10.3 NocheMixer

API publique cible :

```text
playHit(name, gain?)
playStinger(name, gain?, token?)
setBed(name | null, options?)
duckBed(reason)
releaseDuck(reason)
releaseAsk()
syncStage(element)
setMuted(boolean)
unlock()
```

Le mixer est un singleton de module ES. Il persiste pendant les remplacements de
`<body>` Turbo sans être exposé sur `window`.

### 10.4 Contrats de mixage

| Couche | Contrat |
| --- | --- |
| Hit | polyphonique, recouvre stinger et bed, gain nominal `0.78` |
| Stinger | exclusif entre stingers, crossfade `240 ms`, gain nominal `0.80` |
| Bed | boucle, fade in/out, gain nominal `0.32` |
| Duck hit | bed vers `0.20`, puis restauration |
| Duck stinger | bed vers `0.10`, puis restauration |
| Déduplication | même cue + même token ignoré dans une fenêtre d'environ `250 ms` |
| Mute | coupe toutes les couches, conserve l'état logique nécessaire à la reprise |

Les hits ne passent jamais dans une voix exclusive. Seuls les stingers s'excluent.

### 10.5 Cues et déclencheurs

- un cue conserve un nom dans `Sfx::CUES` et `config/media/sfx.yml` ;
- les vues et définitions ne contiennent pas de chemin de fichier ;
- un événement possède un seul chemin de déclenchement : pulse, `stage_sfx` ou commande
  locale ;
- un cue identique rejoué sur une autre phase reçoit un token distinct ;
- un événement `open / lock / reveal` reste diffusé par le serveur ;
- le résultat serveur ne dépend jamais de la lecture effective du son.

### 10.6 Préchargement

Le catalogage global ne signifie pas décoder tous les MP3 au premier rendu.

Politique cible :

1. aucun fichier audio bloquant le rendu utile ;
2. cues critiques du siège courant préparés à l'entrée du jeu ;
3. bed et cue de la prochaine phase préchargés pendant un temps idle ;
4. autres cues chargés à la demande ;
5. URLs immuables servies par GCS/CDN ;
6. aucun appel de génération audio depuis une requête web.

### 10.7 Déverrouillage mobile

Le spike valide sur vrais appareils :

- premier pointer/touch/click ;
- bouton mute avant et après unlock ;
- installation PWA iOS ;
- retour de verrouillage écran ;
- interruption appel ou autre application ;
- background/foreground ;
- retour via bfcache ;
- navigation Turbo pendant un bed ;
- fallback lorsque Web Audio est indisponible.

### 10.8 Cutover audio

Le cutover est atomique :

- aucun second `AudioContext` durable ;
- aucune période de production avec deux moteurs jouant en parallèle ;
- les consommateurs migrent vers `NocheMixer` ;
- `window.NocheLiveAudio` est supprimé ;
- le moteur natif embarqué dans `stage_controller.js` est supprimé ;
- le skill `noche-sfx` est mis à jour dans le même changement pour autoriser l'unique
  backend Howler et continuer d'interdire un second stack Howler/Tone/native.

---

## 11. Architecture de mouvement

### 11.1 Décision

Le candidat est `motion` pour JavaScript, version exacte `13.1.1`, sous réserve du
spike Turbo/mobile.

Le runtime hybride est choisi pour les écrans nécessitant :

- séquences ;
- transforms indépendants ;
- springs ;
- stagger ;
- valeurs CSS ou SVG ;
- contrôle pause, cancel, stop et complete.

La version mini reste possible sur une fonctionnalité isolée qui n'a besoin que de
WAAPI simple, mais il ne doit pas exister deux conventions d'animation concurrentes.

### 11.2 Frontière CSS / Motion / Turbo

| Besoin | Outil |
| --- | --- |
| press, hover, focus | CSS |
| transition simple entre deux classes | CSS |
| animation décorative répétée | CSS, avec pause hors écran |
| état final et fallback sans JS | CSS |
| séquence narrative multi-éléments | Motion |
| spring ou inertie | Motion |
| stagger calculé et borné | Motion |
| trajectoire dynamique score -> couronne | Motion |
| entrée/sortie interrompable locale | Motion |
| navigation de page | Turbo + View Transition API |
| mise à jour métier | Rails/Turbo Stream |

Cette règle remplace l'interprétation absolue « CSS possède tout le mouvement » par
une frontière opératoire : **CSS possède les états et le mouvement simple ; Motion
joue les recettes complexes ; Turbo possède les changements de document**.

### 11.3 MotionDirector

Seul `platform/motion/motion_backend.js` importe Motion. Les écrans invoquent des
recettes nommées par `MotionDirector`.

API conceptuelle :

```text
play(recipeName, root, context) -> controls
complete(scope)
cancel(scope)
setReducedMotion(boolean)
```

Une recette déclare :

```text
name
intent
targets
initial state
final state
segments
maximum duration
render path
cadence
visibility policy
measurement policy
element budget
degradation policy
interruption policy
reduced-motion result
optional named SFX/haptic markers
```

Les contrôleurs n'importent pas `animate()`, `requestAnimationFrame()` ou le scheduler
Motion, et ne définissent pas des easings arbitraires.

### 11.4 Politique de cadence et budget de frame

Le runtime ne promet pas « toujours 60 FPS ». Il promet de sélectionner la cadence
la moins coûteuse qui conserve l'intention et de respecter l'écran réel. Un écran
90 ou 120 Hz ne doit pas accélérer une animation ni être artificiellement limité à
60 Hz pour un geste continu.

| Classe | Exemples | Cadence | Implémentation privilégiée |
| --- | --- | --- | --- |
| `display` | drag, spring, trajectoire de score, transition partagée | taux réel de l'écran, typiquement 60/90/120 Hz | CSS, WAAPI ou Motion, `transform`/`opacity` |
| `bounded` | particules DOM/SVG, interpolation d'un nombre décoratif | 30 Hz par défaut, durée et éléments bornés | scheduler Motion unique |
| `second` | chiffre du compte à rebours, halo d'urgence | une écriture au changement de seconde ou de zone | horloge absolue et timeout recalé |
| `event` | score, présence, phase, résultat | seulement lors d'un événement | Turbo Stream, Cable ou événement DOM |
| `idle` | écran masqué, cible hors viewport, aucune recette active | zéro frame | suspension ou annulation |

`display` signifie « une occasion de rendu par rafraîchissement », pas « une écriture
DOM obligatoire par frame ». Une animation compositeur peut continuer sans exécuter
du JavaScript applicatif à chaque image.

Chaque recette porte un contrat explicite, par exemple :

```js
{
  renderPath: "compositor",       // compositor | main-thread | discrete
  cadence: "display",             // display | 30hz | 1hz | event
  visibility: "visible-only",
  maxDurationMs: 560,
  maxElements: 12,
  measurement: "start-only",      // none | start-only | start-and-end
  degradation: "finish-essential-skip-decoration"
}
```

`MotionDirector` valide ce contrat. `render_policy.js` choisit la stratégie et le
backend exécute le travail. Pour les rares boucles JavaScript continues, le backend
utilise la frame loop partagée de Motion, qui sépare lectures, calculs et écritures ;
il ne crée pas un RAF indépendant par contrôleur.

Règles impératives :

- calculer la progression avec le timestamp/une horloge monotone, jamais en comptant
  les frames ;
- regrouper toutes les lectures DOM avant les écritures ;
- ne faire aucun `getBoundingClientRect()`, `offsetWidth` ou style calculé dans une
  boucle continue ; les mesures ont lieu au départ, à la fin ou sur resize explicite ;
- préférer `transform` et `opacity` ; justifier et mesurer toute propriété déclenchant
  layout ou paint ;
- réserver `will-change` à la durée de l'effet et à un nombre borné de calques ;
- arrêter le travail décoratif avec `document.hidden`, `IntersectionObserver`,
  `disconnect()` et `turbo:before-cache` ;
- recalculer depuis l'état autoritaire au retour au premier plan, sans rejouer les
  frames manquées ;
- ne jamais synchroniser l'audio sur des frames vidéo : Howler/Web Audio conserve son
  horloge audio, la motion ne reçoit que des marqueurs métier bornés.

Cas de référence : le compte à rebours. La barre reçoit une animation linéaire unique
de sa progression courante vers zéro sur la durée restante. Le chiffre et les classes
`warn/hot/empty` changent seulement à la prochaine frontière de seconde ou de zone.
En arrière-plan, aucune boucle ne tourne ; au retour, la vue est recomposée depuis
`ends_at`. Le halo suit la même cadence discrète. Le code actuel qui écrit label,
transform et classes dans un RAF permanent doit donc être migré.

Budget par frame sur l'appareil mobile de référence :

- à 60 Hz, le navigateur dispose de `16,7 ms` pour toute la frame ; Noche vise au plus
  `4 ms` de JavaScript applicatif au p95 pendant une recette ;
- à 120 Hz, la fenêtre tombe à environ `8,3 ms` ; le support est opportuniste et
  mesuré, sans dégrader le contrat 60 Hz ;
- zéro forced synchronous layout dans une boucle active ;
- aucune longue animation frame `> 50 ms` causée par une recette ;
- si le budget est dépassé, terminer l'information essentielle et supprimer d'abord
  les éléments décoratifs ; ne jamais ralentir une commande ou masquer le CTA.

### 11.5 Tokens de mouvement

Les tokens existants deviennent le vocabulaire partagé :

```text
instant  100 ms
fast     160 ms
ui       240 ms
event    380 ms
screen   420 ms
hero     560 ms

ease-out     cubic-bezier(.16, 1, .3, 1)
ease-spring  cubic-bezier(.2, 1.3, .3, 1)
ease-mark    cubic-bezier(.2, .8, .2, 1)
linear       linear

stagger-avatar  55 ms
stagger-result  85 ms
```

Motion ajoute seulement quelques presets physiques nommés :

```text
spring-press
spring-reward
spring-sheet
spring-shared
```

Chaque preset possède une intention, pas seulement des nombres.

### 11.6 Budgets de chorégraphie

- micro-feedback : `100-240 ms` ;
- événement : `300-420 ms` ;
- transition d'écran locale : `360-560 ms` ;
- séquence automatique totale : `1,8 s` maximum ;
- quatre lignes staggered individuellement au maximum ;
- les suivantes entrent ensemble ;
- le CTA critique est lisible et actif avant la première frame ;
- le contenu critique n'est jamais conditionné à une animation ;
- `transform` et `opacity` sont préférés ;
- pas de blur plein écran ou animation de layout coûteuse sans mesure ;
- une animation interrompue laisse un état final cohérent.

### 11.7 Mouvement réduit

Le runtime central observe `prefers-reduced-motion`.

Quand il est actif :

- les translations, zooms, staggers, flashes et trajectoires sont omis ;
- l'état final est appliqué immédiatement ;
- le texte, le résultat, la progression et le CTA restent identiques ;
- le son n'est pas coupé automatiquement ;
- les voiles VFX sont masqués ;
- aucune écriture serveur n'est perdue ;
- `skip()` et les annonces live region restent fonctionnels.

### 11.8 SFX, haptique et motion

La boucle de payoff reste :

```text
action -> résultat serveur -> motion -> cue nommé -> haptique -> prochaine envie
```

Une recette peut émettre un marqueur nommé, mais :

- elle ne contient pas de chemin de fichier ;
- elle ne joue pas directement Howler ;
- le marqueur passe par `NocheMixer` ;
- un cue serveur déjà reçu n'est pas rejoué localement ;
- le haptique n'est activé que lorsque le téléphone est le contrôleur ;
- le résultat final ne dépend pas du callback audio ou motion.

### 11.9 Turbo Drive

Le meta View Transition existant reste la voie par défaut. Les transitions se
personnalisent avec :

- IDs stables ;
- `view-transition-name` explicite ;
- pseudo-éléments CSS ;
- `data-turbo-visit-direction="forward|back|none"` ;
- fallback instantané lorsque l'API n'est pas disponible.

`Motion.animateView()` n'encapsule pas globalement Turbo Drive. Cela créerait un
deuxième propriétaire de navigation.

### 11.10 Turbo Frames et Streams

Une animation autour d'un rendu partiel est autorisée seulement si :

- la cible s'inscrit explicitement à une recette ;
- le rendu serveur n'attend pas une animation pour être correct ;
- l'ancien contenu reste non interactif pendant son exit ;
- une interruption ou un timeout rend immédiatement le nouvel état ;
- `turbo:before-frame-render` ou `turbo:before-stream-render` est utilisé localement,
  jamais comme intercepteur global de tous les streams ;
- le temps ajouté au rendu est mesuré et borné ;
- un stream de présence ou de score critique n'est jamais retardé pour du décoratif.

---

## 12. Recettes de mouvement initiales

| Recette | Premier consommateur | Intention |
| --- | --- | --- |
| `stats-reveal` | page statistiques | révéler sans conserver 400 lignes de timeline |
| `ceremony-enter` | fin de pack | accomplissement et prochaine envie |
| `result-stagger` | Campus multi-duel | comprendre plusieurs résultats rapidement |
| `score-flight` | quiz Street | matérialiser le gain vers la couronne |
| `combo-ignite` | quiz Street | fierté et tension, sans masquer la question |
| `shared-hero` | carte -> détail | conserver le contexte entre deux vues |
| `list-enter` | classement | entrée bornée, jamais une attente proportionnelle à la liste |

Les animations `press`, timer halo, focus et transitions de sheet simples restent en
CSS ou dans leur geste existant tant qu'une mesure ne justifie pas leur migration.

---

## 13. Stratégie de tests

### 13.1 Tests JavaScript purs

Ajouter un harness racine minimal avec `node:test`, sans introduire de bundler de
production.

```text
test/javascript/
  unit/
    effect_scope_test.mjs
    http_client_test.mjs
    loading_director_test.mjs
    resource_policy_test.mjs
    prefetch_policy_test.mjs
    resource_manifest_test.mjs
    noche_mixer_test.mjs
    motion_director_test.mjs
    render_policy_test.mjs
    countdown_projection_test.mjs
    scripture_selection_test.mjs
  contracts/
    loading_contexts_test.mjs
    media_manifest_test.mjs
    audio_layers_test.mjs
    motion_recipes_test.mjs
  fakes/
    fake_network.mjs
    fake_cache.mjs
    fake_audio_backend.mjs
    fake_motion_backend.mjs
    fake_clock.mjs
```

Les tests vérifient le comportement, pas seulement la présence d'une chaîne dans le
source.

### 13.2 Contrats audio

- un hit recouvre un stinger ;
- deux stingers crossfadent ;
- le bed duck puis revient au gain précédent ;
- le même cue/token est dédupliqué ;
- un nouveau token rejoue le même cue ;
- mute coupe les couches ;
- un même bed n'est pas redémarré après un swap Turbo ;
- `releaseAsk()` arrête le bed de tension ;
- seuls les cues du contexte actif sont préchargés après unlock ;
- une page silencieuse ne charge ni backend audio ni MP3 ;
- erreur de chargement dégrade sans casser le jeu.

### 13.3 Contrats motion

- toute recette possède un état final ;
- toute recette possède une politique réduite ;
- durée maximale déclarée `<= 1,8 s` ;
- stagger borné ;
- annulation nettoie les styles temporaires ;
- completion force l'état final ;
- aucune recette ne calcule score ou résultat ;
- aucun CTA critique n'est bloqué par défaut ;
- les marqueurs SFX sont nommés et dédupliqués.

### 13.4 Contrats de cadence

- chaque recette déclare chemin de rendu, cadence, visibilité et budget d'éléments ;
- une recette `display` utilise le temps écoulé et reste identique à 60, 90 et 120 Hz ;
- aucun contrôleur ne crée une boucle RAF autonome ;
- aucune callback de frame n'est active lorsque le director est au repos ;
- une cible hors écran suspend son décoratif sans suspendre son état métier ;
- le retour de background recalcule depuis l'horloge autoritaire ;
- le chiffre d'un countdown reçoit au plus une écriture par seconde ;
- la barre du countdown utilise une animation bornée, pas une écriture JS par frame ;
- reduced motion et dégradation terminent l'état essentiel immédiatement ;
- le fake scheduler permet de tester 60, 90, 120 Hz et les frames manquées sans
  attendre le temps réel.

### 13.5 Contrats de chargement

- chaque surface possède un manifeste valide et un budget ;
- le shell et le CTA ne dépendent d'aucune ressource contextuelle ;
- les contrôleurs globaux respectent la allowlist et le budget ;
- une feuille de surface est présente seulement sur les réponses qui l'utilisent ;
- Turbo retire une feuille `dynamic` absente de la réponse suivante sans flash non
  stylé ;
- les transitions `pending/visible/slow/offline/failed/resolved` sont déterministes ;
- le loader n'importe ni Motion, ni audio, ni média lourd ;
- reduced motion produit un loader statique de même sens ;
- le prefetch attend les ressources critiques, ne prend qu'une cible et s'annule en
  background ou sous contrainte de données ;
- le service worker ne met jamais en cache POST, Turbo Stream, score, phase ou droits ;
- un démarrage PWA offline affiche le shell et une action de reprise ;
- une navigation offline ne remplace pas l'écran par un état de jeu obsolète ;
- chaque média player-facing possède formats, dimensions, largeurs et rôle ;
- le helper choisit un `srcset/sizes` adapté à 390, 768 et 1440 px ;
- le preload LCP et l'image rendue sélectionnent la même variante ;
- aucun master PNG/JPEG n'est exposé lorsque des dérivés existent ;
- les plafonds de bytes échouent en CI avec le détail de la ressource responsable.

### 13.6 Tests Rails et système

Conserver :

- tests de mapping `Sfx.for_pulse` ;
- tests de rendu `data-stage-*` ;
- tests de Turbo Streams ;
- tests système des gestes et de la navigation ;
- captures des écrans visibles.

Ajouter des scénarios :

- navigation pendant une animation ;
- restauration depuis le cache Turbo ;
- mouvement réduit ;
- double message Cable/Stream ;
- stream remplaçant une cible en cours d'animation ;
- absence de JavaScript : contenu et CTA critiques restent disponibles ;
- passage background/foreground pendant un countdown et une recette ;
- cible animée entrant et sortant du viewport ;
- écran à taux de rafraîchissement élevé sans accélération de la durée ;
- navigation instantanée sans flash de loader ;
- navigation lente avec formes puis état explicite ;
- échec et retry Turbo ;
- première visite froide, retour avec cache HTTP et démarrage PWA offline ;
- prochaine question non préchargée sous contrainte de données ;
- média LCP réellement sélectionné et bytes transférés à chaque viewport.

Les tests statiques peuvent interdire des dépendances ou globals. Ils complètent les
tests comportementaux ; ils ne les remplacent pas.

### 13.7 Matrice appareils et réseaux réelle

Avant cutover audio ou motion :

- iPhone Safari ;
- iPhone PWA installée ;
- Android Chrome ;
- iPad ;
- desktop Chrome/Safari ;
- écran TV 16:9 pour watch ;
- Europe stable ;
- forte latence vers l'origine ;
- débit mobile contraint avec pertes intermittentes ;
- `Save-Data` lorsqu'il est disponible ;
- offline, retry et reprise après background.

---

## 14. Budgets et observabilité

### 14.1 Chargement

Plafonds initiaux. La Phase 0 peut les resserrer ; les augmenter nécessite une mesure,
un propriétaire et une date de retrait de l'exception.

| Budget | Plafond initial |
| --- | --- |
| shell loader CSS + SVG | `<= 6 Ko` compressés |
| shell CSS applicatif | `<= 25 Ko` compressés |
| CSS total d'une surface | `<= 60 Ko` compressés, shell inclus |
| JavaScript applicatif global | `<= 12 Ko` compressés, hors Hotwire versionné |
| transfert avant CTA interactif, mobile froid | `<= 350 Ko`, HTML/CSS/JS/LCP inclus |
| média LCP 390 px | `<= 160 Ko` encodés |
| média LCP 768 px | `<= 240 Ko` encodés |
| média LCP 1440 px | `<= 350 Ko` encodés |
| prefetch prédictif | une cible et `<= 180 Ko` simultanés |
| audio page silencieuse | `0 octet` de backend et MP3 |
| audio avant geste | `0 octet` de MP3 |
| one-shots audio préchargés après unlock | `<= 200 Ko` par contexte, bed courant séparé |
| précache service worker | `<= 120 Ko` hors icônes de plateforme |

Autres contrats :

- Motion n'est pas préchargé par `application.js` ;
- un contexte de recette le charge seulement sur une surface animée ;
- Howler n'est pas chargé sur une page silencieuse ;
- les contrôleurs globaux du `<body>` sont allowlistés et mesurés ;
- le rendu utile précède le chargement des effets non critiques ;
- aucun master média n'entre dans le budget d'une route ;
- le delta compressé et les bytes réseau réels sont mesurés après importmap, GCS et
  CDN, pas estimés depuis npm ou le poids du dépôt ;
- un plafond média reste soumis à une inspection de qualité : respecter les bytes avec
  une peinture visiblement dégradée n'est pas un succès.

### 14.2 Runtime

- p75 INP `<= 200 ms` ;
- p75 LCP `<= 2,5 s` ;
- CLS `<= 0,1` ;
- aucun long task `> 50 ms` causé par une recette sur l'appareil de référence ;
- pas de boucle RAF quand aucune animation locale n'est active ;
- pas de boucle RAF applicative pour un countdown, un halo ou un état réseau ;
- aucun polling HTTP au repos ;
- un seul scheduler Motion actif par séquence ;
- lectures DOM groupées avant écritures ;
- animations hors écran suspendues ou omises ;
- JavaScript applicatif d'une recette `<= 4 ms` au p95 sur une frame de l'appareil
  mobile de référence ;
- zéro forced synchronous layout dans une boucle continue ;
- durée d'une recette stable à 60, 90 et 120 Hz.

### 14.3 Instrumentation et RUM

En développement, le runtime peut exposer un logger non global de diagnostic :

```text
motion recipe started/completed/cancelled
motion cadence/render path/frame cost/degradation
audio cue requested/played/deduplicated/failed
active effects by controller
request aborted after disconnect
resource requested/loaded/cached/cancelled with class and bytes
navigation pending/visible/slow/offline/failed/resolved
selected media key/format/width/encoded bytes
surface CSS and global JS bytes
prefetch allowed/denied with reason
```

Aucun contenu utilisateur, token sensible ou localisation précise n'est journalisé.
La production agrège TTFB, LCP, INP, CLS, bytes, cache hit et échecs par surface,
classe de terminal et grande région. Les p75 et p95 Europe/Amérique centrale sont lus
séparément ; une moyenne mondiale ne peut pas masquer une région dégradée.

---

## 15. Plan de migration

État au 29 août 2026 :

| Phase | État prouvé | Gate restant |
| --- | --- | --- |
| 0 — baseline | baseline locale archivée et protocole rejoué | mesures production, CDN et réseaux Europe/Honduras |
| 1 — fondations | terminée localement | aucune |
| 2 — CSS/JS global | terminée localement | observation production du CSS réellement transféré |
| 3 — médias/PWA | code, tests et six masters Hub paysage 1672 px terminés | CDN réel, appareils et masters >= 1920 px pour TV |
| 4 — Howler | port, vendor, fake et contrats terminés | matrice audio sur appareils physiques ; aucune adoption avant ce gate |
| 5 — audio | cutover local terminé sur l'unique backend natif, sans global | décision de bascule Howler après Phase 4 physique |
| 6–7 — motion | director, backend isolé, recettes, cadence et reduced motion terminés localement | traces frame/mémoire sur appareils 90/120 Hz |
| 8 — fonctionnalités | contrôleurs globaux lourds supprimés, lecteur lazy, HTTP/effets centralisés | poursuite du ratchet de taille lors des évolutions fonctionnelles |
| 9 — enforcement | gates architecture, budgets et suites ajoutés | branch protection/CI distante |

Une phase marquée « terminée localement » ne vaut pas validation d'un gate externe.
Le rapport d'exécution fait foi sur les commandes et les limites observées.

### Phase 0 — Baseline et caractérisation

Livrables :

- mesures de payload et de runtime par écran ;
- waterfalls froides et chaudes à 390, 768 et 1440 px ;
- mesures sous latence forte, débit contraint, pertes intermittentes et offline ;
- inventaire des CSS par sélecteur/surface et des contrôleurs globaux ;
- inventaire des médias : appelants, formats, dimensions, poids, rôles et doublons ;
- vérification des en-têtes GCS/CDN, cache hit et topologie de livraison ;
- RUM minimal par surface et grande région ;
- tests de comportement du mixage actuel ;
- tests des principales séquences actuelles ;
- inventaire des `fetch`, timers, RAF, listeners et globals ;
- matrice des écrans qui ont réellement besoin d'audio ou de Motion.

Critères de sortie :

- le comportement actuel important est décrit par des tests ;
- chaque surface critique possède un budget initial signé ;
- les dix ressources dominantes par route sont connues ;
- le coût réel Europe et Amérique centrale n'est pas masqué par une moyenne globale ;
- les mesures sont archivées ;
- aucun changement produit n'est mélangé au refactor.

### Phase 1 — Fondations du chargement et du runtime

Livrables :

- arborescence `platform / runtime / features` ;
- `EffectScope` ;
- client HTTP ;
- `ResourcePolicy`, `LoadingDirector` et `PrefetchPolicy` ;
- manifeste de contexte Rails validé ;
- shell de formes CSS/SVG sans Motion ;
- fakes réseau, cache et horloge ;
- safe storage et clock injectables ;
- `render_policy` et fake scheduler injectables ;
- harness `node:test` ;
- contrats d'importmap et chargement lazy ;
- instrumentation bytes/cache/loading state.

Critères de sortie :

- deux contrôleurs pilotes utilisent le scope et le client ;
- deux surfaces pilotes déclarent un manifeste complet ;
- navigation rapide, lente, échouée et offline testée ;
- prefetch suspendu sous contrainte et background ;
- le countdown pilote sépare barre `display`, chiffre `second` et expiration `event` ;
- déconnexion et annulation sont testées ;
- aucune régression visuelle ou réseau.

### Phase 2 — Cutover du shell CSS et JavaScript global

Livrables :

- extraction `shell / surfaces` depuis `application.css` ;
- chargement Turbo `dynamic` des feuilles de surface ;
- allowlist et budget du JavaScript global ;
- retrait de `duel_campus.css` des surfaces non Campus ;
- séparation `scripture launcher / reader` ;
- remplacement du `stage_controller` global par un adaptateur audio contextuel ;
- guide PWA et services secondaires chargés à l'interaction.

Critères de sortie :

- aucune surface pilote ne dépend d'une autre feuille de surface ;
- navigation Turbo avant/arrière sans FOUC ni style résiduel ;
- aucun contrôleur de fonctionnalité lourd sur `<body>` ;
- shell et CSS par route dans les budgets ;
- contenu, CTA, Light, Dark et reduced motion identiques.

### Phase 3 — Pipeline médias, edge et PWA intermittente

Livrables :

- masters déplacés hors de l'arbre public ;
- build AVIF/WebP/JPEG déterministe ;
- manifeste médias avec rôles, dimensions, poids, focus et thèmes ;
- helper `noche_picture` et preload responsive ;
- variantes téléphone, tablette, desktop/TV et cartes ;
- migration des médias LCP puis de toutes les surfaces player-facing ;
- prefetch quiz via manifeste et budget ;
- CDN/edge et en-têtes immutable vérifiés ;
- service worker versionné : shell local, fallback offline, aucun état métier caché ;
- nettoyage contrôlé des dérivés orphelins locaux et distants.

Critères de sortie :

- le navigateur choisit des largeurs distinctes à 390, 768 et 1440 px ;
- aucun master lourd n'est transféré lorsqu'un dérivé existe ;
- aucune URL raster brute dans une vue player-facing hors exception documentée ;
- médias LCP et transfert avant CTA dans les budgets ;
- PWA froide puis offline affiche le shell sans prétendre reconstruire le jeu ;
- qualité des crops inspectée, notamment sujets, lumière, texte et CTA ;
- reprise réseau et invalidation de cache testées.

### Phase 4 — Spike Howler

Livrables :

- backend Howler Core isolé ;
- fake backend ;
- `NocheMixer` avec les contrats actuels ;
- écran de test ou flag de développement ;
- rapport iOS/PWA/Android/Turbo ;
- mesure de latence première lecture, mémoire et payload ;
- validation du catalogue fractionné `core/quiz/live/study/ceremony`.

Gate d'adoption :

- première lecture fiable après geste ;
- bed stable après navigation et background ;
- aucune double lecture ;
- hit/stinger/bed conformes ;
- aucun MP3 avant geste et aucun audio sur une page silencieuse ;
- seuls les cues du contexte sont préchargés ;
- fallback acceptable ;
- aucune régression audible ou de performance ;
- tests comportementaux verts.

Si le gate échoue, extraire un backend natif derrière la même interface et documenter
la cause.

### Phase 5 — Cutover audio

Livrables :

- migration de tous les consommateurs ;
- `stage_controller` réduit à l'adaptation DOM et au mute ;
- backend chargé uniquement sur une surface sonore ;
- préchargement par contexte ;
- suppression de `window.NocheLiveAudio` ;
- suppression du moteur natif embarqué ;
- mise à jour de `noche-sfx` et des tests Rails.

Critères de sortie :

- zéro import Howler hors backend ;
- zéro global audio applicatif ;
- un seul moteur et un seul contexte ;
- zéro préchargement global de tous les cues ;
- tests et matrice appareils verts.

### Phase 6 — Spike Motion

Premier pilote : `stats-reveal`, puis une cérémonie Campus.

Livrables :

- backend Motion isolé ;
- `MotionDirector` ;
- tokens ;
- deux recettes ;
- support interruption, skip et reduced motion ;
- contrats de cadence et de chemin de rendu validés ;
- migration du halo/countdown hors RAF permanent ;
- mesures avant/après ;
- inspection 390 x 844, 768 x 1024 et 1440 x 900.

Gate d'adoption :

- séquence visuellement au moins équivalente ;
- moins de logique de timeline dans le contrôleur ;
- annulation Turbo fiable ;
- état final identique sans mouvement ;
- CTA jamais retardé ;
- budgets frames, INP et payload respectés ;
- aucune accélération à 90/120 Hz et aucune frame au repos/background ;
- p95 du JavaScript applicatif dans le budget sur l'appareil de référence ;
- Celestial Light et Dark cohérents.

### Phase 7 — Système de motion

Livrables :

- recettes `result-reveal`, `score-flight`, `combo-ignite`, `list-enter` ;
- migration de `street_motion_controller` et des payoffs du quiz ;
- intégration SFX/haptique nommée ;
- suppression des timeouts de chorégraphie remplacés ;
- modification du plan Campus pour refléter la nouvelle frontière CSS/Motion.

Critères de sortie :

- zéro import Motion dans un contrôleur ;
- zéro timeline complexe dispersée ;
- toutes les recettes ont leurs contrats ;
- aucun état serveur dépend d'une animation.

### Phase 8 — Décomposition des fonctionnalités

Ordre recommandé :

1. `scripture_controller` : sélection, dépôt highlights, qualification lecture ;
2. `quiz_controller` : commande réponse, présentation, payoff ;
3. `push_subscription_controller` : service navigateur, dépôt HTTP, vue ;
4. partage Street et invitations ;
5. autres contrôleurs dépassant le budget de revue.

Critères de sortie :

- contrôleurs adaptateurs ;
- logique pure testée ;
- requêtes centralisées ;
- effets possédés ;
- compatibilités temporaires supprimées.

### Phase 9 — Enforcement et nettoyage

Ajouter des gates CI :

- pas de `fetch()` brut dans `controllers/` ;
- pas de contrôleur lourd ajouté à l'allowlist `<body>` ;
- pas de nouveau CSS feature dans le shell ;
- pas d'URL raster brute player-facing hors helper/exception ;
- chaque surface a manifeste et budget ;
- chaque média a rôle et variantes ;
- pas de `new Image()` ou prefetch brut hors `PrefetchPolicy` ;
- le service worker ne cache aucun état métier dynamique ;
- pas de `window.NocheLiveAudio` ;
- pas d'import Howler hors backend ;
- pas d'import Motion hors backend ;
- pas de `requestAnimationFrame()` direct dans `controllers/` ;
- pas de nouveau listener global anonyme ;
- chaque recette a test, durée maximale et reduced-motion ;
- chaque recette a cadence, chemin de rendu, visibilité et budget d'éléments ;
- suite Node et Rails verte ;
- vérification visuelle requise pour les changements player-facing.

Supprimer les fichiers legacy seulement après vérification des appelants.

---

## 16. Découpage recommandé en changements reviewables

1. **PR Loading baseline** — métriques, inventaires et budgets, aucun changement
   player-facing.
2. **PR Loading foundation** — manifestes, director, policy, loader shell et fakes.
3. **PR CSS surfaces** — shell commun, feuilles Turbo dynamiques et premiers pilotes.
4. **PR Global controller split** — scripture, stage, PWA et allowlist `<body>`.
5. **PR Responsive media pipeline** — build, manifeste, helper et un média LCP pilote.
6. **PR Media cutover + edge/PWA** — surfaces, prefetch, CDN et shell offline.
7. **PR Runtime foundations** — scope, HTTP, clock, render policy et tests restants.
8. **PR Audio characterization + Howler spike** — contrats puis backend derrière flag.
9. **PR Audio cutover** — catalogue contextuel et suppression de l'ancien moteur.
10. **PR Motion foundation** — backend, director, tokens, scheduler, countdown et
    `stats-reveal`.
11. **PR Campus motion** — cérémonie et résultats multi-duel.
12. **PR Quiz/Scripture split** — payoff, dépôts, modules purs et interruption.
13. **PR Architecture enforcement** — gates CI et suppression finale des
    compatibilités.

Chaque changement conserve un comportement jouable et peut être relu indépendamment.

---

## 17. Definition of Done frontend

Une tranche frontend n'est terminée que si :

- le serveur reste l'autorité ;
- le rendu initial contient le contenu et le CTA utiles ;
- la surface déclare son contexte et ses classes de ressources ;
- seul le shell et le CSS de la surface sont chargés ;
- le loader rapide/lent/offline a été exercé sans masquer un échec ;
- le contrôleur délègue la logique ;
- toutes les ressources ont un propriétaire de cycle de vie ;
- aucune réponse obsolète ne modifie un écran déconnecté ;
- audio et motion passent par leur façade Noche ;
- audio, motion et prefetch respectent le manifeste de contexte ;
- une page silencieuse n'a téléchargé aucun MP3 ;
- les médias utilisent le helper, les formats et largeurs adaptés au slot ;
- l'image LCP a dimensions, priorité, preload responsive et budget vérifiés ;
- les médias sous le viewport sont différés sans provoquer de CLS ;
- chaque rendu animé déclare sa cadence et son chemin de rendu ;
- le mouvement réduit produit le même sens et les mêmes actions ;
- navigation et skip interrompent proprement les effets ;
- erreurs, loading, empty, denied, success et failure sont exercés ;
- les tests purs, Rails et système pertinents passent ;
- la console est propre ;
- les écrans sont inspectés à 390, 768 et 1440 px ;
- Light et Dark sont inspectés lorsque les deux peuvent survenir ;
- les mesures de payload et performance sont enregistrées ;
- les bytes froids/chauds, cache hits et variantes sélectionnées sont enregistrés ;
- le parcours passe sous latence forte, débit contraint et offline/retry ;
- aucun prefetch n'a concurrencé le CTA, une commande ou le média LCP ;
- le service worker ne peut servir aucun score, phase ou droit obsolète ;
- aucune boucle de frame ne tourne au repos, hors écran ou en background ;
- les durées restent correctes sur écrans 60, 90 et 120 Hz ;
- le code legacy du périmètre n'a plus d'appelant et est supprimé ;
- aucune décision éditoriale non approuvée n'est activée.

---

## 18. Critères de réussite du programme

Le programme est achevé lorsque :

- `stage_controller.js` est un adaptateur court et non un moteur ;
- `scripture_controller.js` et `quiz_controller.js` sont décomposés ;
- aucun contrôleur de fonctionnalité lourd n'est global sur `<body>` ;
- `application.css` monolithique est remplacé par un shell et des surfaces bornées ;
- Campus CSS n'est jamais livré hors Campus ;
- chaque surface possède un manifeste de ressources validé ;
- toutes les peintures player-facing utilisent des variantes de largeur et de format ;
- les masters haute définition ne sont plus dans l'arbre public distribué ;
- mobile, tablette et TV ne reçoivent pas systématiquement le même raster ;
- le loader de formes fonctionne avant Motion et depuis le shell PWA ;
- une panne réseau produit un état explicite et récupérable, jamais une attente infinie ;
- le prefetch est borné, annulable et désactivable sous contrainte ;
- les budgets régionaux Europe/Amérique centrale restent visibles et verts ;
- `window.NocheLiveAudio` n'existe plus ;
- les contrôleurs ne contiennent plus de `fetch()` brut ;
- les séquences complexes utilisent des recettes nommées ;
- les transitions simples restent en CSS ;
- Turbo garde la propriété des navigations ;
- aucun effet asynchrone ne survit par accident à son contrôleur ;
- les règles audio sont testées sans sortie sonore réelle ;
- les règles motion sont testées sans attendre le temps réel ;
- countdown, halo, présence et score n'effectuent plus d'écriture DOM à 60 Hz ;
- les gestes et recettes continues suivent le taux réel de l'écran sans accélérer ;
- les grands écrans Noche partagent un langage de rythme reconnaissable ;
- les budgets de performance existants restent verts ;
- les plafonds CSS, JS, média, audio, prefetch et précache sont appliqués en CI ;
- la complexité totale diminue malgré l'ajout de deux dépendances.

---

## 19. Risques et réponses

| Risque | Réponse |
| --- | --- |
| Howler peu actif récemment | backend isolé, version pin, spike vrais appareils, fallback natif possible |
| Motion utilisé partout | imports restreints, recettes nommées, CSS par défaut |
| augmentation du payload | lazy loading, mesure compressée, suppression du code remplacé |
| lazy loading retardant le CTA | classes explicites, HTML utile et LCP en `critical` |
| loader dépendant du code qu'il attend | CSS/SVG shell autonome, aucun import Motion/audio/font/média |
| CSS de surface absent ou résiduel sous Turbo | liens `dynamic`, tests avant/arrière et FOUC |
| multiplication de petits fichiers CSS | surfaces produit stables, pas un fichier par partial, mesure HTTP réelle |
| import dynamique après geste perdant l'unlock audio | backend audio contextuel prêt avant le premier geste attendu |
| préchargement de tous les cues | catalogues contextuels, budget one-shots, bed courant séparé |
| prefetch consommant le forfait ou bloquant le LCP | une cible, plafond bytes, Save-Data/timings, annulation |
| master média servi par erreur | arbre masters séparé, helper obligatoire, gate CI |
| crop responsive détruisant la scène | point focal, variante art-directed et inspection Light/Dark |
| cache PWA servant un score obsolète | shell statique seulement, navigation dynamique network-first |
| faux positif `navigator.onLine` | indice seulement, résultat et timing réels prioritaires |
| performance correcte en Europe mais mauvaise au Honduras | RUM régional, scénarios forte latence/débit contraint, CDN vérifié |
| conflit Motion/Turbo | Turbo propriétaire des navigations, hooks locaux seulement |
| animations plus longues car plus faciles | budgets et durée maximale testés |
| « tout à 60 FPS » transforme les états discrets en boucles | cadence déclarative, scheduler partagé, zéro frame au repos |
| écran 120 Hz accélérant ou doublant le coût JS | progression fondée sur le temps, chemin compositeur, tests 60/90/120 Hz |
| trop de calques GPU | budget d'éléments, `will-change` temporaire, mesure mémoire mobile |
| état métier glissant vers le client | contrats d'architecture et tests serveur |
| double SFX serveur/local | un trigger par événement et token de déduplication |
| dette de compatibilité permanente | cutovers atomiques et critères de suppression explicites |
| tests trop statiques | fakes, tests comportementaux et matrice appareils |
| dépendance à un fournisseur | façade backend et API Noche stables |

---

## 20. Règles temporaires pendant la migration

Jusqu'au cutover validé :

- ne pas ajouter Howler à côté du moteur audio actuel en production ;
- ne pas ajouter Motion directement dans un contrôleur ;
- ne pas ajouter un contrôleur de fonctionnalité sur `<body>` ;
- ne pas ajouter de CSS feature à `application.css` hors correction urgente documentée ;
- ne pas ajouter de nouvelle URL PNG/JPEG/WebP brute dans une vue player-facing ;
- ne pas précharger une image fixe lorsqu'un `srcset` existe ;
- ne pas ajouter de `new Image()`, `<link rel=prefetch>` ou fetch spéculatif hors policy ;
- ne pas précacher une collection média, audio ou un HTML de jeu dans le service worker ;
- ne pas adapter la qualité d'expérience selon le pays ;
- ne pas générer automatiquement un crop paysage sans inspection du sujet et du CTA ;
- ne pas convertir mécaniquement les animations CSS existantes ;
- ne pas mélanger refactor runtime et changement de gameplay ;
- ne pas retirer un test de caractérisation avant son remplacement comportemental ;
- ne pas contourner les plans d'écran ou la charte Noche au nom de la bibliothèque.

Après cutover :

- `ResourcePolicy` est l'unique propriétaire du prefetch applicatif ;
- le shell et les feuilles de surface remplacent le CSS monolithique ;
- `noche_picture` et le manifeste sont la voie normale des médias player-facing ;
- le service worker ne possède que le shell/fallback et les caches statiques autorisés ;
- le port audio Noche est l'unique entrée des consommateurs ; le backend natif reste
  l'unique moteur de production tant que le gate Howler physique n'est pas vert ;
- Motion est l'unique backend de séquences complexes ;
- CSS et Turbo conservent leurs frontières définies ;
- les règles et skills du dépôt sont mis à jour pour ne plus contredire l'architecture.

---

## 21. Références techniques

- Howler : <https://github.com/goldfire/howler.js>
- Releases Howler : <https://github.com/goldfire/howler.js/releases>
- Motion for JavaScript : <https://motion.dev/docs/animate>
- Motion View Transitions : <https://motion.dev/docs/animate-view>
- Motion frame loop : <https://motion.dev/docs/frame>
- Motion performance : <https://motion.dev/docs/performance>
- `requestAnimationFrame` et taux d'écran :
  <https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame>
- Performance des animations CSS/JavaScript :
  <https://developer.mozilla.org/en-US/docs/Web/Performance/Guides/CSS_JavaScript_animation_performance>
- Turbo Drive et View Transitions :
  <https://turbo.hotwired.dev/handbook/drive#view-transitions>
- Turbo et assets de page `data-turbo-track="dynamic"` :
  <https://turbo.hotwired.dev/handbook/drive#removing-assets-when-they-change>
- Événements de rendu Turbo : <https://turbo.hotwired.dev/reference/events>
- Images responsives, `srcset`, `sizes` et art direction :
  <https://developer.mozilla.org/en-US/docs/Web/HTML/Guides/Responsive_images>
- Élément `picture` :
  <https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/picture>
- Preload responsive `imagesrcset/imagesizes` :
  <https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/imageSrcset>
- Service workers et Cache API :
  <https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API>
- Indice d'économie de données :
  <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Save-Data>
- Limites de `navigator.onLine` :
  <https://developer.mozilla.org/en-US/docs/Web/API/Navigator/onLine>

Les versions candidates sont celles disponibles à la date de référence. Toute mise à
jour de dépendance repasse les tests comportementaux et la matrice appareils.
