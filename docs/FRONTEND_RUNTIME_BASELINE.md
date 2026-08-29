# Baseline du runtime frontend

Date : 29 août 2026

Révision de référence : `0e226a7` (`main`) avec un worktree déjà modifié.

Plan d'autorité : [FRONTEND_RUNTIME_ARCHITECTURE_PLAN.md](FRONTEND_RUNTIME_ARCHITECTURE_PLAN.md).

Cette baseline décrit l'état du worktree avant les changements du runtime frontend.
Elle ne transforme pas les modifications préexistantes en propriété de ce chantier.
Les comparaisons finales doivent rejouer les mêmes commandes sur le même environnement.

## 1. Environnement et protocole

- Ruby `3.3.12` ;
- Node `22.22.0` ;
- Rails `8.1.3.1` ;
- serveur Rails local en développement sur `127.0.0.1:3100` ;
- captures réelles à `390 × 844`, `768 × 1024` et `1440 × 900` ;
- page observée : Hub `/`, avec données de développement réalistes ;
- tailles réseau locales non compressées mesurées avec `curl` ;
- tailles compressées reproductibles mesurées avec `gzip -c` ;
- inventaire de la page observée via le navigateur intégré après chargement.

La latence locale ne représente ni l'Europe en production ni l'Amérique centrale.
TTFB, LCP, INP et cache hit régionaux restent des mesures de production à instrumenter ;
aucune valeur régionale n'est inventée dans ce document.

## 2. Non-régression initiale

| Suite | Résultat avant changement |
| --- | --- |
| `node --test test/javascript/*.mjs` | 6 tests, 6 succès, 0 échec |
| `bundle exec rails test` | 981 runs, 15 175 assertions, 0 échec, 0 erreur, 0 skip |
| couverture Rails | 92,09 % — 8 616 / 9 356 lignes |

La suite Rails a terminé en `85,28 s` avec le seed `59561`.

## 3. Poids du runtime actuel

| Ressource | Brut | Compressé reproductible | Contrat cible |
| --- | ---: | ---: | ---: |
| `application.css` | 1 002 372 o | 162 622 o | shell `<= 25 Ko`, surface totale `<= 60 Ko` |
| `duel_campus.css` | 19 756 o | 4 319 o | absent hors Campus |
| JavaScript applicatif observé sur le Hub | 87 309 o | 25 747 o | global `<= 12 Ko`, hors Hotwire |
| Hotwire observé sur le Hub | 154 551 o | à mesurer dans le build de production | dépendance plateforme versionnée |
| HTML du Hub | 74 858 o | 13 328 o | contenu utile et CTA dans la réponse initiale |
| catalogue SFX injecté dans chaque HTML | 1 325 o | non isolé | manifeste audio contextuel |

Le Hub charge `duel_campus.css` deux fois dans le DOM : une fois par le groupe `:app`
et une fois par le lien explicite du layout. Trois feuilles sont observées en comptant
la feuille de fonts distante.

## 4. JavaScript et cycle de vie

- 59 contrôleurs Stimulus ;
- 6 419 lignes JavaScript applicatives ;
- 17 appels `fetch()` dans les contrôleurs ;
- 35 occurrences de `requestAnimationFrame` ;
- 55 créations de timeout/interval contre 47 annulations explicites ;
- contrôleurs globaux : `stage press motion scripture pwa-install` ;
- `stage_controller.js` : 25 576 o ;
- `scripture_controller.js` : 27 934 o ;
- bloc global `stage + press + motion + scripture + pwa-install` : 15 722 o gzip ;
- `window.NocheLiveAudio` et `window.NocheSfx` sont encore des globals applicatifs ;
- le premier unlock appelle encore un preload de tous les cues non-bed.

Le Hub observé a chargé 22 modules JavaScript, dont `stage_controller`,
`scripture_controller`, `motion_controller` et `pwa_install_controller`, même sans
ouvrir le lecteur d'Écritures ni le guide PWA.

## 5. CSS et médias

- `public/media` : 447 696 Ko, 858 fichiers ;
- `public/sfx` : 1 696 Ko ;
- formats médias : 372 JPEG, 425 WebP, 55 PNG, 4 MP4, 1 SVG ;
- aucune variante AVIF ;
- les variantes WebP existantes changent principalement le format, pas la largeur ;
- le raster pleine résolution reste identique entre téléphone, tablette et desktop.

Le navigateur mobile `390 × 844` a observé 19 ressources image uniques totalisant
4 486 327 octets dans l'arbre local. Ce total inclut les ressources lazy proches ou
révélées par le navigateur et ne doit pas être confondu avec les bytes avant CTA.

Exemples critiques observés :

| Média | Dimensions intrinsèques | Poids |
| --- | ---: | ---: |
| hero courant `rut_noemi.webp` | 1 024 × 1 824 | 394 876 o |
| backdrop `moises-mer-rouge.webp` | 941 × 1 672 | 135 364 o |
| étude `psalms-refuge-2026.png` | master player-facing | 2 060 629 o |
| Campus `campus-scriptures-master-v1.webp` | 941 × 1 672 | 294 368 o |

Le média LCP potentiel dépasse donc le plafond mobile de 160 Ko et le Hub expose
encore des masters à un terminal de 390 px.

## 6. Audio et PWA

- le catalogue comporte 26 MP3 pour environ 1,7 Mo ;
- `timer_tension.mp3` pèse 608 757 o ;
- `study_refuge.mp3` pèse 368 348 o ;
- un `<audio preload="none">` pour l'unlock est présent sur chaque page ;
- le moteur natif est monté globalement et précharge le catalogue après unlock ;
- le service worker possède un listener `fetch` vide : ni shell offline ni stratégie
  explicite de navigation ;
- les tests push existants sont verts, mais ne caractérisent pas encore le cache
  offline du shell.

## 7. Inspection visuelle initiale

Le Hub a été rendu et inspecté à `390 × 844`, `768 × 1024` et `1440 × 900`.

- le CTA principal reste immédiatement identifiable ;
- la composition Celestial conserve son identité sur les trois largeurs ;
- aucune erreur ou warning console n'a été observé ;
- les mêmes grands rasters sont utilisés aux trois largeurs ;
- les ressources Campus et les contrôleurs Écritures/audio/PWA sont chargés alors que
  leurs interactions ne sont pas le verbe initial du Hub.

Les captures constituent une référence visuelle de non-régression pour les contrôles
après chaque cutover. Une comparaison finale doit conserver hiérarchie, contraste,
artwork, CTA, Light/Dark et comportement reduced motion.

## 8. Commandes de reproduction

```bash
node --test test/javascript/*.mjs
bundle exec rails test
gzip -c app/assets/stylesheets/application.css | wc -c
gzip -c app/assets/stylesheets/duel_campus.css | wc -c
find public/media -type f | wc -l
du -sk public/media public/sfx
```

Les mesures réseau finales doivent compléter ces commandes par un build de production,
un waterfall froid et chaud, les trois viewports, une forte latence, un débit contraint,
des pertes intermittentes et une reprise offline.
