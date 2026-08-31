# Bibliothèque personnelle — plan d’implémentation, mouvement et migration

Statut : plan produit et technique
Date : 2026-08-31
Surface canonique cible : `GET /bibliotheque`
Décision produit : la Bibliothèque remplace les agrégateurs **Parole**, **Mon parcours** et **Ma paroisse depuis la Parole**.

## 1. Résultat attendu

La Bibliothèque devient l’unique point d’entrée de premier niveau vers la lecture et l’étude des Écritures. Elle offre deux modes complémentaires :

1. **accès direct** — le joueur connaît déjà le livre, le chapitre ou le passage qu’il veut lire et le recherche en haut de la page ;
2. **accompagnement** — le flux éditorial lui indique quoi reprendre ou approfondir.

Sous cette recherche directe, le flux répond aux sept intentions suivantes :

1. reprendre la lecture en cours ;
2. approfondir un passage révélé par les résultats du Quiz ;
3. suivre les lectures de la semaine de *Viens et suis-moi* ;
4. retrouver ses signets ;
5. parcourir les quatre collections canoniques et son historique ;
6. percevoir la lecture de sa rama et rejoindre les conversations associées ;
7. replacer la semaine dans le programme annuel.

La règle de composition est non négociable :

> Une ligne = une information = une intention.

Il n’y a ni grille de widgets, ni tableau de bord, ni carte dans une carte. La priorité visuelle est toujours la prochaine lecture utile.

La recherche n’est pas une huitième ligne éditoriale : c’est un accès canonique compact placé dans le hero. Lorsqu’une lecture est en cours, « Continuer la lecture » reste la première et la plus forte destination du flux.

## 2. Périmètre de remplacement

### Surfaces rendues obsolètes

| Surface actuelle | Route actuelle | Destination cible | Comportement cible |
|---|---|---|---|
| Parole | `/parole` | `/bibliotheque` | Ouvrir la Bibliothèque au début du flux |
| Mon parcours | `/parole/historique` | `/bibliotheque#mes-ecritures` | Mettre la ligne « Mes Écritures » au focus ; les signets disposent aussi de `#mes-signets` |
| Ma paroisse depuis Parole | `/parole/paroisse/:ward_code` | `/bibliotheque#ma-rama` | Montrer uniquement la rama du profil courant, jamais celle déduite aveuglément du paramètre historique |

Ces trois surfaces ne doivent plus apparaître dans le dock, le menu, le HUD ou les liens éditoriaux une fois la migration terminée.

### Hamburger menu cible

Le hamburger suit exactement la même simplification que le dock et la navigation desktop.

| Entrée actuelle ou historique | Décision | Nouvelle destination |
|---|---|---|
| Parole | supprimer | — |
| Mon parcours | supprimer | — |
| Ma paroisse depuis Parole | supprimer | — |
| Bibliothèque | conserver comme unique entrée Écritures | `/bibliotheque` |
| Cercle | conserver comme entrée communautaire distincte | `/escrituras/cercle` |

Le bloc concerné du hamburger doit donc présenter **Bibliothèque** comme la destination personnelle de lecture et **Cercle** comme la destination de conversation. Il ne doit pas exposer les sept lignes de la Bibliothèque comme sept raccourcis concurrents.

Si le profil n’a pas accès au Cercle de sa rama, l’entrée Cercle suit ses règles d’autorisation existantes ; l’entrée Bibliothèque reste toujours disponible. Le libellé et le hint de Bibliothèque doivent être localisés en es, fr, en et pt-BR.

### Destinations qui restent actives

| Destination | Raison |
|---|---|
| `/parole/semaines/:id` | Détail éditorial d’une semaine ; destination de la ligne hebdomadaire et du programme annuel |
| `/parole/parcours/:id` | Exécution et résultat d’un parcours de Quiz |
| routes `/escrituras/*study` | Lecteur canonique et reprise à la position exacte |
| `/escrituras/cercle` | Le Cercle reste une vraie destination communautaire séparée |
| routes de signets, annotations et progression | Ce sont des capacités du lecteur, pas des pages d’agrégation concurrentes |

La suppression des trois anciennes pages ne doit donc pas entraîner la suppression des modèles `StudyProgram`, `StudyUnit`, `StudyRun`, `ScriptureReadingProgress` ou `ScriptureMark`.

## 3. Architecture d’information cible

```text
Quiz
  └─ réponse à approfondir
       └─ Bibliothèque · Recommandé pour toi
            └─ Lecteur · passage exact
                 ├─ Signet / annotation
                 └─ Conversations liées au passage
                      └─ Cercle

Bibliothèque
  ├─ Rechercher directement · « DyC 48 », « Jean 3:16 »…
  ├─ Continuer la lecture
  ├─ Recommandé pour toi
  ├─ Cette semaine · Viens et suis-moi
  ├─ Mes signets
  ├─ Mes Écritures
  ├─ Ma rama
  └─ Programme annuel
```

La Bibliothèque orchestre les destinations de profondeur. Elle ne duplique ni le lecteur, ni la chronologie complète, ni le Cercle.

### Recherche directe des Écritures

La zone de recherche est placée en haut de la Bibliothèque, dans la partie basse du hero, avant la première ligne du flux. Son libellé explicite est « Rechercher dans les Écritures ». Son exemple est localisé : `DyC 48`, `D&A 48`, `D&C 48` ou `1 Néphi 5:1` selon la langue.

Elle recherche exclusivement dans le canon disponible dans le lecteur — jamais dans les joueurs, les ramas ou les conversations.

#### Grammaire acceptée

| Saisie | Résultat attendu |
|---|---|
| `DyC 48` | Doctrine et Alliances, section 48 |
| `D&A 48` | Doctrine et Alliances, section 48 en français |
| `D&C 48` | Doctrine and Covenants, section 48, alias également reconnu dans les autres langues |
| `Doctrine et Alliances 48` | Doctrine et Alliances, section 48 |
| `Jean 3` | chapitre 3 de Jean |
| `Jean 3:16` | Jean 3, verset 16 |
| `Jean 3:16-17` | Jean 3, versets 16 à 17 |
| `1 Néphi 5` | chapitre 5 de 1 Néphi |
| `Psaumes` | suggestions de livres ou chapitres ; ne pas choisir arbitrairement un chapitre |

La résolution est insensible à la casse, aux accents typographiques, aux espaces multiples et aux tirets `-` / `–`. Elle reconnaît les noms canoniques et abréviations approuvés dans les quatre langues.

#### Comportement

- à partir de deux caractères, afficher jusqu’à six suggestions canoniques ;
- privilégier les correspondances exactes dans la langue active, puis les alias connus ;
- une correspondance exacte livre + chapitre ouvre directement le lecteur à la validation ;
- une correspondance avec verset ou plage ouvre le lecteur et cible le passage ;
- une saisie ambiguë conserve le focus et affiche des suggestions, sans navigation arbitraire ;
- une saisie invalide produit un message local et accessible avec des exemples ;
- `Échap` ferme les suggestions, les flèches les parcourent et `Entrée` choisit l’option active ;
- le bouton d’effacement mesure au moins 44 × 44 px et possède un libellé accessible ;
- la requête saisie n’est jamais conservée en clair dans les événements analytiques.

Le formulaire fonctionne sans JavaScript : une requête `GET` résout la référence côté serveur et redirige vers le lecteur, ou renvoie des suggestions. JavaScript améliore uniquement l’autocomplétion.

## 4. Contrat de données par ligne

Chaque ligne reçoit un présentateur stable comportant : `title`, `detail`, `intent`, `path`, `icon`, `progress`, `state` et, si nécessaire, `avatars`.

| Ligne | Source fiable | État principal | État vide |
|---|---|---|---|
| Continuer | dernier `ScriptureReadingProgress#resumable?` | citation localisée, dernier verset, progression, deep link lecteur | inviter à choisir une lecture canonique |
| Recommandé | `Quizzes::ReadingSuggestions` | dernier passage issu d’une réponse incorrecte terminée | annoncer qu’une recommandation suivra le prochain Quiz |
| Cette semaine | `StudyProgram#current_week` + quiz publié + lectures publiées | thème, références, chapitres terminés / total | attente honnête de publication |
| Mes signets | `ScriptureMark.active` avec `bookmarked_at` | nombre et dernier passage conservé | aucun passage conservé |
| Mes Écritures | lectures de chapitres + marques actives, groupées par canon | collection la plus avancée et nombre de chapitres | quatre collections disponibles, zéro progression |
| Ma rama | progressions terminées de membres de la rama sur les références publiées de la semaine | nombre réel et jusqu’à quatre avatars | personne n’a encore terminé ; ne jamais inventer d’activité |
| Programme annuel | semaines du `StudyProgram` publié | numéro, thème, période et progression temporelle | attente de publication du programme |

Règles d’intégrité :

- toute citation doit être reconstruite avec le nom canonique localisé du livre ;
- une copie venant d’un Quiz ou du programme n’est visible que si sa version est publiée ;
- une progression partielle ne doit jamais être annoncée comme terminée ;
- les données d’aperçu du mockup sont autorisées uniquement en développement et en test ;
- aucun nombre communautaire ne doit être dérivé du simple nombre de membres de la rama.

## 5. Composition et responsive

### Premier pli

Le hero cinématographique occupe la majorité du premier écran. Le HUD flotte au-dessus de l’artwork en Celestial Dark. Le titre et la citation sont positionnés dans une zone de contraste locale, sans voile opaque plein écran. La recherche vient ensuite sous la forme d’un seul verre Celestial Dark, suffisamment dense pour rester lisible sur le crop le plus lumineux.

La première ligne « Continuer la lecture » chevauche légèrement la fin du hero. Elle est la seule surface renforcée du flux et le seul CTA explicitement doré. Le bouton de recherche reste neutre afin de ne pas concurrencer Continuer.

### Flux

Les six autres lignes utilisent une surface papier ivoire continue, des séparateurs fins et une hiérarchie éditoriale. Elles ne deviennent pas six cartes indépendantes.

### Largeurs de référence

| Viewport | Comportement |
|---|---|
| 390 × 844 | une main, premier CTA visible au pli, dock fixe, cibles ≥ 44 px |
| 768 × 1024 | hero plus respirant, contenu plafonné, même ordre et même intention |
| 1440 × 900 | colonne monumentale centrée ; aucune conversion en grille |

Le desktop ne doit jamais juxtaposer les lignes. L’espace supplémentaire renforce l’artwork, la typographie et les marges.

## 6. Plan d’animation et de transition

### Principes

Le mouvement doit évoquer une page que l’on retrouve et une lumière qui guide. Il ne doit pas transformer la lecture en spectacle permanent.

- une seule chorégraphie d’entrée ; pas d’animation en boucle sur les lignes ;
- mouvement orienté verticalement, dans le sens de la lecture ;
- l’or signale une destination ou une progression, jamais une décoration errante ;
- aucune animation de `backdrop-filter` ;
- aucun parallax agressif ni déplacement qui gêne la lecture ;
- `prefers-reduced-motion` réduit les transitions à des fondus de 0 à 100 ms et supprime translation, lumière voyageuse et chevauchement animé.

### Entrée de la Bibliothèque

| Élément | Départ | Arrivée | Durée | Délai | Courbe |
|---|---|---|---:|---:|---|
| Artwork hero | échelle `1.025`, opacité 0,92 | échelle `1`, opacité 1 | 700 ms | 0 | `cubic-bezier(.2,.75,.2,1)` |
| Kicker | opacité 0, translation Y 8 px | état final | 260 ms | 120 ms | ease-out |
| Titre | opacité 0, translation Y 14 px | état final | 420 ms | 170 ms | courbe Noche out |
| Citation | opacité 0, translation Y 8 px | état final | 320 ms | 260 ms | ease-out |
| Recherche | opacité 0, translation Y 8 px | état final | 300 ms | 310 ms | ease-out |
| Ligne Continuer | opacité 0, translation Y 18 px | chevauchement final | 420 ms | 380 ms | courbe Noche out |
| Barre de progression | largeur 0 | valeur réelle | 520 ms | 580 ms | ease-out |

Le HUD n’est pas réanimé lors d’une navigation Turbo interne : il reste stable afin que le joueur conserve son identité spatiale.

### Révélation des lignes

Les lignes suivantes apparaissent naturellement avec le scroll. Une ligne peut effectuer une seule révélation à sa première intersection : opacité 0,96 → 1 et translation Y 8 px → 0 en 220 ms. Il n’y a ni cascade longue, ni blocage de l’interaction, ni nouvelle animation lors du retour arrière.

Sans JavaScript, toutes les lignes sont immédiatement visibles. L’animation est une amélioration progressive.

### États d’interaction

| État | Feedback |
|---|---|
| Idle | surface et intention stables |
| Hover | élévation locale de 2 px maximum et légère prise de lumière, desktop seulement |
| Pressed | échelle `0.985` pendant 90 ms, surface légèrement approfondie |
| Focus visible | anneau or contrasté de 3 px, sans déplacement |
| Loading destination | intention remplacée par un indicateur discret ; la ligne garde sa géométrie |
| Success | réservé aux mutations, par exemple création d’un signet ; pas au simple clic de navigation |
| Failure | navigation annulée, intention restaurée, message accessible global |
| Completed | progression pleine et marque calme ; jamais de confettis ni de classement |
| New | petite étoile statique ou apparition unique, puis état mémorisé |

### Mouvement de la recherche

- le focus renforce le liseré du verre en 120 ms, sans agrandir le champ ;
- le panneau de suggestions apparaît par fondu et translation Y de 6 px en 160 ms ;
- les résultats ne sont pas animés individuellement ;
- lors d’une validation exacte, l’icône de recherche devient un indicateur de chargement sans changer la géométrie ;
- la citation choisie peut partager une View Transition avec le titre du lecteur ;
- une erreur apparaît sous le champ sans secousse horizontale ;
- avec mouvement réduit, suggestions et messages apparaissent immédiatement.

### Transitions entre surfaces

Utiliser l’API View Transitions quand elle est disponible, avec un fallback Turbo instantané.

#### Quiz → Bibliothèque

- le bouton d’approfondissement ouvre `/bibliotheque#recommande` ;
- la citation du Quiz et la citation de la ligne recommandée partagent un nom de transition stable dérivé de `pack_id + question_id` ;
- la Bibliothèque se positionne sur la recommandation, la met brièvement en lumière pendant 600 ms, puis revient à son état normal ;
- ne pas rejouer toute la chorégraphie du hero lorsque l’arrivée cible une ancre profonde.

#### Bibliothèque → Lecteur

- la citation sélectionnée devient le titre d’ouverture du lecteur par une transition de texte de 240 à 320 ms ;
- le lecteur restaure exactement `reference`, `verse` et, si disponible, l’offset ;
- la ligne passe en état `loading` sans disparaître ;
- le retour navigateur restitue le scroll et le focus sur la ligne d’origine.

#### Lecteur → Cercle

- le passage reste l’objet partagé : `reference`, plage de versets et citation sont conservés ;
- le panneau Cercle entre latéralement ou depuis le bas selon la largeur, sans transition de page spectaculaire ;
- le retour au lecteur conserve la position de lecture et la sélection éventuelle.

#### Cercle → Lecteur

- un lien de passage ouvre directement le verset concerné ;
- la plage référencée reçoit un surlignage d’arrivée non clignotant pendant 1,2 seconde ;
- avec mouvement réduit, seul le contraste du surlignage change.

#### Bibliothèque → programme annuel ou collection complète

Tant que les vues détaillées historiques existent, la ligne lance une transition verticale courte vers leur contenu. À terme, si la chronologie et la collection deviennent des sous-vues de la Bibliothèque, elles s’ouvrent comme une feuille plein écran avec URL propre et bouton retour explicite. Elles ne doivent pas devenir des accordéons massifs dans le flux principal.

### Identifiants stables requis

```text
#bibliotheque
#recherche-ecritures
#continuer
#recommande
#cette-semaine
#mes-signets
#mes-ecritures
#ma-rama
#programme-annuel
```

Ces identifiants servent aux deep links, au focus d’arrivée, aux View Transitions et aux redirections des anciennes pages.

## 7. Plan technique par phases

### Phase 0 — figer le contrat

- valider l’ordre des sept lignes et les états vides ;
- valider les identifiants d’ancre et la table de redirection ;
- confirmer que « Ma rama » compte les lectures terminées, pas la simple présence ;
- obtenir l’approbation éditoriale des citations et thèmes variables ;
- conserver les captures 390, 768 et 1440 comme références visuelles.

Critère de sortie : toutes les sources de données et destinations sont décidées, sans faux contenu de production.

### Phase 1 — consolider le présentateur

- maintenir un service unique `ScriptureLibraries::Screen` ;
- éviter les requêtes dans la vue ;
- précharger progressions, signets, semaine publiée et avatars en nombre borné ;
- ajouter un état explicite par ligne : `ready`, `empty`, `unavailable`, `completed`, `new` ;
- ajouter des tests unitaires pour les sept lignes, les quatre langues et les profils invités.

Critère de sortie : une requête ne peut ni mélanger les langues, ni inventer une activité de rama, ni afficher du contenu éditorial non publié.

### Phase 1 bis — construire le résolveur canonique

- créer un service dédié, par exemple `Scriptures::QueryResolver`, indépendant de la vue ;
- générer son catalogue depuis `Scriptures::Reference::BOOKS` et les alias localisés, sans dupliquer manuellement le canon dans JavaScript ;
- résoudre livre, chapitre, verset et plage avec validation des bornes ;
- ajouter une route progressive `GET /bibliotheque/recherche?q=...` ;
- rediriger une correspondance exacte vers `scripture_path` ou `scripture_passage_path` ;
- rendre les suggestions ambiguës dans un Turbo Frame, avec une réponse HTML complète sans JavaScript ;
- ajouter une autocomplétion Stimulus avec délai de 150 à 200 ms et annulation de la requête précédente ;
- ne jamais envoyer la valeur brute de `q` aux analytics.

Critère de sortie : `DyC 48` ouvre la section 48 correcte, dans la langue active, avec ou sans JavaScript.

### Phase 2 — implémenter le mouvement

- ajouter un contrôleur Stimulus dédié, par exemple `scripture-library` ;
- utiliser des classes d’état et des événements `turbo:load`, pas des temporisations dispersées dans la vue ;
- mémoriser en `history.state` la ligne source et la position de scroll ;
- implémenter les noms de View Transition pour les citations ;
- ajouter les fallbacks sans View Transitions et sans IntersectionObserver ;
- vérifier `prefers-reduced-motion` et `forced-colors`.

Critère de sortie : aucune animation ne bloque un clic, ne modifie la géométrie après rendu ou ne se rejoue inutilement au retour.

### Phase 3 — reconnecter toute la navigation

- dock « Bibliothèque » → `/bibliotheque` ;
- navigation desktop → `/bibliotheque` ;
- hamburger / menu HUD : remplacer les éventuelles entrées « Parole », « Mon parcours » et « Ma paroisse » par une seule entrée « Bibliothèque » → `/bibliotheque` ;
- conserver « Cercle » comme ligne séparée du hamburger, soumise aux autorisations communautaires existantes ;
- ne pas dupliquer les sept lignes de la Bibliothèque dans le hamburger ;
- ne pas ajouter une entrée « Recherche » au hamburger : la recherche canonique vit en haut de la Bibliothèque ;
- sorties de Quiz « approfondir » → `/bibliotheque#recommande` ou directement au lecteur selon le contexte ;
- liens de profil, de rama et de programme qui pointaient vers les trois agrégateurs → ancres correspondantes de la Bibliothèque ;
- conserver les liens de semaine, lecteur et Cercle comme destinations de profondeur.

Critère de sortie : aucune navigation de premier niveau — dock, desktop, hamburger ou HUD — ne pointe encore vers `/parole`, `/parole/historique` ou `/parole/paroisse/:ward_code`.

### Phase 4 — déprécier sans casser

Créer un contrôleur de redirection explicite ou conserver temporairement les anciens contrôleurs avec une réponse de redirection.

1. pendant une version, utiliser une redirection temporaire `302` et journaliser l’origine ;
2. surveiller les liens entrants, favoris et erreurs pendant au moins un cycle de publication ;
3. corriger les liens internes et campagnes encore actifs ;
4. passer à `301` quand aucun retour arrière produit n’est prévu ;
5. retirer ensuite les vues et CSS devenus inutiles, mais garder les noms de routes historiques tant que des liens externes existent.

Les redirections doivent conserver les paramètres de langue et les paramètres de campagne autorisés. Elles ne doivent jamais exposer une rama différente de celle du profil courant.

Critère de sortie : les anciennes URL conduisent au bon contexte sans boucle, sans 404 et sans fuite inter-rama.

### Phase 5 — supprimer le code mort

Après stabilisation des redirections :

- supprimer la vue d’agrégation `study_programs/show` si elle n’est plus utilisée ailleurs ;
- extraire ou déplacer la chronologie annuelle encore nécessaire ;
- supprimer la présentation de `study_histories/show` uniquement après disponibilité de la collection complète et des signets depuis la Bibliothèque ;
- supprimer `study_communities/show` uniquement après parité fonctionnelle de « Ma rama » et de ses accès au Cercle ;
- nettoyer les CSS, traductions et tests propres aux trois anciennes présentations ;
- ne pas supprimer les services ou modèles utilisés par les pages détaillées conservées.

Critère de sortie : aucune constante, route profonde ou test de lecture n’est supprimé par confusion avec les anciennes pages d’agrégation.

## 8. Stratégie de redirection détaillée

| Ancienne requête | Nouvelle requête | Focus |
|---|---|---|
| `GET /parole` | `GET /bibliotheque` | hero puis Continuer |
| `GET /parole#mi-recorrido` | `GET /bibliotheque#programme-annuel` | programme annuel |
| `GET /parole/historique` | `GET /bibliotheque#mes-ecritures` | progression canonique |
| `GET /parole/historique#study-highlights-title` | `GET /bibliotheque#mes-signets` | signets |
| `GET /parole/historique#study-scripture-progress-title` | `GET /bibliotheque#mes-ecritures` | collections |
| `GET /parole/paroisse/:ward_code` | `GET /bibliotheque#ma-rama` | rama du profil courant |

Un fragment URL n’est pas envoyé au serveur. Les anciens fragments produits par l’application doivent donc être remplacés dans les générateurs de liens avant le déploiement. Pour les favoris externes contenant un fragment, la redirection serveur ne peut pas le lire : un petit adaptateur client temporaire sur la page de redirection peut traduire les deux fragments connus avant de disparaître.

## 9. Accessibilité et performance

- cibles tactiles ≥ 44 × 44 px ;
- ordre DOM identique à l’ordre visuel ;
- recherche implémentée comme combobox accessible avec un vrai `<label>`, `aria-expanded`, `aria-controls` et une liste d’options ;
- une seule balise `h1`, puis libellés de lignes structurés ;
- barres de progression avec nom, minimum, maximum et valeur ;
- avatars décoratifs si les noms ne sont pas nécessaires à la compréhension ;
- annonces de chargement et d’échec via une région accessible existante ;
- focus programmatique uniquement lors d’une arrivée par deep link ;
- aucune dépendance à la couleur pour distinguer terminé, nouveau ou indisponible ;
- image hero responsive, préchargée uniquement sur cette surface ;
- pas de chargement anticipé de toutes les semaines ou de tout le Cercle ;
- budget mouvement : aucune animation continue et aucun layout shift après le premier rendu.

## 10. Tests et preuves obligatoires

### Tests de service

- résolution de `DyC 48`, `D&A 48`, `D&C 48` et des noms longs selon la langue ;
- résolution livre + chapitre, chapitre + verset et plage de versets ;
- normalisation de casse, accents, espaces et types de tirets ;
- rejet des chapitres et versets hors limites ;
- classement déterministe des ambiguïtés ;
- reprise exacte du dernier chapitre réellement reprenable ;
- recommandation localisée depuis une réponse incorrecte ;
- absence de recommandation sans Quiz terminé ;
- progression hebdomadaire calculée sur les lectures publiées ;
- signets limités au profil courant ;
- quatre collections correctement regroupées ;
- Rama limitée à la rama courante et aux lectures terminées ;
- semaine annuelle correcte aux changements de semaine et d’année.

### Tests de contrôleur et de routage

- recherche exacte redirigée vers le lecteur canonique ;
- recherche ambiguë rendue comme suggestions ;
- recherche invalide accessible et sans redirection arbitraire ;
- recherche fonctionnelle sans JavaScript ;
- Bibliothèque disponible en es, fr, en et pt-BR ;
- sept lignes, une seule ligne prioritaire ;
- anciennes routes redirigées vers la bonne ancre ;
- paramètres de langue conservés ;
- aucun `ward_code` historique ne permet de lire une autre rama ;
- routes semaine, parcours, lecteur et Cercle toujours fonctionnelles.

### Tests système

- captures 390 × 844, 768 × 1024 et 1440 × 900 ;
- `DyC 48` saisi depuis la Bibliothèque ouvre Doctrine et Alliances 48 ;
- navigation clavier complète de la combobox et fermeture avec Échap ;
- autocomplétion annulant correctement une requête précédente plus lente ;
- premier CTA visible au pli mobile ;
- hamburger ouvert : une seule entrée Bibliothèque, aucune entrée Parole / Mon parcours / Ma paroisse ;
- hamburger ouvert : Cercle reste distinct de Bibliothèque et respecte l’autorisation de la rama ;
- dock, navigation desktop et hamburger conduisent tous à la même route canonique `/bibliotheque` ;
- navigation clavier et focus visible ;
- retour lecteur → Bibliothèque avec scroll restauré ;
- arrivée Quiz → recommandation ciblée ;
- mouvement réduit sans translation ;
- aucune erreur console sévère ;
- absence de layout shift pendant la chorégraphie d’entrée.

### Validation éditoriale

- citation hero et thème hebdomadaire approuvés dans les quatre langues ;
- aucune copie de démo en production ;
- les nombres du programme proviennent du contenu publié, même s’ils diffèrent du mockup ;
- verdict Conseil Noche documenté avec toutes les dimensions ≥ 8/10.

## 11. Observabilité et déploiement

Événements minimaux, sans contenu scripturaire privé :

```text
scripture_library.view
scripture_library.search_submitted   resolution=exact|ambiguous|invalid
scripture_library.row_opened          row_key, state
scripture_library.resume_opened       has_progress
scripture_library.recommendation_opened
scripture_library.circle_opened       source=row_rama|reader_passage
scripture_library.legacy_redirect     legacy_route
```

Ne jamais journaliser le texte d’une note personnelle, le contenu sélectionné ou l’identité des lecteurs affichés.

Indicateurs de réussite :

- hausse des reprises exactes dans le lecteur ;
- part des ouvertures directes réussies depuis la recherche canonique ;
- hausse des passages ouverts depuis une recommandation de Quiz ;
- baisse des retours immédiats depuis la Bibliothèque ;
- usage maintenu ou amélioré des signets, semaines et conversations ;
- zéro 404 sur les anciennes routes ;
- zéro accès inter-rama introduit par la migration.

## 12. Definition of Done

La migration est terminée lorsque :

- `/bibliotheque` est l’unique destination Écritures de premier niveau ;
- la recherche supérieure ouvre toute référence canonique valide, dont `DyC 48`, avec ou sans JavaScript ;
- le hamburger ne contient qu’une entrée Bibliothèque pour ce périmètre, avec Cercle séparé ;
- les sept intentions fonctionnent avec données réelles et états vides honnêtes ;
- les transitions Quiz ↔ Bibliothèque ↔ Lecteur ↔ Cercle conservent le passage comme objet commun ;
- le mouvement est vérifié en mode normal et réduit ;
- Parole, Mon parcours et Ma paroisse depuis Parole ne sont plus accessibles comme surfaces concurrentes ;
- leurs anciennes URL redirigent correctement ;
- les routes profondes nécessaires restent actives ;
- les quatre langues, trois viewports et états d’accessibilité sont verts ;
- la revue éditoriale et la revue Conseil Noche sont approuvées.
