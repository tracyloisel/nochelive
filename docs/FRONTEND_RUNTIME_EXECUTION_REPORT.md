# Rapport d'exécution du runtime frontend

Date : 29 août 2026

Révision de référence : `0e226a7` (`main`) dans un worktree déjà modifié

Plan d'autorité : [FRONTEND_RUNTIME_ARCHITECTURE_PLAN.md](FRONTEND_RUNTIME_ARCHITECTURE_PLAN.md)

Baseline : [FRONTEND_RUNTIME_BASELINE.md](FRONTEND_RUNTIME_BASELINE.md)

## 1. Verdict

Tout le travail sûr et réalisable localement du plan est livré : runtime de
chargement, ownership des effets, HTTP commun, CSS par surface, médias responsifs,
art direction portrait/paysage, audio contextuel sans global, motion isolé, cadence
déclarée, shell PWA offline, nettoyage du legacy et gates d'architecture.

La livraison locale est verte. Cela ne vaut pas autorisation de production : les
mesures sur appareils physiques, réseaux Europe/Honduras et CDN réel restent des
gates externes. Howler n'est donc pas adopté en production ; le backend natif reste
l'unique moteur derrière le port audio Noche.

## 2. Architecture réellement livrée

- Rails et Turbo Streams restent l'autorité des scores, phases, droits et résultats.
- `Frontend::ResourceManifest` déclare contexte, classes de ressources, CSS, audio,
  motion et budget de prefetch.
- `ResourcePolicy`, `LoadingDirector`, `PrefetchPolicy`, `NetworkPolicy` et
  `ResourceLoader` centralisent le chargement et l'anticipation bornée.
- `EffectScope` possède listeners, timers, frames, animations et abort controllers ;
  `platform/http/client` centralise same-origin, CSRF, JSON, Turbo Stream et annulation.
- Stimulus reste un adaptateur DOM. Aucun contrôleur ne contient de `fetch()` brut,
  `requestAnimationFrame()` direct ou `new Image()`.
- `application.css` est devenu le shell. Les feuilles `church`, `gameplay`, `hub`,
  `identity`, `live`, `onboarding`, `profile`, `pwa`, `scripture`, `stats`,
  `street_play` et `study` sont chargées par surface ; Campus reste isolé.
- Les feuilles Turbo `dynamic` sont retirées sans FOUC ni style résiduel. Le loader
  interactif déduplique et refuse les URLs cross-origin. La feuille Google Fonts ne
  se duplique plus après navigation Turbo.
- Les masters sont sous `media/masters`, hors de l'arbre public. Un build déterministe
  produit AVIF/WebP/JPEG et un manifeste avec dimensions, poids, rôle, ratio, focus,
  thème et SHA-256.
- `noche_picture` émet `picture`, art direction, `srcset`, `sizes`, dimensions,
  `loading`, `decoding` et `fetchpriority`. Le Hub possède de vrais rendus portrait
  et paysage.
- Le port audio est un module, pas un global `window`. Le catalogue est un bloc JSON
  contextuel. Le geste déverrouille synchroniquement la session, puis importe le
  backend natif et les seuls cues probables.
- Howler Core 2.2.4 est vendored, hashé et enfermé dans son backend de spike. Il ne
  participe ni au graphe initial ni au moteur de production.
- Motion 13.1.1 est vendored et isolé. CSS possède les états simples ; Motion ne sert
  que les recettes complexes. Les compteurs initiaux utilisent le backend natif léger.
- Les countdowns projettent depuis le temps absolu ; aucun état discret ne nécessite
  une écriture DOM à chaque frame.
- Le service worker précache seulement cinq ressources de shell, sert
  `/offline-v1.html` pour une navigation indisponible et exclut commandes, Turbo
  Streams, Action Cable, état métier et cross-origin.

## 3. Legacy supprimé ou neutralisé

- `stage_controller.js` est passé de 953 à 43 lignes ; le moteur est derrière le port.
- `scripture_controller` n'est plus global : un launcher léger charge le lecteur à
  l'ouverture de sa frame.
- Le guide PWA et ses styles sont chargés à l'interaction.
- `window.NocheLiveAudio`, `window.NocheSfx` et les stores audio applicatifs globaux
  ont disparu ; tous les consommateurs importent le port.
- Le préchargement de tout le catalogue SFX après n'importe quel geste a disparu.
- Les appels réseau, RAF et prefetch image bruts des contrôleurs ont disparu.
- Les séquences Campus complexes passent par des recettes ; le code de feu de
  cérémonie sans appelant a été supprimé.
- Le CSS monolithique et les inclusions Campus globales/doublées ont disparu.
- Le handler `fetch` vide du service worker a été remplacé par une stratégie bornée.
- Les anciens tests système de nom/équipe et de verdict prématuré ont été alignés sur
  les parcours serveur actuels sans supprimer leurs contrôles géométriques ou
  d'accessibilité.

## 4. Mesures avant/après

Protocoles : tailles CSS avec `Zlib.gzip` fichier par fichier ; JS avec la fermeture
des 34 modules applicatifs réellement chargés par le Hub, hors Hotwire, et somme de
leur compression individuelle ; médias avec fichiers et manifeste ; audio avec les
entrées `PerformanceResourceTiming` du navigateur après un clic réel. Les nombres ne
sont pas extrapolés à un réseau de production.

| Mesure | Avant | Après | Différence | Gain / régression | Confiance |
| --- | ---: | ---: | ---: | ---: | --- |
| CSS Hub gzip, shell + surface + onboarding + Campus + loader | 171 260 o | 57 149 o | -114 111 o | **-66,6 %** | haute |
| `application.css` gzip | 162 622 o | 20 199 o | -142 423 o | **-87,6 %** | haute |
| JS applicatif initial Hub brut | 87 309 o | 66 598 o | -20 711 o | **-23,7 %** | haute |
| JS applicatif initial Hub gzip, modules séparés | 25 747 o | 24 639 o | -1 108 o | **-4,3 %** | haute |
| Adaptateurs globaux gzip | 15 722 o | 6 034 o | -9 688 o | **-61,6 %** | haute |
| HTML Hub brut | 74 858 o | 100 680 o | +25 822 o | **+34,5 %** | haute ; manifeste et srcsets explicites |
| HTML Hub gzip | 13 328 o | 15 853 o | +2 525 o | **+18,9 %** | haute |
| Lignes des contrôleurs | 6 419 | 5 621 | -798 | **-12,4 %** | haute |
| `fetch()` bruts dans les contrôleurs | 17 | 0 | -17 | **-100 %** | haute, gate CI |
| RAF directs dans les contrôleurs | 35 | 0 | -35 | **-100 %** | haute, gate CI |
| Globals audio applicatifs | présents | 0 | suppression | **-100 %** | haute, gate CI |
| MP3 avant geste | non mesuré réseau en baseline | 0 o | n/a | aucune régression mesurée | haute après, inconnue avant |
| Cues Hub uniques après unlock | 704 590 o déclarés | 96 804 o transférés | -607 786 o | **-86,3 %** | moyenne avant, haute après |
| Backdrop `moises`, 390 px : raster unique → AVIF portrait | 135 364 o | 16 904 o | -118 460 o | **-87,5 %** | haute, même artwork |
| Backdrop `moises`, 768 px : raster unique → AVIF paysage recomposé | 135 364 o | 23 223 o | -112 141 o | **-82,8 %** | haute, nouveau master |
| Backdrop `moises`, viewport 1440 px : raster unique → AVIF paysage 1672 | 135 364 o | 89 181 o | -46 183 o | **-34,1 %** | haute, nouveau master |
| Stockage public distribué `public/media` | 447 696 Ko | 415 856 Ko | -31 840 Ko | **-7,1 %** | haute |
| Précache service worker | aucun shell | 5 ressources | +5 | amélioration fonctionnelle | haute |

Le HTML augmente parce que le contrat de ressources, les `picture`, les trois formats
et leurs largeurs sont explicites. Cette régression est rapportée, pas masquée. Le
budget réseau avant CTA ne peut pas être obtenu en additionnant ces composants : il
reste à mesurer sur un build de staging avec compression, cache et CDN réels.

### Inventaire média final

- 440 masters privés, 377 304 374 octets source, dont six paysages Hub 1672 × 941 ;
- 434 assets logiques et 4 113 variantes générées ;
- 4 132 fichiers sous `public/media` : 1 371 AVIF, 1 384 WebP, 1 371 JPEG,
  4 MP4, 1 SVG et `.gitkeep` ;
- manifeste SHA-256 :
  `d219ac8a69f204878986f57add23db4abd84c26596119b7577d855e7c4c0504f` ;
- `media/masters/media` : 368 461 Ko, non servis ; `public/sfx` : 1 696 Ko.

La multiplication des dérivés augmente le nombre de fichiers du dépôt mais pas les
requêtes d'une page : `picture`, lazy loading et manifeste font choisir une seule
variante utile. Le gain de `public/media` mesure l'arbre distribuable, pas la taille
totale de travail incluant les masters privés.

## 5. Vérifications exécutées

- Rails complet final : 1 001 runs, 39 983 assertions, 0 failure, 0 error,
  0 skip, 77,171 s, seed `23596`, couverture 92,07 % (8 906 / 9 673 lignes).
- JavaScript final : 31 tests, 31 succès, 0 échec ; tous les JS applicatifs et vendor
  passent `node --check`.
- Système complet final : 51 runs, 5 400 assertions, 0 failure, 0 error,
  0 skip, 164,503 s, seed `2500`, couverture 45,10 % (5 025 / 11 142 lignes).
- Contrats audio/loading/CSS/média ciblés après suppression des globals : 35 runs,
  23 916 assertions, 0 failure, 0 error, 0 skip.
- Build assets recompilé après le cutover final ; aucun ancien global audio dans les
  fichiers compilés.
- Génération média déterministe : 434 assets, 4 113 sorties attendues, aucun dérivé
  périmé et hash de manifeste stable.
- `git diff --check` : passe (aucune erreur).

Les gates automatisés couvrent notamment : frontières d'import Howler/Motion, absence
de globals audio, absence de `fetch`/RAF/`new Image`, budgets CSS par route, ownership
des effets, média immutable, hashes vendor, PWA statique, Redis temps réel et cache
production hors PostgreSQL/Puma.

## 6. Recette navigateur

Le Hub a été inspecté à 390 × 844, 768 × 1024 et 1440 × 900.

| Viewport | Sélection observée | Résultat |
| --- | --- | --- |
| 390 × 844 | AVIF portrait 390 px | aucun overflow ; image 390 × 693 rendue en plein écran |
| 768 × 1024 | AVIF paysage 768 px | aucun overflow ; master Bethléem paysage distinct |
| 1440 × 900 | AVIF paysage 1672 px | aucun overflow ; master Élie paysage distinct |

Le hero critique est `eager`, `fetchpriority=high`; les autres images restent lazy.
Motion et Howler ne sont pas dans le premier écran. Aucun MP3 n'est demandé avant le
geste. Après clic : `tick` 4 949 o, `celestial_breath` 33 601 o, `chest` 26 656 o et
`level_up` 31 598 o, soit 96 804 o uniques. Après navigation Turbo vers `/legal`, le
runtime revient à `idle`, l'élément audio et le contrôleur stage disparaissent et les
feuilles de surface sont remplacées sans doublon.

Les six backdrops Hub possèdent désormais chacun un master paysage distinct de
1672 × 941, validé dans le Hub à 768 et 1440 px. Un master d'au moins 1920 px reste
souhaitable avant de qualifier les téléviseurs Full HD/4K ; le pipeline ne doit pas
inventer ce détail par upscale.

## 7. Régressions découvertes et corrigées

1. `scope` écrasait un getter Stimulus réservé ; les contrôleurs utilisent
   `effectScope` et un gate interdit la récidive.
2. Le template service worker envoyait une expression ERB littérale ; il est rendu en
   `.js.erb` et testé en intégration.
3. Les compteurs Hub tiraient Motion transitivement ; le backend numérique natif les
   garde hors du premier écran.
4. Le backend audio était encore statique ; il est importé après unlock et démonté
   sous Turbo.
5. Des consommateurs audio et le catalogue restaient globaux ; ils passent désormais
   tous par le port et le JSON de document.
6. Le palier 384 faisait choisir 768 à 390 px ; le pipeline propose désormais 390.
7. Le guide PWA et le lecteur Écritures avaient des courses de focus/sélection ; les
   imports et états d'ouverture sont attendus explicitement.
8. Reduced motion conservait des transforms inutiles ; l'état final est `none`.
9. L'invitation animait l'ancêtre d'actions `fixed` ; la recette ne transforme plus
   ce repère.
10. Des docks ou buzzers invisibles débordaient aux petits écrans ; leur géométrie et
    leurs cibles tactiles ont été corrigées.
11. Le Hub auto-scrollait la carte au chargement ; ce déplacement non sollicité a été
    supprimé.
12. Le watch paysage et le duel invitation empiétaient sur les zones sûres ; leurs
    layouts ont été bornés.
13. Une feuille Google Fonts mutée par `onload` se dupliquait à chaque visite Turbo ;
    un preload stable et un montage JS dédupliqué la remplacent.

## 8. Ce qui n'est pas mesuré

Les éléments suivants restent volontairement « non mesurés » : bytes totaux d'une
visite froide/chaude, bytes complets avant CTA, nombre de requêtes comparable avant/
après, TTFB, LCP, INP, CLS, long tasks, coût JS p95 d'une frame, mémoire, RAF du
navigateur, cache HIT/MISS CDN, pertes intermittentes et reprise après background.

Les tests prouvent une durée fondée sur le temps à 60/90/120 Hz et zéro RAF direct
dans les contrôleurs ; ils ne remplacent pas une trace Performance sur un appareil
90/120 Hz. Aucune valeur régionale ou Web Vital n'est inventée.

## 9. Gates externes avant production

1. iPhone Safari, iPadOS, Android Chrome et PWA installée : unlock, mute, première
   lecture, interruption, background/foreground, Bluetooth, bed et reprise Turbo.
2. Exécuter la même matrice sur le spike Howler. Ne basculer que s'il bat ou égale le
   backend natif sans double moteur, sur payload, latence, mémoire et fiabilité.
3. Staging depuis Europe et province du Honduras : stable, forte latence, débit
   contraint, pertes, Save-Data, offline/retry et retour réseau.
4. Vérifier sur GCS/CDN les headers immutable, Age, HIT/MISS, invalidation et absence
   de passage des médias statiques par Puma/PostgreSQL.
5. Capturer Lighthouse/Web Vitals et Performance sur les trois viewports, avec
   appareils 60/90/120 Hz, avant de signer LCP/INP/CLS/frame cost.
6. Fournir des masters paysage d'au moins 1920 px validés par la direction artistique
   avant de qualifier les téléviseurs Full HD/4K ; les six masters web 1672 px sont livrés.

## 10. Commandes de reproduction

```bash
node --test test/javascript/**/*.mjs
find app/javascript vendor/javascript -name '*.js' -type f -print0 | xargs -0 -n1 node --check
bundle exec rails test
bundle exec rails test:system
bin/rails assets:clobber
bin/rails assets:precompile
bin/rails media:build_responsive
git diff --check
```

Ce rapport ferme l'exécution locale ; il maintient les gates externes ouverts au lieu
de transformer des hypothèses en gains de production.
