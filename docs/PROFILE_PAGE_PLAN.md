# Plan produit et technique — Fiche profil joueur

Statut : profil et historique privé des réponses livrés
Dernière mise à jour : 30 août 2026
Surface principale : `GET /jugadores/:player_id/perfil`
Sas de sélection et création : `GET|POST /ficha`
Périmètre MVP : consultation du profil, modification des données canoniques, changement de paroisse et consultation de ses réponses Aventure/Parole

## 1. Décision

La page `/jugadores/:player_id/perfil` est la fiche personnelle de référence du joueur. `/ficha` reste le sas de sélection, de réclamation et de création, puis redirige une personne déjà reconnue vers son URL explicite.

Elle ne doit plus être principalement un formulaire. Elle doit d’abord permettre au joueur de comprendre, en moins de deux secondes :

1. qui il est dans Noche Live ;
2. à quelle paroisse il est associé ;
3. où il en est dans son aventure ;
4. quelles données il peut corriger ;
5. où retrouver ses historiques et ses préférences.

La lecture devient l’état par défaut. L’édition est contextuelle, champ par champ. Les historiques détaillés restent dans les surfaces qui leur sont déjà consacrées.

Le MVP doit rendre accessibles les six données canoniques de `Person` :

- prénom de jeu : `given_name` ;
- nom : `family_name` ;
- avatar : `avatar_key` ;
- année favorite : `favorite_year` ;
- langue : `locale` ;
- paroisse associée : `ward_id`.

La date de création de la fiche est consultable, mais non modifiable. Les données canoniques de la paroisse ne sont pas éditées depuis cette page : le joueur modifie uniquement son association à une paroisse.

## 2. Références visuelles validées

- Vue principale : [`tmp/street-shots/temple-mockups/mockup-street-profile-celestial-light.png`](../tmp/street-shots/temple-mockups/mockup-street-profile-celestial-light.png)
- Édition du prénom : [`tmp/street-shots/temple-mockups/mockup-street-profile-edit-name-celestial-light.png`](../tmp/street-shots/temple-mockups/mockup-street-profile-edit-name-celestial-light.png)
- Destination Parole : [`tmp/street-shots/temple-mockups/mockup-street-profile-parole-celestial-light.png`](../tmp/street-shots/temple-mockups/mockup-street-profile-parole-celestial-light.png)

Ces images fixent la hiérarchie, les comportements et le langage Celestial Light. Les chiffres, titres de rang et contenus illustratifs qu’elles contiennent ne constituent pas des règles métier approuvées.

## 3. Objectifs

### Objectifs joueur

- Voir toutes les informations personnelles utiles que Noche Live associe à sa fiche.
- Comprendre la différence entre identité, appartenance, progression et données privées.
- Corriger une donnée sans entrer dans un long formulaire.
- Changer de paroisse sans perdre sa progression.
- Accéder directement à Aventure, Parole, Défis et Notifications.
- Savoir comment demander une copie ou l’effacement de ses données.

### Objectifs produit

- Faire du profil un point de confiance et de transparence.
- Réduire les profils dupliqués provoqués par des informations difficiles à corriger.
- Réutiliser les services et historiques existants au lieu de créer un second système.
- Ne pas exposer d’identifiants techniques autres que l’ID joueur explicitement approuvé, ni jetons ou événements techniques bruts.
- Respecter les engagements déjà formulés dans la politique de confidentialité.

### Non-objectifs du MVP

- Créer un compte avec e-mail et mot de passe.
- Permettre au joueur de modifier le nom, l’adresse ou les horaires canoniques d’une paroisse.
- Afficher chaque enregistrement technique de la base de données.
- Automatiser immédiatement l’export et l’effacement RGPD.
- Inventer un nouveau score spirituel, un niveau ou un rang sans source métier approuvée.
- Remplacer les écrans Carte, Parole, Défis ou Notifications.

## 4. État actuel

### Surface joueur

- `config/routes.rb` sépare le sas `GET|POST /ficha` de la ressource explicite `GET|PATCH /jugadores/:player_id/perfil`.
- `StreetProfilesController#show` choisit actuellement entre création, reconnaissance, réclamation, sélection de fiche et édition.
- L’ancien grand formulaire se trouvait dans `app/views/street_profiles/_edit.html.erb`; il a été retiré après validation des micro-éditeurs.
- Le formulaire actuel permet seulement de modifier `given_name` et `avatar_key`.
- `StreetProfilesController#update` met directement à jour `Person`, puis recopie le prénom et l’avatar sur tous les `players`.

### Services déjà disponibles

- `People::Update` sait modifier le prénom, le nom, l’avatar et l’année favorite dans une transaction.
- `Locales::Set` sait modifier la langue de la personne et la propager aux participations Live concernées.
- `People::Transfer` sait changer la paroisse et remettre `last_ward_team` à `nil`.
- `StreetWardPicksController` réutilise déjà `People::Transfer` après la sélection d’une paroisse.

### Identité actuelle

- La personne courante est retrouvée avec le cookie signé `noche_street_person`.
- L’accès n’est accepté que si un `PersonDevice` relie cette personne au cookie signé `noche_device`.
- Il n’existe pas encore de compte personnel durable indépendant d’un appareil.
- La réclamation d’une fiche sur un nouvel appareil utilise actuellement `favorite_year` comme vérification dans `People::Claim`.

### Engagement de confidentialité existant

La politique de confidentialité indique déjà que le joueur peut voir ses données, les corriger, demander leur effacement et en demander une copie. Le profil doit donc fournir une entrée visible vers ces droits, même si la copie et l’effacement restent d’abord traités manuellement.

## 5. Architecture d’information cible

### 5.1 En-tête et identité de jeu

Afficher :

- avatar ;
- prénom de jeu ;
- rang et niveau uniquement si une source métier stable existe ;
- couronnes totales ;
- série d’activité ;
- place actuelle dans la paroisse, si calculable sans ambiguïté ;
- date d’arrivée dans Noche Live en information secondaire.

Action principale : `Modifier ma fiche`.

Règle : un seul bouton doré principal dans la vue. Les lignes modifiables restent également accessibles individuellement.

### 5.2 Mon identité

Afficher et permettre de modifier :

- Prénom ;
- Nom ;
- Avatar ;
- Année favorite ;
- Langue.

Afficher sans modification :

- Date de création de la fiche ;
- Date de dernière modification uniquement dans « Mes données », si elle apporte une valeur réelle au joueur.

### 5.3 Ma paroisse

Afficher, quand les données existent :

- nom de la paroisse ;
- type d’unité : branche ou paroisse ;
- ville ;
- nom et adresse de la chapelle ;
- horaires du dimanche ;
- pieu ;
- pays ;
- lien vers la carte de la chapelle.

Permettre au joueur de modifier seulement l’association `Person#ward` avec l’action `Changer`.

Ne pas permettre l’édition des données de `Ward` depuis le profil joueur. Une donnée de paroisse incorrecte doit être signalée ou corrigée dans un flux administré séparément.

### 5.4 Mon histoire

La page affiche des résumés cliquables, pas des listes techniques.

#### Aventure

Afficher :

- nombre de parcours ou packs terminés ;
- couronnes totales ;
- meilleurs scores utiles ;
- série d’activité actuelle ;
- progression débloquée.

Destination : `street_map_path` (`GET /mapa`).

#### Parole

Afficher :

- nombre de semaines ou parcours commencés et terminés ;
- chapitres étudiés par collection ;
- nombre de passages surlignés ;
- semaine en cours.

Destination : `study_history_path` (`GET /parole/historique`).

Les textes surlignés et le détail des lectures sont privés. Ils ne doivent pas apparaître sur une surface publique ou dans la paroisse.

#### Mes réponses

Afficher dans la fiche un résumé cliquable comprenant le nombre total de réponses et le nombre de bonnes réponses.

Destination : `player_quiz_history_path(person)` (`GET /jugadores/:player_id/perfil/respuestas`).

La destination regroupe uniquement les quiz qui possèdent une vérité métier objective et un temps par question :

- Aventure : `QuizAnswer`, relié au joueur par `QuizRun#person_id` ;
- Parole : `StudyAnswer`, relié au joueur par `StudyRun#person_id`.

Pour chaque réponse, afficher la source, la date du parcours, la question, la réponse donnée, la bonne réponse, le verdict bonne/mauvaise réponse et le temps passé. La référence scripturaire est affichée lorsqu’elle existe. Les parcours sont regroupés en sessions et paginés par huit sessions.

Les réponses Live ne font pas partie de cette destination : plusieurs formats Live sont des buzz, mimes ou actions d’équipe sans verdict individuel canonique ni durée de question homogène. Elles ne pourront être ajoutées qu’après définition d’un contrat métier commun.

L’historique est strictement privé au joueur reconnu sur l’appareil. Il n’est jamais affiché dans la paroisse, le classement ou une surface présentateur.

#### Défis

Afficher :

- défis actifs ;
- invitations en attente ;
- victoires et résultats terminés si le calcul est déjà défini par le moteur de défis.

Destination : `street_challenges_path` (`GET /desafios`).

#### Nuits en direct

Prévoir en étape ultérieure :

- nuits auxquelles la personne a participé ;
- rôle et lieu de participation ;
- équipe rejointe ;
- résultats collectifs et actions de jeu pertinentes.

Ne pas transformer un score d’équipe en mérite individuel. Cette famille n’entre pas dans le MVP tant qu’une destination dédiée et des règles de conservation n’ont pas été validées.

### 5.5 Notifications et mes données

Afficher une ligne d’accès vers :

- préférences de notifications ;
- état des notifications de cet appareil ;
- politique de confidentialité ;
- procédure pour obtenir une copie ;
- procédure pour demander un effacement ;
- profils reconnus sur cet appareil ;
- fusion de profils existante.

Destination notifications : `notification_settings_path` (`GET /notifications`).

Destination confidentialité : `privacy_path` (`GET /privacidad`).

## 6. Contrat d’accès aux données

### Données modifiables depuis la fiche

- `Person#given_name`
- `Person#family_name`
- `Person#avatar_key`
- `Person#favorite_year`
- `Person#locale`
- `Person#ward_id`, via le flux de sélection de paroisse

### Données consultables, mais non modifiables depuis la fiche

- `Person#id`, présenté comme « ID joueur » uniquement dans la fiche privée reconnue
- `Person#created_at`
- `Person#updated_at`, si affiché dans « Mes données »
- progression, détail des réponses et agrégats de `QuizRun` et `QuizAnswer`
- progression, détail des réponses de quiz, `StudyRun`, `StudyAnswer` et `ReadingProgress`
- lectures de `ScriptureChapterRead`
- surlignages de `ScriptureHighlight`
- défis et invitations associés à la personne
- participations Live associées à `Player`
- état lisible des préférences et abonnements de notifications
- présence des appareils liés et leur dernière activité

### Données privées au joueur

- identifiant numérique du joueur et date de création du profil ;
- année favorite ;
- langue ;
- lectures et surlignages ;
- préférences de notifications ;
- liste des appareils ;
- détails d’export ou d’effacement.

### Données visibles dans la paroisse selon les règles du jeu

- prénom de jeu ;
- avatar ;
- couronnes et rang ;
- présence de jeu utile ;
- résultats de défis nécessaires à la compétition.

### Données accessibles aux présentateurs autorisés

- données nécessaires pour distinguer, corriger ou fusionner une fiche ;
- année favorite seulement dans le flux d’assistance existant, jamais sur l’écran TV.

### Données à ne jamais afficher brutes

- identifiants internes des autres enregistrements ; l’exception explicitement approuvée est `Person#id`, présenté comme « ID joueur » dans la fiche privée reconnue ;
- cookies et jetons d’appareil ;
- `device_token` et digests ;
- jetons de présentation ;
- endpoints et clés Web Push ;
- données chiffrées de notification ;
- clés d’idempotence ;
- propriétés techniques de `ViralEvent` ;
- traces serveur ou adresses IP.

Dans un futur export, ces éléments doivent être soit omis pour raison de sécurité, soit traduits en événements humains compréhensibles.

## 7. Comportements d’interface

### 7.1 Ouverture de la fiche

- Si une personne est reconnue sur l’appareil, `/ficha` ouvre la vue en lecture.
- Si aucune personne n’est reconnue, les flux existants de création, choix et réclamation restent disponibles.
- Le profil ne doit plus exiger `?edit=1` pour être utile.
- L’ancien `?edit=1` n’est plus émis ; une valeur d’éditeur inconnue est ignorée et rend simplement la fiche en lecture.

### 7.2 Clic sur « Prénom »

- Ouvrir un panneau contextuel au-dessus de la fiche encore visible.
- Placer immédiatement le focus dans le champ.
- Préremplir la valeur actuelle.
- Afficher la limite `24` caractères.
- Proposer une seule action principale : `Enregistrer`.
- Proposer `Annuler` comme action calme.
- Fermer le panneau après succès et mettre à jour le hero et la ligne sans rechargement visuel brutal.
- En cas d’échec, conserver la saisie, placer le message près du champ et remettre le focus sur le problème.

### 7.3 Clic sur « Parole »

- Naviguer vers `study_history_path`.
- Afficher le dock avec `Parole` actif.
- Donner la priorité au parcours, au nombre de semaines terminées et à l’action de reprise.
- Conserver l’accès aux chapitres étudiés, à la semaine actuelle et aux passages surlignés.
- Ne pas créer un second historique dans la fiche.

### 7.4 Clic sur « Paroisse » ou « Changer »

- Ouvrir `search_path(cambiar: 1)`.
- Conserver en session un retour explicite vers la fiche.
- Avant la validation, expliquer que la progression et les couronnes restent avec la personne, mais que le classement et la communauté visibles changent.
- Après succès, revenir à `/ficha` avec la nouvelle paroisse et un message de confirmation.
- En cas d’échec, rester dans le sélecteur avec une erreur actionnable.

### 7.5 États obligatoires

Chaque éditeur doit spécifier et tester :

- repos ;
- focus ;
- saisie ;
- validation en cours ;
- succès ;
- erreur de validation ;
- erreur serveur ;
- perte de la fiche courante ;
- annulation ;
- réduction des animations.

Les sections historiques doivent aussi gérer :

- aucune donnée ;
- données partielles ;
- chargement ;
- destination indisponible.

## 8. Plan technique

### 8.1 Présentation des données

Créer `StreetProfiles::Snapshot`, un objet de présentation en lecture seule qui reçoit `person:` et retourne les données déjà agrégées pour la vue.

Responsabilités recommandées :

- identité canonique ;
- paroisse et horaires ;
- couronnes et progression Aventure ;
- nombre de parcours Parole ;
- résumé des défis ;
- statut des notifications ;
- nombre d’appareils liés ;
- destinations disponibles.

Contraintes :

- ne pas mettre les agrégations dans le template ERB ;
- éviter les requêtes par ligne et les N+1 ;
- utiliser des `count`, `sum`, `maximum` et agrégations ciblées ;
- ne pas persister des compteurs dérivés tant qu’un besoin de performance n’est pas démontré ;
- couvrir l’objet par des tests unitaires avec profil vide, partiel et complet.

### 8.2 Contrôleur

Adapter `StreetProfilesController#show` :

- conserver les écrans existants pour les personnes non reconnues ;
- utiliser un nouvel état `:profile` pour une personne reconnue ;
- construire `@snapshot` pour cet état ;
- interpréter un paramètre d’édition strictement autorisé, par exemple `?edit=given_name` ;
- refuser toute clé d’édition non reconnue ;
- toujours dériver la personne de `current_street_person`, jamais d’un `person_id` fourni pour l’édition.

Adapter `StreetProfilesController#update` :

- accepter seulement les attributs canoniques autorisés ;
- utiliser un service unique pour la validation et la propagation ;
- répondre en HTML complet et, si le projet conserve Turbo sur cette surface, par Turbo Frame ;
- renvoyer `422 Unprocessable Entity` pour les erreurs de validation ;
- ne jamais changer `ward_id` dans cette action.

### 8.3 Mise à jour canonique

Consolider les mises à jour joueur sur `People::Update` au lieu de garder la logique directe actuelle dans le contrôleur.

Le service doit supporter une mise à jour partielle explicite sans remplacer les champs absents par des valeurs vides. Une sentinelle d’attribut absent est préférable à l’utilisation de `nil`, car `nil` peut être une valeur métier autorisée pour `family_name` ou `favorite_year`.

Le service doit continuer à :

- normaliser et limiter prénom et nom à 24 caractères ;
- valider l’avatar ;
- valider l’année favorite ;
- recalculer les clés de nom via les callbacks de `Person` ;
- synchroniser prénom, avatar et langue avec les participations Live qui doivent refléter le profil canonique ;
- effectuer l’ensemble dans une transaction ;
- préserver les usages du bureau de fiches (`FichaDesk`).

Pour la langue, appeler `Locales::Set.call(person:, locale:)` puis `remember_locale(locale)` afin d’aligner la fiche, les participations et le navigateur.

#### Garde-fous Active Record livrés

`Person` reste la frontière canonique, y compris pour les écritures qui ne passent pas par les services HTTP :

- prénom, clé de prénom, avatar et langue obligatoires ;
- prénom et nom limités à 24 caractères, sans caractères de contrôle ;
- espaces extérieurs retirés et suites d’espaces ordinaires normalisées avant le calcul des clés ;
- avatar limité à `Player::AVATARS` et langue limitée à `Locale::AVAILABLE` ;
- année favorite facultative, entière, comprise entre 1000 et l’année courante ;
- nom, année et paroisse toujours facultatifs pour les profils progressifs ;
- équipe de paroisse mémorisée obligatoirement rattachée à la paroisse courante ; un changement ou retrait de paroisse nettoie automatiquement cette équipe ;
- aucune validation d’unicité entre homonymes, conformément au fonctionnement familial et au flux de fusion.

La constante `Person::NAME_MAX` est partagée par `People::Register` et `People::Update` afin d’éviter une dérive entre formulaire, service et modèle.

### 8.4 Changement de paroisse

Conserver `People::Transfer` comme unique service métier.

Ajouter la destination `profile` au mécanisme `session[:street_return]` :

- la fiche place `session[:street_return] = "profile"` avant d’ouvrir le sélecteur ;
- `StreetWardPicksController#redirect_after_ward_pick` renvoie vers `player_profile_path(person)` pour cette destination ;
- `People::Transfer` conserve toutes les progressions et remet `last_ward_team` à `nil` comme aujourd’hui ;
- le message de confirmation explique l’effet sur la paroisse et le classement.

### 8.5 Vue et composants

Réorganiser `app/views/street_profiles/show.html.erb` autour de l’état en lecture.

Partiels recommandés :

- `_profile.html.erb` : composition complète de la fiche ;
- `_profile_hero.html.erb` : identité et progression principale ;
- `_profile_identity.html.erb` : lignes canoniques ;
- `_profile_ward.html.erb` : paroisse ;
- `_profile_history.html.erb` : destinations Aventure, Parole et Défis ;
- `_profile_data.html.erb` : notifications, confidentialité et appareils ;
- `_profile_editor.html.erb` : panneau contextuel générique ;
- `_avatar_editor.html.erb` : sélection d’avatar.

Ne pas dupliquer les composants existants de dock, pictogrammes, avatar et boutons.

### 8.6 Interaction côté navigateur

Privilégier le HTML serveur. Ajouter un contrôleur Stimulus léger seulement pour :

- ouvrir et fermer le panneau ;
- gérer le focus initial et son retour ;
- empêcher la page derrière de défiler pendant l’édition ;
- synchroniser le compteur de caractères ;
- refléter les états `loading`, `success` et `failure` ;
- respecter `prefers-reduced-motion`.

Le panneau ne doit pas afficher de poignée s’il n’est pas réellement déplaçable.

#### 8.6.1 Plan d’animation et de transition livré

Émotion recherchée : fierté calme, reconnaissance immédiate et contrôle. La fiche n’ajoute ni tension artificielle, ni boucle ambiante infinie, ni son ou vibration pour des actions administratives.

| Moment | Mouvement | Durée cible | Règle |
|---|---|---:|---|
| Entrée de la fiche | titre, héros puis quatre groupes montent légèrement et se révèlent | 420 à 650 ms | le héros reste prioritaire ; le décalage des groupes est borné à 55 ms |
| Signature du héros | orbite, étoile et un reflet traversent le verre une seule fois | 320 à 630 ms | aucun scintillement infini et aucun `backdrop-filter` animé |
| Ligne ou destination | plaque qui se soulève de 1 px, médaillon et chevron qui avancent, pression à `scale(.985)` | 160 ms | le mouvement confirme l’action sans déplacer la mise en page |
| Ouverture d’un éditeur | voile qui se teinte puis panneau depuis le bas sur téléphone, légère montée/échelle au centre dès 720 px | 180 / 320 ms | la fiche derrière ne rejoue pas son entrée ; la feuille est lisible dès sa première frame |
| Annulation ou `Escape` | panneau descend et voile disparaît avant la navigation Turbo | 200 ms | le focus revient sur la ligne d’origine |
| Enregistrement | bouton verrouillé avec indicateur ; après succès la ligne concernée reçoit une lueur locale unique | 700 ms maximum | aucune lueur de succès après une annulation ou une erreur `422` |
| Erreur | message local révélé par une courte montée et un renforcement de bordure | 280 ms | pas de secousse agressive ; la saisie est conservée |
| Historique des réponses | en-tête, résumé puis sessions apparaissent par groupes | 280 à 560 ms | aucune animation question par question sur les longues listes |
| Changement de page | transition de document existante : sortie 180 ms, entrée 280 ms | 280 ms | la destination reste l’unique source de vérité ; pas de faux écran intermédiaire |

Les déplacements utilisent `transform` et, lorsque cela ne crée pas de superposition de texte, `opacity`. Les ombres, teintes de fond et bordures peuvent répondre à la pression, mais le flou du verre n’est jamais animé. En `prefers-reduced-motion: reduce`, les entrées, sorties, reflets, déplacements, rotations et transitions de document propres à la fiche sont supprimés ; l’état final apparaît immédiatement. Le spinner de chargement devient un anneau statique lisible.

### 8.7 Styles

Étendre `app/assets/stylesheets/surfaces/profile.css` avec les tokens existants.

Règles :

- Celestial Light pour cette surface tant qu’aucun artwork dynamique n’est défini ;
- texte principal en `--ink` sur papier clair ;
- or réservé au métal, aux hairlines, à l’état actif et à l’unique CTA principal ;
- cibles tactiles d’au moins `44 × 44 px` ;
- taille de texte minimale conforme à `--type-min` ;
- aucun story tick, badge Live, croix décorative ou poignée factice ;
- aucun débordement à `390`, `768` et `1440` pixels de largeur ;
- clavier mobile pris en compte avec `interactive-widget=resizes-visual` et `visualViewport` seulement si nécessaire.

### 8.8 Routes

Le sas et les ressources privées ont des responsabilités distinctes :

- `GET /ficha` pour sélectionner, réclamer ou créer une fiche ; une personne déjà reconnue est redirigée vers son URL explicite ;
- `POST /ficha` pour sélectionner, réclamer ou créer une fiche ;
- `GET /jugadores/:player_id/perfil` pour consulter la fiche et ouvrir un éditeur via un paramètre autorisé ;
- `GET /jugadores/:player_id/perfil/respuestas` pour consulter uniquement les réponses du joueur demandé et reconnu ;
- `PATCH /jugadores/:player_id/perfil` pour les données canoniques ;
- `POST /jugadores/:player_id/perfil/fusion` pour une fusion initiée depuis cette fiche ;
- `PATCH /locale` pour la langue, ou appel serveur équivalent depuis la fiche ;
- `POST /rama` pour finaliser le changement de paroisse ;
- destinations existantes pour les historiques.

`player_id` rend la cible explicite, mais ne constitue jamais une preuve d’accès. Le serveur exige toujours la reconnaissance de l’appareil et vérifie que l’ID demandé correspond exactement à `current_street_person`.

### 8.9 Base de données

Aucune migration n’a été nécessaire pour les données canoniques du profil. L’extension d’historique ajoute toutefois `StudyRun#asked_at` afin de mesurer honnêtement le temps passé sur chaque question Parole. `StudyAnswer#duration_ms` existait déjà mais n’était pas alimenté.

Les réponses Aventure utilisent le chronométrage existant de `Quizzes::AskClock`. Les réponses Parole utilisent `Studies::AnswerClock`, avec une borne de 30 minutes afin qu’un onglet laissé ouvert ne déforme pas les statistiques.

Les anciennes réponses Parole ne sont pas rétro-remplies : leur durée reste `nil`, est affichée comme « non disponible » et est exclue du calcul du temps moyen. Aucune durée historique n’est inventée.

Une autre migration ne sera nécessaire que si l’équipe décide d’ajouter :

- une preuve de récupération distincte de `favorite_year` ;
- un journal minimal des changements sensibles ;
- un nom d’appareil choisi par le joueur ;
- une demande d’export ou d’effacement suivie dans le produit.

## 9. Sécurité et confidentialité

### 9.1 Niveau d’autorité actuel

Le couple cookie signé + `PersonDevice` peut autoriser les modifications réversibles et de faible risque sur l’appareil reconnu : prénom, nom, avatar, langue et préférences.

Le changement de paroisse exige une confirmation explicite, mais peut conserver cette même autorité dans le MVP puisque `People::Transfer` préserve les données et que le choix est réversible.

Les actions sensibles suivantes exigent une preuve renforcée avant automatisation :

- consulter et révoquer d’autres appareils ;
- générer un export complet ;
- effacer ou anonymiser la fiche ;
- transférer une fiche vers une identité non reconnue ;
- fusionner sans assistance lorsque le risque d’homonymie existe.

### 9.2 Année favorite

`favorite_year` est actuellement une donnée canonique visible par les présentateurs et utilisée comme facteur de réclamation dans `People::Claim`.

Elle ne doit pas être considérée comme un secret robuste si elle devient une donnée de profil consultable et modifiable. Avant de livrer les actions sensibles, choisir une autre preuve :

- PIN de récupération propre à la fiche ;
- code ponctuel présenté sur un appareil déjà reconnu ;
- récupération assistée par un présentateur autorisé ;
- compte durable, si le produit évolue plus tard vers cette direction.

La limitation actuelle de `People::Claim` utilise un `MemoryStore` local au processus. Une protection durable contre les essais répétés devra utiliser un stockage partagé ou une stratégie de limitation au niveau de l’infrastructure.

### 9.3 Règles d’autorisation

- La personne modifiée est toujours `current_street_person`.
- Le `player_id` de l’URL doit correspondre exactement à `current_street_person.id` ; il déclare la ressource attendue mais ne l’autorise pas.
- Une absence de reconnaissance redirige vers `/ficha`; un ID différent renvoie `404` sans charger ni nommer l’autre fiche.
- Toute mise à jour conserve la protection CSRF Rails.
- Les erreurs ne doivent pas confirmer l’existence d’une fiche inaccessible.
- Les valeurs de nom sont échappées dans les vues et ne sont jamais injectées comme HTML.
- Les événements de mesure ne contiennent ni nom, ni année favorite, ni texte de lecture, ni jeton.

### 9.4 Indexation

- `/ficha` et `/jugadores/` reçoivent `noindex, nofollow` dans la balise `robots` et l’en-tête `X-Robots-Tag`.
- Ces préfixes sont refusés dans `public/robots.txt`, y compris pour `OAI-SearchBot` et `ChatGPT-User`.
- Aucune fiche ni aucun historique privé n’est produit par `SeoController#sitemap`.
- Aucune URL canonique, donnée structurée ou alternate SEO n’est émise pour ces pages privées.

### 9.5 Enfants et famille

Une fiche peut appartenir à un enfant. Les textes doivent rester compréhensibles pour une famille et rappeler, quand nécessaire, qu’en Espagne la famille crée la fiche d’un joueur de moins de 14 ans sur cet appareil.

## 10. Internationalisation et rédaction

Toute nouvelle copie utilise `t()` et doit exister dans :

- `config/locales/es.yml` ;
- `config/locales/fr.yml` ;
- `config/locales/en.yml` ;
- `config/locales/pt-BR.yml`.

Les libellés de mockup sont des propositions. Avant livraison, faire valider au minimum :

- le nom des sections ;
- l’explication du changement de paroisse ;
- l’explication de l’année favorite ;
- les messages de succès et d’erreur ;
- les libellés de copie et d’effacement ;
- la terminologie branche, paroisse, pieu et chapelle dans les quatre langues.

## 11. Accessibilité

### Exigences clavier et lecteur d’écran

- Chaque ligne interactive est un vrai lien ou bouton.
- Le nom du champ et sa valeur sont annoncés ensemble.
- Le panneau d’édition possède un titre accessible.
- Le focus entre dans le champ à l’ouverture et revient sur la ligne à la fermeture.
- `Escape` ferme le panneau sans enregistrer.
- Une erreur est reliée au champ avec `aria-describedby` et annoncée avec un statut adapté.
- Le chargement ne supprime pas silencieusement le contrôle actif.

### Exigences visuelles et motrices

- Cibles tactiles d’au moins 44 pixels.
- Contraste vérifié sur papier et artwork.
- Valeur et chevron ne sont pas les seuls indices de modification.
- Les informations ne reposent pas uniquement sur la couleur.
- Les animations sont désactivables.
- Aucun contenu important n’est masqué par le clavier ou le dock.

## 12. Performance

- Conserver la page dans le budget CSS `profile` vérifié par `test/performance/architecture_contract_test.rb`.
- Éviter une requête par bloc ou par ligne.
- Charger uniquement les agrégats visibles dans le premier rendu.
- Ne pas charger le détail des réponses, passages ou événements sur `/ficha`.
- Réutiliser les images d’avatar et pictogrammes déjà mis en cache.
- Vérifier les temps de requête avec un profil riche en parties, études, surlignages et défis.

## 13. Mesure produit

La mesure est facultative pour le MVP et doit respecter la minimisation des données.

Événements autorisés si l’équipe confirme leur utilité :

- `profile_viewed` ;
- `profile_field_edit_opened`, avec seulement le nom technique du champ ;
- `profile_field_updated`, avec seulement le nom technique du champ et le résultat ;
- `profile_ward_change_started` ;
- `profile_ward_change_completed` ;
- `profile_history_opened`, avec la section Aventure, Parole ou Défis.

Ne jamais enregistrer les anciennes ou nouvelles valeurs dans ces événements.

Indicateurs utiles :

- taux d’ouverture d’un éditeur ;
- taux de succès de mise à jour ;
- erreurs par type de champ ;
- abandons du changement de paroisse ;
- ouvertures des historiques depuis la fiche ;
- évolution du nombre de doublons nécessitant une fusion.

## 14. Découpage de livraison

### Phase 0 — Contrat et sécurité

Objectif : éliminer les ambiguïtés avant le code.

- Valider la liste des données visibles et modifiables.
- Valider la visibilité publique, paroisse, privée et présentateur.
- Décider du statut de `favorite_year` : simple donnée de profil ou facteur de récupération temporaire.
- Valider les données de rang, niveau, série et place affichées dans le hero.
- Valider la copie dans les quatre langues.
- Confirmer que l’export et l’effacement restent manuels dans le MVP.

Sortie : contrat produit approuvé et aucune donnée de mockup interprétée comme règle métier par défaut.

### Phase 1 — Profil en lecture

Objectif : remplacer l’état d’édition par défaut par une fiche utile.

- Créer `StreetProfiles::Snapshot`.
- Ajouter l’état `:profile` à `StreetProfilesController`.
- Construire le hero et les sections Identité, Paroisse, Histoire et Mes données.
- Relier Aventure, Parole, Défis, Notifications et Confidentialité.
- Conserver les flux de création, choix, réclamation et fusion.
- Ajouter les états vides honnêtes.
- Ajouter les traductions et tests de rendu.

Sortie : toutes les données utiles sont consultables, mais les nouvelles micro-éditions peuvent encore être désactivées.

### Phase 2 — Édition canonique et paroisse

Objectif : permettre les corrections prévues dans le MVP.

- Refactorer la mise à jour joueur vers `People::Update` avec sémantique partielle explicite.
- Implémenter les éditeurs Prénom, Nom, Année favorite et Langue.
- Réutiliser la sélection d’avatar existante dans un éditeur dédié.
- Ajouter focus, validation, chargement, succès, erreur et annulation.
- Ajouter le retour `profile` après changement de paroisse.
- Vérifier la propagation vers les participations Live.
- Ajouter les tests d’autorisation et de non-régression.

Sortie : le MVP fonctionnel est complet.

### Phase 3 — Contrôle avancé des données

Objectif : offrir des droits en self-service après décision d’identité.

- Mettre en place une preuve renforcée.
- Afficher les appareils reconnus de façon humaine.
- Permettre la révocation distante.
- Générer une copie compréhensible des données.
- Définir et implémenter l’effacement ou l’anonymisation par famille de données.
- Documenter les contraintes de conservation et les dépendances `restrict_with_exception`.
- Tester les suppressions sur une fiche complète.

Sortie : droits d’accès, copie et effacement disponibles sans demande manuelle, si le cadre légal et l’identité sont validés.

## 15. Tickets d’implémentation recommandés

### PROF-01 — Contrat des données

Livrable : liste approuvée des champs, agrégats, visibilités et sources métier.
Dépendance : aucune.
Bloque : tous les autres tickets.

### PROF-02 — Snapshot de profil

Livrable : `StreetProfiles::Snapshot` et tests unitaires.
Dépendance : PROF-01.
Critère : aucune N+1 et aucun détail sensible chargé inutilement.

### PROF-03 — Vue en lecture

Livrable : hero et sections conformes au mockup principal.
Dépendance : PROF-02.
Critère : `/ficha` ouvre cette vue pour une personne reconnue.

### PROF-04 — Navigation des historiques

Livrable : liens Aventure, Parole, Défis, Notifications et Confidentialité.
Dépendance : PROF-03.
Critère : chaque ligne ouvre la destination exacte et le bon onglet du dock.

### PROF-05 — Service de mise à jour partielle

Livrable : source unique de validation et propagation des champs canoniques.
Dépendance : PROF-01.
Critère : aucun champ absent n’est effacé ; les usages présentateur restent compatibles.

### PROF-06 — Éditeurs de texte

Livrable : Prénom, Nom et Année favorite avec panneau contextuel accessible.
Dépendance : PROF-03 et PROF-05.
Critère : clavier, focus, succès, erreur et annulation sont couverts.

### PROF-07 — Avatar et langue

Livrable : sélection d’avatar et changement de langue propagé avec `Locales::Set`.
Dépendance : PROF-03 et PROF-05.
Critère : l’interface et les participations Live reflètent la nouvelle valeur.

### PROF-08 — Changement de paroisse

Livrable : flux de recherche, confirmation et retour à la fiche.
Dépendance : PROF-03.
Critère : progression préservée, `last_ward_team` remis à zéro et classement actualisé.

### PROF-09 — I18n, accessibilité et QA visuelle

Livrable : quatre langues, audit clavier/lecteur d’écran, captures aux trois largeurs.
Dépendance : PROF-03 à PROF-08.
Critère : aucun défaut bloquant connu.

### PROF-10 — Mes données avancées

Livrable : preuve renforcée, appareils, copie et effacement.
Dépendance : décision d’identité distincte.
Hors MVP.

## 16. Stratégie de tests

### Tests unitaires et services

- `StreetProfiles::Snapshot` avec fiche vide, partielle et riche.
- `StreetProfiles::AnswerHistory` avec réponses Aventure et Parole, localisation, pagination, données anciennes partielles et exclusion d’un autre profil.
- `Studies::AnswerClock` avec durée normale, durée négative ramenée à zéro et durée maximale de 30 minutes.
- `People::Update` pour chaque champ, mises à jour combinées et champs absents.
- `People::Transfer` avec paroisse identique, nouvelle paroisse et conflit.
- `Locales::Set` avec personne seule et participations Live.
- agrégats Aventure, Parole et Défis avec données anciennes et incomplètes.

### Tests contrôleur

- personne reconnue : vue en lecture.
- appareil non reconnu : aucun accès à une fiche arbitraire.
- mise à jour de chaque champ autorisé.
- rejet des attributs non autorisés.
- rejet d’une mise à jour sans personne courante.
- impossibilité de modifier une autre personne avec un `person_id` injecté.
- réponse `422` et conservation des valeurs en cas d’erreur.
- retour à la fiche après changement de paroisse.
- compatibilité des flux création, claim, choix d’appareil et fusion.
- historique inaccessible sans fiche reconnue, limité à `current_street_person`, complet et vide.

### Tests système

- clic sur Prénom, focus automatique, saisie, annulation et enregistrement.
- clavier mobile ne masquant pas le champ ou le bouton.
- clic sur Parole menant à `/parole/historique` avec dock actif.
- clic sur Paroisse menant à la recherche puis retour à `/ficha`.
- navigation complète au clavier.
- annonces d’erreur accessibles.
- `prefers-reduced-motion`.
- ouverture de « Mes réponses » depuis la fiche, verdicts correct/incorrect, temps connu/inconnu, état vide et géométrie aux trois viewports.

### Vérification visuelle obligatoire

Inspecter personnellement :

- `390 × 844` ;
- `768 × 1024` ;
- `1440 × 900`.

Pour chaque largeur :

- profil vide ou minimal ;
- profil réaliste ;
- nom de 24 caractères ;
- paroisse au nom long ;
- éditeur Prénom avec clavier ;
- erreur de validation ;
- langue produisant les libellés les plus longs ;
- aucun débordement horizontal ;
- console sans erreur ni avertissement causé par la feature.

Celestial Dark n’est pas exigé pour ce profil tant que la surface est explicitement Celestial Light. Si le décor devient dynamique, les deux familles deviennent obligatoires.

### Commandes de vérification prévues

- tests contrôleur profil ;
- tests services `People`, `Locales` et `StreetProfiles` ;
- test système `StreetProfileVisualTest` étendu ;
- test système du parcours Parole concerné ;
- test de budget `test/performance/architecture_contract_test.rb` ;
- suite Rails pertinente avant fusion.

## 17. Déploiement et retour arrière

### Livraison progressive

1. Livrer le snapshot et la vue en lecture derrière un flag serveur si nécessaire.
2. Observer les erreurs et la performance sans activer les nouveaux éditeurs.
3. Activer les éditeurs canoniques.
4. Activer le retour de changement de paroisse.
5. Retirer l’ancien grand formulaire uniquement après validation des nouveaux flux.

### Retour arrière

- Les micro-éditeurs étant stabilisés et couverts, l’ancien partiel a été supprimé. Un retour arrière de code reste possible sans migration de données.
- Le rollback de l’historique peut d’abord retirer la route et l’écriture du chronomètre sans perdre de réponse. La colonne nullable `study_runs.asked_at` peut rester en place sans effet ; sa suppression éventuelle se fait dans une migration séparée après vérification qu’aucun autre usage ne l’a adoptée.
- Les services existants restent la source métier pendant la transition.

## 18. Critères d’acceptation du MVP

Le MVP est terminé seulement si :

- `/ficha` présente une fiche en lecture pour la personne reconnue ;
- prénom, nom, avatar, année favorite, langue et paroisse sont visibles ;
- les cinq premières données et l’association de paroisse sont modifiables par les flux prévus ;
- la date de création est consultable ;
- Aventure, Parole, Défis, Notifications et Confidentialité ouvrent la bonne destination ;
- le clic sur Prénom correspond au comportement du mockup validé ;
- le clic sur Parole ouvre l’historique personnel validé ;
- « Mes réponses » ouvre un historique privé Aventure/Parole avec question, réponse donnée, bonne réponse, verdict et durée lorsqu’elle est connue ;
- aucune réponse d’un autre profil reconnu sur le même appareil n’est exposée ;
- aucune donnée technique sensible n’est affichée ou journalisée ;
- une autre personne ne peut pas être modifiée en injectant un identifiant ;
- les quatre langues sont présentes et relues ;
- les états focus, loading, success, failure, empty et reduced-motion sont vérifiés ;
- les trois largeurs cibles sont inspectées visuellement ;
- les tests pertinents et le budget CSS passent ;
- la console est propre ;
- le statut de l’année favorite comme facteur de récupération est documenté ;
- l’export et l’effacement sont soit disponibles avec preuve renforcée, soit clairement proposés comme procédure manuelle.

## 19. Décisions encore requises

### Bloquantes avant le MVP

- Quelle source produit définit exactement rang, niveau et série dans le hero ?
- L’année favorite reste-t-elle modifiable tant qu’elle sert à réclamer une fiche ?
- Quel texte explique le changement de paroisse dans les quatre langues ?
- Les résumés de progression montrent-ils des totaux historiques ou seulement la saison courante ?
- Le nombre de victoires de défis possède-t-il une définition métier stable et testée ?

### Bloquantes avant la phase 3

- Quelle preuve renforcée remplace l’année favorite ?
- Quelles données doivent être supprimées, anonymisées ou conservées lors d’un effacement ?
- Comment traiter les invitations et duels protégés par `restrict_with_exception` ?
- L’export est-il généré dans le produit ou remis manuellement après vérification ?
- Comment nommer et reconnaître un appareil sans conserver davantage de données que nécessaire ?

## 20. Définition de prêt à développer

Un ticket de cette documentation peut passer en développement lorsque :

- sa source de données est identifiée ;
- sa visibilité est approuvée ;
- son comportement et ses états sont décrits ;
- sa copie française et les intentions des trois autres langues sont validées ;
- ses critères d’acceptation et tests sont listés ;
- aucune décision de sécurité ou de conservation ne lui manque ;
- les données illustratives des mockups ont été remplacées par des règles métier explicites.

## 21. État de livraison — 30 août 2026

Le MVP décrit dans ce document est implémenté. `/ficha` ouvre désormais la vue de lecture pour une personne reconnue, et conserve les flux historiques de création, réclamation, choix d’appareil et fusion.

### Données effectivement exposées

- identité canonique : prénom, nom, avatar, année favorite et langue ;
- repères de fiche : identifiant numérique du joueur et date de création, visibles uniquement depuis sa fiche reconnue ;
- appartenance : paroisse, ville et pays lorsqu’ils existent ;
- repères de jeu réels : couronnes, rang paroissial et série ;
- Aventure : packs terminés et couronnes ;
- Parole : parcours terminés et passages surlignés ;
- Défis : victoires résolues et défis actifs ;
- données de confiance : date de création, nombre d’appareils liés, notifications, confidentialité et récupération d’une ancienne fiche.

Aucun niveau n’est affiché : il n’existe pas de source métier canonique suffisamment stable pour cette surface. Les victoires de défis correspondent uniquement aux duels résolus dont le score de la personne est strictement supérieur à celui de l’adversaire.

### Décisions auparavant bloquantes

- Rang : `Quizzes::Standings` / `Quizzes::Leaderboard`; série : `Quizzes::Streak`; couronnes : score total de leaderboard.
- Année favorite : reste modifiable dans le MVP, avec une copie qui explicite son rôle possible de récupération. Elle ne constitue pas une preuve renforcée.
- Changement de paroisse : le parcours existant `/buscar?cambiar=1` est réutilisé et revient à `/ficha` via `session[:street_return] = "profile"`.
- Progression : totaux historiques, plus utiles dans une fiche personnelle qu’un instantané de saison.
- Parole : redirection vers `/parole/historique`; aucun second historique n’est créé.
- Export, effacement self-service et révocation distante : toujours hors MVP, conformément à la section 15.

### Architecture livrée

- `StreetProfiles::Snapshot` centralise les agrégats en lecture.
- `People::Update` utilise une sentinelle `UNSET` et préserve les attributs absents.
- Le contrôleur accepte uniquement les champs canoniques autorisés et agit toujours sur `current_street_person`.
- Les erreurs métier rendent `422`, conservent la saisie et rouvrent l’éditeur concerné.
- `Locales::Set` reste la source d’écriture de langue ; le contrôleur mémorise aussi la préférence locale dans le cookie.
- Les six éditeurs autorisés sont `given_name`, `family_name`, `avatar_key`, `favorite_year`, `locale` et `merge`. Toute autre valeur de `edit` est ignorée.

### Expérience et accessibilité livrées

- vue en lecture par défaut ;
- panneau contextuel nommé par `role="dialog"` et `aria-modal="true"` ;
- autofocus, compteur de caractères, état loading, erreur locale reliée par `aria-describedby`, annulation et restauration du focus ;
- cibles tactiles mesurées à 44 × 44 px minimum ;
- verre ivoire/doré, fallback opaque sans blur, reduced motion et reduced transparency ;
- entrée bornée à 630 ms, reflet unique du héros, micro-réactions à 160 ms et aucun mouvement ambiant infini ;
- fermeture animée par Annuler, croix, clic hors panneau ou `Escape`, puis restauration du focus ;
- feedback d’enregistrement localisé sur la seule ligne modifiée et erreur `422` révélée sans secousse ;
- historique des réponses animé par grands groupes, jamais réponse par réponse ;
- quatre langues : es, pt-BR, en et fr.

### Preuves de validation

- 40 tests fonctionnels, 329 assertions, 0 échec ;
- historique et régressions ciblées avec architecture : 55 tests, 25 752 assertions, 0 échec ;
- 35 tests Hub, 701 assertions, 0 échec ;
- revalidation fonctionnelle profil/historique : 33 tests, 297 assertions, 0 échec ;
- contrat d’architecture : 18 tests, 25 194 assertions, 0 échec ;
- 5 tests système visuels, 294 assertions, 0 échec ;
- scénarios notifications concernés : 53 puis 43 assertions, 0 échec ;
- viewports inspectés : 390 × 844, 768 × 1024 et 1440 × 900 ;
- états supplémentaires inspectés à 390 × 844 : profil minimal, noms maximaux, paroisse longue et partielle, ouverture, loading, succès local, erreur de validation et historique vide ;
- captures : `tmp/street-shots/profile-dashboard/` ;
- verdict Noche : `docs/AGENT_REVIEWS/148-ficha-profile-celestial-glass.md` — PASS.
- verdict de l’historique : `docs/AGENT_REVIEWS/149-historique-reponses-joueur.md` — PASS.

## 22. Assets générés pour la feature

Les fichiers livrés sont des WebP 256 × 256 avec canal alpha réel. Les PNG de génération ont été convertis avant livraison afin de réduire d’environ 80 % le poids public sans changer les dimensions :

- `public/media/profile/icons/profile-identity-medallion-v1.webp` ;
- `public/media/profile/icons/profile-ward-medallion-v1.webp` ;
- `public/media/profile/icons/profile-adventure-medallion-v1.webp` ;
- `public/media/profile/icons/profile-answers-medallion-v1.webp` ;
- `public/media/profile/icons/profile-word-medallion-v1.webp` ;
- `public/media/profile/icons/profile-challenges-medallion-v1.webp` ;
- `public/media/profile/icons/profile-data-medallion-v1.webp`.

Le décor existant `public/media/profile/profile-gathering-celestial-light-v1.webp` a été réutilisé parce qu’il appartient déjà à la surface et correspond au mockup approuvé.

### Prompts exacts de génération

Référence visuelle commune : `tmp/street-shots/temple-mockups/mockup-street-profile-celestial-light.png`.

#### Historique des réponses

```text
Use case: stylized-concept
Asset type: standalone 1:1 UI medallion for the Noche Live Celestial Light player profile, displayed at 58 px
Primary request: Create the dedicated “answer history” medallion. Inside a refined circular sacred-medallion frame, show a small elegant quiz parchment with three abstract horizontal answer marks; add one clear navy check seal and one restrained coral-red incorrect seal as simple symbols, communicating review, learning, and progress rather than judgment.
Style/medium: premium AAA family mobile-game HUD icon, softly dimensional painted 3D illustration, simplified and crisp at small size
Composition/framing: perfectly centered circular object, generous transparent padding, strong readable silhouette, no square tile or button backing
Lighting/mood: warm celestial light, gentle hopeful confidence
Color palette: pearl ivory translucent glass, restrained champagne-gold rim and metal hairlines, deep navy details, one small coral-red accent, tiny celestial star glint
Materials/textures: polished pearl glass, subtle gold metal, lightly textured parchment
Constraints: genuinely transparent alpha background; one isolated medallion only; no external drop shadow; no religious cross; no photorealism; no watermark
Avoid: all text, letters, words, numbers, UI labels, square backgrounds, flat web icon style, excessive ornament, stacked gold, trophy or competitive ranking imagery
```

Le fichier livré est le rendu qui possède un véritable canal alpha. Deux essais de simplification ont été refusés parce que le damier de transparence avait été rasterisé dans l’image au lieu de produire de l’alpha.

#### Identité

```text
Create one standalone UI icon asset for Noche Live's approved Celestial Light profile screen: the Identity medallion. A warm, friendly human bust silhouette centered inside a refined circular sacred-medallion frame, pearl ivory translucent glass, subtle champagne-gold rim, tiny celestial star glint, soft navy detail, premium AAA mobile-game HUD finish, graceful and family-friendly, readable at 44 px, no text, no letters, no numbers, no button background, no square tile, no drop shadow outside the object. Perfectly centered with generous transparent padding. Output a single 1:1 PNG with a truly transparent alpha background. Match the visual language, gold warmth, ivory glass material, and restrained dimensionality of the supplied approved profile mockup.
```

#### Paroisse — version finale régénérée

```text
Regenerate one standalone UI icon asset for Noche Live's approved Celestial Light profile screen: the Parish medallion for an LDS ward. Show a welcoming modern meetinghouse facade with a modest slender steeple and glowing open doorway, centered inside a refined circular medallion. IMPORTANT: absolutely no cross, crucifix, denomination symbol, lettering, plaque, text, letters, or numbers anywhere. Pearl ivory translucent glass, restrained champagne-gold rim, small soft navy roof detail, one tiny celestial star glint, premium but gentle family mobile-game HUD craftsmanship. Simplified and readable at 44 px. No button tile, no square backing, no outside shadow. Generous transparent padding. Single centered 1:1 PNG with truly transparent alpha. Match the warm ivory and gold material of the supplied approved profile mockup.
```

La première génération de ce médaillon a été refusée pendant la revue Art parce qu’elle comportait une croix ; elle n’est pas livrée. Son prompt était :

```text
Create one standalone UI icon asset for Noche Live's approved Celestial Light profile screen: the Parish medallion. A welcoming small chapel facade with a simple steeple and open doorway, centered inside a refined circular medallion, pearl ivory translucent glass, restrained champagne-gold hairline rim, a little soft navy detail, one tiny celestial glint, premium but gentle mobile-game HUD craftsmanship. Readable at 44 px, simplified silhouette, not photorealistic, no text, no letters, no numbers, no button tile, no square backing, no shadow outside the object. Generous transparent padding. Single centered 1:1 PNG with truly transparent alpha. Match the supplied approved profile mockup; elegant, warm, less ornate than a collectible coin.
```

#### Aventure

```text
Create one standalone UI icon asset for Noche Live's approved Celestial Light profile screen: the Adventure medallion. A clean compass rose with a subtle winding path motif, centered inside a refined circular medallion, pearl ivory translucent glass, restrained champagne-gold hairline rim, soft navy accents and one tiny celestial glint, premium mobile-game HUD finish yet light and serene. Readable at 44 px, simplified shape, no text, no letters, no numbers, no button tile, no square backing, no shadow outside the object. Generous transparent padding. Single centered 1:1 PNG with truly transparent alpha. Match the visual material and warmth of the supplied approved profile mockup.
```

#### Parole

```text
Create one standalone UI icon asset for Noche Live's approved Celestial Light profile screen: the Word / Scripture medallion. A graceful open scripture book with two clean pages and one small rising star of light, centered inside a refined circular medallion, pearl ivory translucent glass, restrained champagne-gold hairline rim, soft navy page detail, premium warm family-friendly mobile-game HUD finish. Readable at 44 px, simplified silhouette, no cross, no text, no letters, no numbers, no button tile, no square backing, no shadow outside the object. Generous transparent padding. Single centered 1:1 PNG with truly transparent alpha. Match the supplied approved profile mockup.
```

#### Défis

```text
Create one standalone UI icon asset for Noche Live's approved Celestial Light profile screen: the Challenges medallion. A noble small shield with two subtle crossed ceremonial staffs behind it and one star, centered inside a refined circular medallion, pearl ivory translucent glass, restrained champagne-gold hairline rim, soft navy accents, premium family-friendly mobile-game HUD finish. Competitive but kind, readable at 44 px, simplified silhouette, no weapons or aggression, no text, no letters, no numbers, no button tile, no square backing, no shadow outside the object. Generous transparent padding. Single centered 1:1 PNG with truly transparent alpha. Match the supplied approved profile mockup.
```

#### Données et confidentialité

```text
Create one standalone UI icon asset for Noche Live's approved Celestial Light profile screen: the Data and privacy medallion. A refined protective seal combining a small keyhole and a gentle four-point celestial star, centered inside a pearl ivory translucent-glass circular medallion with restrained champagne-gold hairline rim and soft navy accents. Trustworthy, calm, premium mobile-game HUD finish, readable at 44 px, simplified silhouette, no text, no letters, no numbers, no button tile, no square backing, no shadow outside the object. Generous transparent padding. Single centered 1:1 PNG with truly transparent alpha. Match the supplied approved profile mockup.
```

## 23. Contrat livré — historique privé des réponses

### Données conservées

| Source | Lien au joueur | Question | Réponse | Verdict | Durée |
|---|---|---|---|---|---|
| Aventure | `QuizAnswer → QuizRun#person_id` | `question_id` | `choice_key` | `correct` | `duration_ms` existant |
| Parole | `StudyAnswer → StudyRun#person_id` | `question_key` | `choice_key` | `correct` | `duration_ms`, alimenté depuis `StudyRun#asked_at` |

Les textes de question et de choix ne sont pas dupliqués dans les réponses : ils sont reconstruits dans la langue courante depuis le catalogue Aventure ou la version Parole immuable. Si une ancienne définition Aventure n’est plus disponible, l’écran affiche un libellé honnête d’ancien quiz ou d’ancienne question au lieu de lever une erreur.

### Sémantique du chronomètre Parole

1. `asked_at` est initialisé à la création d’un `StudyRun`.
2. Pour un ancien parcours ouvert sans valeur, la première consultation initialise le départ.
3. La soumission calcule `duration_ms` entre `asked_at` et la réponse.
4. Le passage à la question suivante réinitialise `asked_at`.
5. La valeur est bornée entre zéro et 1 800 000 ms.
6. Une réponse historique sans durée reste inconnue et n’entre pas dans la moyenne.

### Lecture et agrégats

`StreetProfiles::AnswerHistory` retourne :

- nombre total de réponses ;
- nombre de bonnes réponses ;
- taux de réussite calculé dans la vue ;
- temps moyen calculé seulement sur les réponses chronométrées ;
- sessions Aventure et Parole triées de la plus récente à la plus ancienne ;
- huit sessions par page ;
- chaque entrée localisée avec réponse donnée, bonne réponse, verdict, durée et référence scripturaire éventuelle.

La fiche `/jugadores/:player_id/perfil` ne charge que deux compteurs via `StreetProfiles::Snapshot`. Le détail n’est chargé qu’après ouverture de `/jugadores/:player_id/perfil/respuestas`.

### Autorisation et minimisation

- Le contrôleur exige `current_street_person`, lui-même validé par le couple cookie signé et `PersonDevice`, puis compare son ID au `player_id` du chemin.
- Le service filtre les deux familles par l’ID autorisé côté serveur ; l’ID du chemin ne peut jamais sélectionner seul une autre personne.
- Les réponses rattachées uniquement à un appareil, sans personne canonique, ne sont pas attribuées rétroactivement.
- Les identifiants de base, digests d’appareil, points techniques et clés de catalogue ne sont pas rendus.
- L’état correct/incorrect est toujours écrit en texte et symbole ; il ne repose pas seulement sur la couleur.

### État vide et données partielles

- Zéro réponse : résumé à zéro, explication et bouton verre doré vers Aventure.
- Durée inconnue : « Non disponible » dans la langue active.
- Réponse absente : « Aucune réponse ».
- Définition historique manquante : fallback localisé, sans masquer le reste de la session.

### Limites assumées

- Les réponses Live sont exclues tant qu’elles ne partagent pas un contrat objectif `correct + duration_ms`.
- Aucun backfill probabiliste des durées Parole n’est effectué.
- Aucun partage public, paroissial ou présentateur de l’historique détaillé n’est ajouté.
