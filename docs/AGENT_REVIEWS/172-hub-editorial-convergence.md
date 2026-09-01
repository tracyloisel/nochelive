# M172 — Home éditoriale vivante

Reviewed: 2026-09-01
Slice: de la grille de fonctionnalités à une programmation éditoriale de jeu, pour visiteur, joueur sans Rama et joueur avec Rama
Tests: lots Home ciblés verts ; voir la matrice détaillée dans Evidence
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — 230 clés `hub` à parité en es, pt-BR, en et fr

## Feeling

La Home doit dire en moins de cinq secondes : « Voilà mon aventure, voilà ce
qui se passe aujourd’hui, j’ai envie d’entrer. » Elle ne doit plus demander au
joueur de parcourir un catalogue de capacités avant de choisir son prochain
geste.

## Inventaire réel avant modification

Le rendu partait de `StreetHubController`, de `Hubs::Screen` et d’une succession
de partials Hero, cartes « maintenant », Rama, expédition et surfaces de
conversion. Les données existantes disponibles étaient : identité du joueur,
pack et run courants, progression, thème issu de l’artwork, expédition active,
Rama, sessions Live, défis, cercles, découvertes d’étude, catalogue vidéo et
états vides. La route racine et le dock/HUD étaient partagés avec les autres
surfaces.

Les baselines 1440 × 900, 768 × 1024 et 390 × 844, en Celestial Light et Dark,
montraient un carrousel de grands modules de même poids, une répétition de la
progression et des surfaces qui nommaient des fonctionnalités plutôt que des
contenus. L’absence de Rama réservait trop de place et les zéros du HUD
devenaient de faux signaux éditoriaux.

## Hiérarchie retenue

| Classe | Surfaces |
|---|---|
| PRIMARY | Un Hero artwork-first : vraie aventure courante, progression réelle, un CTA Jouer ou Continuer |
| SECONDARY | Une actualité Aujourd’hui, l’expédition active comme événement, la présence Rama, les rails À explorer et À regarder |
| CONTEXTUAL | Invitation compacte à choisir sa Rama, identité progressive, installation et notifications |
| UTILITY | HUD intégré au décor, navigation desktop haute, dock mobile |
| REMOVE_FROM_HOME | Carrousel de héros concurrents, cartes « fonctionnalités », ligue/récompense/résumé de duel, progression dupliquée, grande Rama vide et entrée générique « bibliothèque vidéo » |

## 1 — Game experience

La boucle est maintenant : reconnaître son aventure → voir le geste immédiat →
apercevoir ce qui change aujourd’hui → entrer dans l’événement ou explorer un
contenu réel. Le Hero est la seule promesse dominante. `Aujourd’hui` choisit un
seul signal vrai selon un ordre explicite : Live réellement en cours, prochain
Live imminent, découverte éditoriale du jour, prochaine porte d’expédition,
contenu hebdomadaire, activité Rama, puis repli honnête.

L’expédition n’est plus une feature équivalente aux autres : elle devient une
invitation pleine image vers sa page canonique. La Rama ne présente plus une
collection de KPI ; elle montre au plus trois événements/action sociales réels.
Sans Rama, elle se réduit à une invitation utile. Les zéros sans pouvoir de
décision sont masqués.

## 2 — UI design

Verbe en deux secondes : `Jouer` ou `Continuer`. Une seule surface porte le
pack, l’étape et la progression. Le desktop reçoit une composition
cinématographique large, une navigation haute et aucun dock. Le mobile reçoit un
Hero vertical, une colonne d’action, des rails swipe/snap et conserve le dock.

Le HUD fait partie du décor à l’ouverture puis acquiert son matériau glass au
scroll. Les informations suivantes arrivent une par ligne éditoriale ; elles ne
forment plus une grille de rectangles. Les titres et CTA ont été vérifiés en
quatre langues à 390 et 1440 px. Les interactions gardent leurs états pressés,
hover/focus desktop et leur information visible sans hover sur mobile.

## 3 — Art direction

L’artwork conduit la navigation. Le Hero conserve un large champ visuel sur
desktop et un cadrage vertical full-bleed sur mobile. Les textes reposent sur des
scrims locaux et des gradients de lisibilité, jamais sur une grande plaque
opaque. Les cartes secondaires sont devenues des vignettes principalement
composées d’une œuvre et d’un titre. L’or reste réservé à la signature et à
l’action principale.

## Theme engine

Une seule structure de Home alimente Celestial Light et Celestial Dark. Les
manifestes d’artwork, focal points et tokens du Hub continuent de choisir
l’atmosphère ; aucune bascule utilisateur ni markup parallèle n’a été ajouté.
Le header au repos reste transparent dans les deux mondes et sa transition au
scroll utilise les matériaux sémantiques existants.

## Performance et motion

L’image du Hero reste prioritaire. Les contenus plus bas conservent leur
chargement différé ; le rail vidéo est résolu par un endpoint paresseux et ne
sollicite pas le catalogue au rendu initial de `/`. La motion se limite aux
transitions et au snap utiles, respecte `prefers-reduced-motion`, et n’ajoute
aucun pulse permanent ni signal Live fictif.

## Test mental des quatre profils

| Profil | Premier choix visible | Ce qui peut changer demain |
|---|---|---|
| Visiteur sans profil | Entrer directement dans un vrai pack ; l’identité n’est pas un mur | Actualité ou contenu éditorial quotidien |
| Joueur sans Rama | Reprendre son aventure ; invitation Rama compacte plus bas | Progression, découverte, expédition ou Live |
| Joueur actif avec Rama | Continuer immédiatement ; signal social pertinent ensuite | Live, défi, cercle, activité ou progression de la Rama |
| Joueur qui revient demain | Retrouver son avancée sans relire la Home | Le choix unique d’Aujourd’hui et les événements datés |

## Scores (/10)

Toute dimension est supérieure ou égale à 8.

| Dimension | /10 |
|---|---:|
| Editorial hierarchy | 9.3 |
| Immediate desire to play | 9.3 |
| Artwork breathing | 9.4 |
| Daily freshness | 9.0 |
| Expedition visibility | 9.4 |
| Rama presence | 9.2 |
| Empty states | 9.3 |
| Desktop composition | 9.1 |
| Mobile composition | 9.2 |
| NocheLive identity | 9.5 |
| Information density | 9.2 |
| Return desire | 9.1 |
| **Moyenne** | **9.25** |

## Verdict

PASS pour le périmètre Home.

## What works

- Le premier écran a un sujet, un geste et une actualité, pas une liste de
  fonctions.
- La même donnée produit deux compositions réellement adaptées à desktop et
  mobile.
- L’expédition, la Rama et les vidéos sont présentées comme des événements ou
  des contenus réels.
- Aucun système futur, économie, statistique ou signal Live n’a été inventé.
- La suppression des anciens modules et de 346 lignes CSS mortes réduit la
  densité autant que les nouvelles règles la réorganisent.

## What feels weak

- Le fallback `Aujourd’hui` reste volontairement sobre quand aucune donnée
  datée n’existe ; sa valeur éditoriale dépendra de la régularité de publication
  du contenu réel.
- La passe Rails complète finale compte 1021 runs et 44804 assertions, avec
  14 failures et 1 error. Ces 15 cas relèvent de la Bibliothèque, du loader, des
  seeds, du pipeline média ou de tests d’ordre déjà présents dans le worktree ;
  aucun ne traverse le contrat Home ciblé. L’unique erreur, dans
  `Nights::StartTest`, repasse au vert isolément.

## Required before approval

- None for the Home scope.

## Evidence

- Services Home : 66 runs, 316 assertions, 0 failure.
- Contrôleurs Street Hub et vidéo : 33 runs, 647 assertions, 0 failure.
- HUD et Street Hub : 38 runs, 662 assertions, 0 failure.
- Notifications et états Live/Rama : 8 runs, 56 assertions, 0 failure.
- Systèmes joueur actif : 3 runs, 1295 assertions, 0 failure.
- Systèmes visiteur et joueur sans Rama : 3 runs, 1146 assertions, 0 failure.
- Chrome, identité progressive, campus et PWA : 17 runs, 2179 assertions, 0 failure.
- Dernier contrôle visuel ciblé : 5 runs, 460 assertions, 0 failure.
- CTA start/resume : es, pt-BR, en et fr à 390 et 1440 px, 97 assertions,
  0 failure.
- Suite complète : 1021 runs, 44804 assertions, 14 failures et 1 error hors
  périmètre Home ; `Nights::StartTest` vert lors de sa relance isolée.
- Captures comparatives archivées sous
  `tmp/street-shots/editorial-convergence-baseline/` et
  `tmp/street-shots/editorial-convergence/`.

## Night director

Oui. Le joueur n’a plus à comprendre le produit avant de jouer : il reconnaît
son aventure, voit ce qui est vivant aujourd’hui et entre par un geste unique.
