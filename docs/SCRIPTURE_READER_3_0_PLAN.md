# Plan produit et technique — Liseuse 3.0

- Statut : proposition consolidée à partir des mockups, prête à être découpée en tickets
- Dernière mise à jour : 30 août 2026
- Surface principale : liseuse authentifiée ouverte depuis La Parole
- Périmètre : lecture longue, accueil éditorial bref, préférences, sélection et annotations enrichies, historique, cercle de la paroisse, publications depuis le profil et vidéos officielles liées au chapitre

## 1. Décision

La Liseuse 3.0 doit devenir une chambre de lecture calme, personnelle et habitée.

Son premier verbe reste **lire**. L'accueil bref, les repères, l'historique, les vidéos et le cercle social doivent aider la lecture sans entrer en concurrence avec le texte sacré.

La proposition initiale a correctement identifié plusieurs besoins : donner une vraie place au chapitre, retrouver ses notes, percevoir une communauté de lecteurs et prolonger la lecture. La contre-proposition fixe cependant une hiérarchie plus stricte :

1. le texte biblique occupe toujours la surface dominante ;
2. la taille, l'interligne, la largeur et le fond de lecture sont réglables et mémorisés ;
3. un court accueil éditorial prépare la lecture sans la remplacer ;
4. toute sélection peut devenir une annotation personnelle enrichie : surlignage ou soulignement, couleur, note, tags, carnet, signet ou lien vers un autre passage ;
5. le lecteur voit son histoire avec ce chapitre et peut reprendre où il s'est arrêté ;
6. la présence d'autres lecteurs est exprimée avec sobriété ;
7. le cercle de conversation est séparé du texte et strictement limité à la `Ward` associée au joueur ;
8. tout membre éligible de cette ward peut proposer une censure ; le message est remplacé en place pendant un vote communautaire dont les résultats restent visibles en direct ;
9. le profil permet de retrouver les publications du joueur sans devenir un flux social global ni contourner les frontières de ward ;
10. une vidéo ne peut apparaître que si elle provient d'une source officielle, est liée éditorialement au chapitre et respecte le consentement YouTube.

Le cercle de la liseuse n'est donc ni un réseau social global, ni le flux public montré dans le premier mockup. C'est une conversation spirituelle de proximité, bornée par la paroisse actuelle du joueur.

## 2. Règles non négociables

### 2.1 Primauté de la lecture

- Aucun fil de commentaires ne reste ouvert à côté des versets par défaut.
- Aucun compteur, réaction ou recommandation ne doit dépasser visuellement le titre du chapitre ou le texte.
- Aucun autoplay, pop-up social, toast promotionnel ou récompense animée ne survient pendant la lecture.
- Les illustrations restent des respirations éditoriales rares, au maximum trois par chapitre, ancrées après les versets concernés.
- Les panneaux secondaires se ferment pour rendre au texte toute la largeur utile.

### 2.2 Appartenance à une ward

- La ward autorisée est toujours `current_street_person.ward`.
- `current_ward`, le cookie `noche_ward`, un `ward_code` d'URL, un champ de formulaire ou un identifiant envoyé par le client ne suffisent jamais à autoriser le cercle.
- Dans cette documentation, la « ward associée au joueur » désigne donc `Person#ward`, pas la ward simplement visitée dans l'interface.
- Une personne sans profil reconnu sur l'appareil n'accède pas au cercle.
- Une personne dont `ward_id` est nul n'accède pas au cercle et ne voit ni messages, ni auteurs, ni nombre de participants d'une autre ward.
- Toutes les lectures et écritures sociales sont vérifiées côté serveur avec la ward actuelle de la personne.
- Les canaux temps réel sont eux aussi autorisés et segmentés par `ward_id` et référence canonique du chapitre.
- Il n'existe pas de recherche ou de navigation permettant de consulter le cercle d'une autre ward.

### 2.3 Confidentialité spirituelle

- Un surlignage, un signet ou une note est privé par défaut.
- Les tags, carnets et liens entre passages sont eux aussi privés par défaut.
- Rien n'est publié automatiquement à partir d'un repère personnel.
- Partager dans le cercle est une action séparée avec aperçu du texte envoyé et rappel explicite de l'audience : « Ta paroisse ».
- Le contenu des notes privées et des messages n'est jamais envoyé aux outils d'analytics, aux logs applicatifs ou à un moteur de recommandation.
- Il n'y a pas de messages privés entre joueurs dans ce périmètre.

### 2.4 Éditorial et doctrine

- Les résumés, invitations à accueillir le texte, questions de réflexion, définitions lexicales et associations de vidéos sont des contenus éditoriaux versionnés et approuvés.
- Aucun texte doctrinal ou historique n'est généré à la volée par une IA dans la liseuse.
- Un contenu non approuvé, incomplet ou sans source échoue fermé : le bloc concerné est absent et la lecture reste disponible.
- Les quatre langues de Noche Live doivent avoir une parité fonctionnelle. Une langue sans contenu approuvé ne reçoit pas silencieusement un texte d'une autre langue.

### 2.5 Direction visuelle

- La liseuse est une exception justifiée au chrome de jeu : elle occupe une chambre de lecture plein écran, sans HUD joueur et sans dock global Noche Live.
- Toute la liseuse reste dans la famille crème/ivoire. Une illustration monochrome or/ivoire peut accompagner l'en-tête du chapitre et le repère de défilement, mais aucun décor bleu ou Celestial Dark ne paraît dans cette surface.
- Le réglage de fond de la liseuse est un réglage de lisibilité (`papier`, `doux`, éventuellement `fort contraste`), pas un interrupteur de thème.
- L'or sert à la signature, au focus et aux repères importants. Le corps du texte reste en encre à fort contraste.

### 2.6 Gouvernance sans modérateur

- Aucun profil, dirigeant de ward, présentateur ou administrateur technique ne possède de droit individuel de censure dans le cercle.
- Toute proposition est attribuée, limitée à la ward et soumise à un vote `Oui` / `Non` d'au moins deux jours.
- Pendant le scrutin, le message reste à sa place mais son corps est masqué et remplacé par l'invitation à voter.
- Les nombres et pourcentages sont visibles en temps réel, avec une présentation neutre des deux choix.
- Un cron applique automatiquement une politique versionnée ; propositions, suffrages, changements et décisions restent traçables.

## 3. Contrat émotionnel

La liseuse doit faire ressentir successivement :

1. **Accueil** — « Je peux entrer dans ce texte sans être pressé. »
2. **Compréhension** — « Je sais brièvement où je suis et ce que je vais lire. »
3. **Présence** — « Le texte est grand, stable et confortable pour moi. »
4. **Mémoire** — « Je peux garder ce qui m'a touché et retrouver mon chemin. »
5. **Appartenance** — « D'autres personnes de ma paroisse lisent aussi, sans envahir ma lecture. »
6. **Prolongement** — « Si je le souhaite, je peux écouter, regarder ou parler de ce chapitre. »

La boucle calme cible est :

`ouvrir → accueillir → lire → marquer → reprendre ou terminer → percevoir le mouvement → choisir de prolonger`

## 4. Ce que les mockups fixent

Les mockups ne sont pas des écrans à recopier pixel par pixel. Ils fixent les décisions suivantes.

### 4.1 Éléments conservés de la proposition initiale

- Une vraie surface desktop, pas un simple agrandissement de la vue mobile.
- Un chapitre clairement identifié, avec durée et progression.
- Des repères personnels accessibles pendant la lecture.
- Une présence communautaire visible.
- Des suites de lecture ou contenus complémentaires.
- Une direction artistique digne de l'univers Noche Live.

### 4.2 Éléments écartés ou déplacés

- Le paysage photographique ne sert pas de fond au texte long.
- Le texte ne descend jamais à une taille de « dashboard ».
- Le flux social avec likes et commentaires n'est pas affiché en permanence à droite du texte.
- Les recommandations ne forment pas un carrousel promotionnel collé au chapitre.
- Les notes ne sont pas limitées à de petites cartes difficiles à relire.
- La preuve sociale n'est pas globale quand l'expérience promet un cercle de proximité.

### 4.3 Cible mobile

À `390 × 844`, l'écran montre une seule colonne :

- en-tête compact avec retour, référence, progression et bouton `Aa` ;
- carte d'accueil du chapitre, réductible après la première lecture ;
- texte en grand corps, sur une surface papier pleine largeur utile ;
- barre d'action contextuelle uniquement lorsqu'un passage est sélectionné ;
- signal discret du mouvement de lecture ;
- navigation locale en trois destinations : `Lire`, `Mes repères`, `Le cercle`.

Les repères et le cercle s'ouvrent comme des vues dédiées ou des feuilles plein écran. Ils ne réduisent pas la colonne de texte.

Dans la vue mobile `Le cercle`, les messages forment une liste verticale. Lorsqu'un vote est ouvert, la publication concernée garde son auteur et sa position entre les messages ordinaires, mais affiche à la place du corps la carte de censure, les deux choix, le temps restant et les résultats en direct.

### 4.4 Cible tablette

À `768 × 1024`, la chambre de lecture reste centrale. Les repères et le cercle s'ouvrent dans un panneau latéral temporaire, sans descendre le texte sous une largeur confortable.

### 4.5 Cible desktop

À `1440 × 900`, la composition comporte trois zones, mais une seule zone dominante :

- **gauche, étroite** : retour, progression dans le parcours, contexte du mouvement de lecture et navigation locale ;
- **centre, dominante** : accueil éditorial, texte du chapitre, illustrations rares et fin de lecture ;
- **droite, étroite** : panneau compagnon repliable pour les repères, l'historique du chapitre ou l'entrée du cercle.

Le centre vise une mesure de `60–72ch`. Si la fenêtre devient trop étroite, les colonnes latérales deviennent des tiroirs avant que le texte ne soit comprimé.

## 5. Objectifs et non-objectifs

### 5.1 Objectifs joueur

- Lire un psaume ou un chapitre long sans fatigue visuelle.
- Régler la lecture une fois et retrouver ces préférences plus tard.
- Comprendre en quelques lignes le genre, la situation et le mouvement du chapitre.
- Reprendre à son dernier verset utile.
- Distinguer surlignage, signet et note.
- Transformer une sélection précise en note, classement, carnet ou référence croisée sans quitter le texte.
- Retrouver les différentes visites et repères liés au chapitre.
- Sentir qu'il rejoint un mouvement réel, particulièrement dans sa paroisse.
- Choisir de rejoindre une conversation bornée et sûre.
- Participer à la responsabilité de sa ward sans dépendre d'un modérateur ni recevoir un pouvoir permanent.
- Retrouver depuis son profil toutes les réflexions et questions qu'il a publiées dans le cercle.
- Découvrir une vidéo officielle réellement liée au passage, sans pistage préalable.

### 5.2 Objectifs produit

- Faire de La Parole une destination régulière et non un écran secondaire.
- Augmenter la proportion de lectures qualifiées, de reprises et de chapitres terminés.
- Donner une utilité durable à l'historique et aux surlignages déjà collectés.
- Créer une présence sociale locale sans fabriquer de classement spirituel.
- Réutiliser les services de contenu, d'illustrations, de comptage et de vidéo déjà présents.
- Garder les pages bibliques publiques indexables, rapides et libres de toute donnée privée.

### 5.3 Non-objectifs

- Transformer la Bible en fil social global.
- Mesurer la foi, classer les lecteurs ou attribuer des points à une lecture.
- Autoriser une ward à observer une autre ward.
- Publier automatiquement des notes privées.
- Héberger des débats publics, des messages privés ou des contenus anonymes.
- Créer un rôle de modérateur, un pouvoir de retrait individuel ou une hiérarchie de votants.
- Transformer le profil d'un joueur en flux public global ou en moyen d'observer une autre ward.
- Faire une recherche YouTube ouverte depuis le navigateur du joueur.
- Remplacer le programme d'étude hebdomadaire existant.
- Produire automatiquement des explications doctrinales non relues.
- Ouvrir la recherche ou la définition à un moteur web non approuvé.
- Partager ou rendre collaboratif un carnet personnel dans le MVP.

## 6. État actuel à préserver ou faire évoluer

### 6.1 Liseuse authentifiée

- `ScripturesController#show` charge le chapitre depuis le service de contenu de l'Église.
- `app/views/scriptures/_reader.html.erb` rend aujourd'hui une modale avec titre, résumé, versets, illustrations et partage.
- `app/javascript/controllers/scripture_controller.js` qualifie une lecture après 10 secondes visibles et 50 % du contenu.
- Le même contrôleur sait créer et supprimer des surlignages à partir d'une sélection de texte.
- La liseuse ne mémorise pas encore les préférences typographiques, la position de reprise ou un historique général de progression par chapitre.

### 6.2 Données personnelles existantes

- `ScriptureHighlight` conserve une plage de texte et le texte sélectionné, mais ne distingue pas signet, intention ou note.
- La sélection actuelle crée automatiquement un surlignage après un court délai ; elle ne propose ni style de trait, ni palette, ni tags, ni carnet, ni lien entre passages.
- `ReadingProgress` concerne le programme d'étude et ne doit pas être détourné pour la reprise générale de tous les chapitres.
- `ScriptureChapterRead` est un événement de lecture qualifiée unique par lecteur, chapitre et jour.
- `ScriptureChapterStat` est un agrégat global. Il n'est pas une mesure de la ward.
- `GET /parole/historique` valorise déjà les lectures et surlignages par collection, mais pas encore l'histoire détaillée avec un chapitre.

### 6.3 Identité et ward

- Le profil courant est retrouvé par le cookie signé `noche_street_person` puis vérifié par l'existence d'un `PersonDevice` lié au cookie d'appareil.
- `Person` appartient optionnellement à une `Ward`.
- Le cookie `noche_ward` représente un contexte de navigation. Il ne constitue pas une preuve d'appartenance.
- La route communautaire d'étude actuelle accepte un `ward_code` et mémorise la ward demandée. Ce comportement ne doit pas être réutilisé pour le nouveau cercle.
- `People::Transfer` permet de changer la ward d'une personne sans perdre sa progression.

### 6.4 Contenus et médias

- `Scriptures::Read` fournit déjà le titre, le résumé source, les versets et l'URL de référence.
- `Scriptures::Illustrations` sait insérer jusqu'à trois images sûres et pertinentes après les versets concernés.
- `ChurchVideos::Catalog` sait chercher dans des chaînes officielles configurées, vérifier l'intégrabilité et mettre les métadonnées en cache.
- Le lecteur vidéo existant utilise `youtube-nocookie` et attend un consentement avant de contacter YouTube.

## 7. Architecture d'information cible

La liseuse possède trois destinations locales dans sa chambre plein écran. Le HUD et le dock global de Noche Live disparaissent pendant la lecture ; le retour explicite à `La Parole` permet de quitter cette surface.

### 7.1 Lire

Contient :

- référence et traduction/source ;
- progression du chapitre ;
- accueil éditorial ;
- texte intégral ;
- illustrations éditoriales ;
- contrôle audio si une source officielle et approuvée existe plus tard ;
- pied de provenance canonique obligatoire ;
- fin de chapitre et choix de prolongement.

Le pied de provenance se trouve après le dernier verset et avant les prolongements facultatifs. Il affiche au minimum `Origine du texte`, le nom de la traduction ou du corpus lorsque cette information est disponible, puis un lien explicite vers la page officielle correspondante sur le site de **l'Église de Jésus-Christ des Saints des Derniers Jours**. Le lien ouvre la source dans un nouvel onglet avec `rel="noopener"`. Ce bloc reste présent même lorsque l'accueil éditorial, le cercle ou les vidéos sont indisponibles ; il n'est ni réduit à une icône, ni déplacé dans un menu secondaire.

### 7.2 Mes repères

Contient :

- surlignages du chapitre ;
- signets ;
- notes ;
- filtres par intention ;
- tags personnels ;
- carnets de lecture ;
- liens créés entre passages ;
- historique des visites qualifiées ;
- dernière position et action `Reprendre` ;
- accès à l'historique complet de La Parole.

Cette vue est strictement privée.

### 7.3 Le cercle

Contient :

- identité de la ward du joueur ;
- mouvement de lecture du chapitre dans cette ward ;
- réflexions et questions explicitement publiées pour cette ward ;
- formulaire de contribution, lorsque la fonctionnalité d'écriture est activée ;
- propositions de censure et votes communautaires en cours ou terminés dans cette ward.

Cette vue n'est ni publique, ni indexable, ni accessible sans profil et ward valides.

## 8. Expérience de lecture

### 8.1 En-tête

L'en-tête affiche seulement :

- retour ;
- livre et chapitre ;
- position, par exemple `3 sur 9` ;
- bouton `Aa` ;
- accès compact aux repères.

La durée estimée peut être affichée à l'ouverture, mais disparaît de l'en-tête pendant le défilement si elle encombre la lecture.

### 8.2 Accueil du chapitre

Avant le premier verset, une carte « Pour accueillir ce chapitre » contient au maximum :

- une phrase d'invitation ;
- un résumé de deux ou trois lignes ;
- une étiquette de genre ou de thème.

La carte n'ouvre aucun panneau historique détaillé. Elle est réductible ; après une première lecture qualifiée, son état réduit peut être mémorisé par chapitre sans supprimer définitivement l'invitation et le résumé.

### 8.3 Typographie et largeur

Le menu `Aa` propose :

- taille du texte : 90 %, 100 %, 115 %, 130 %, 145 % ;
- interligne : compact, confortable, ample ;
- largeur desktop : concentrée, confortable, large ;
- police : lecture éditoriale ou système accessible ;
- fond de lecture : papier, doux, fort contraste ;
- illustrations : affichées ou masquées.

Garde-fous :

- corps par défaut d'au moins `18px` sur mobile et `19px` sur desktop ;
- interligne par défaut autour de `1.65` ;
- mesure cible de `60–72ch` ;
- commandes tactiles d'au moins `44 × 44px` ;
- aucun réglage ne peut produire un contraste ou une taille sous les seuils d'accessibilité retenus.

### 8.4 Mémorisation des préférences

- Pour une personne reconnue, les préférences sont enregistrées côté serveur.
- Pour un invité, elles sont conservées localement dans `noche_scripture_reader_preferences:v1`.
- Quand un invité devient une personne reconnue, les préférences locales sont importées si aucune préférence serveur n'existe déjà.
- Les préférences sont globales à la liseuse, sauf l'état réduit de l'accueil qui peut être propre au chapitre.
- La préférence de fond ne modifie pas le thème artistique global du Hub.

### 8.5 Progression et reprise

La liseuse mémorise régulièrement, sans requête à chaque pixel :

- dernier verset majoritairement visible ;
- position relative dans ce verset si nécessaire ;
- ratio de progression ;
- date de dernière ouverture ;
- date de fin du chapitre.

Une mise à jour est envoyée après un changement significatif de verset, à la mise en arrière-plan et à la fermeture. Les écritures sont limitées et dédupliquées.

À la prochaine ouverture :

- si la progression est faible, le chapitre repart du début ;
- sinon un choix non bloquant propose `Reprendre au verset N` ou `Recommencer` ;
- un lien partagé vers un verset garde la priorité sur la reprise personnelle.

### 8.6 Fin du chapitre

Après le dernier verset, la liseuse présente un seul temps de conclusion :

- confirmation calme de lecture terminée ;
- rappel d'un repère personnel éventuel ;
- choix entre `Garder une note`, `Voir le cercle`, `Regarder la vidéo` ou `Continuer` ;
- jamais plus d'une action primaire dorée.

La fin ne donne ni points, ni rang, ni jugement spirituel.

## 9. Sélection, repères personnels et éditeur

### 9.1 Principe : la sélection est une porte d'entrée

La sélection ne doit pas être traitée comme un raccourci vers une seule action. Elle ouvre trois couches distinctes :

1. **Ancre textuelle** — la plage exacte choisie dans le chapitre.
2. **Annotation personnelle** — la manière dont le joueur souhaite garder et organiser cette plage.
3. **Outils** — les actions ponctuelles appliquées au texte : rechercher, définir, copier ou partager.

Cette séparation permet à une même annotation de cumuler, par exemple, un soulignement, une note, deux tags, une présence dans un carnet et un lien vers un autre passage. Rien n'oblige à créer cinq objets visibles superposés.

### 9.2 Deux échelles de mémoire

La liseuse distingue :

- **le chapitre entier**, avec un signet disponible dans l'en-tête et une note générale éventuelle ;
- **un passage précis**, sélectionné au mot près avec début et fin dans un ou plusieurs versets.

Un signet de chapitre sert à revenir à la lecture. Un signet de passage sert à revenir à une idée. Les deux apparaissent dans `Mes repères`, mais leur échelle est toujours explicite.

### 9.3 Interaction de sélection

La création automatique après 450 ms doit être supprimée. Après une sélection native avec poignées tactiles, une barre contextuelle courte propose :

- `Surligner` ;
- `Noter` ;
- `Signet` ;
- `Plus`.

`Plus` ouvre une feuille d'actions contenant :

- ajouter à un carnet ;
- ajouter ou modifier des tags ;
- relier à un autre passage ;
- rechercher cette expression ;
- définir un mot ;
- copier ;
- partager.

Sur mobile, la feuille s'ouvre depuis le bas et ne masque pas durablement le passage sélectionné. Sur desktop, une barre compacte reste près de la sélection tandis que les éditeurs longs utilisent le panneau compagnon. Les libellés ne doivent pas être tronqués.

Chaque action doit aussi être disponible au clavier. La fermeture restitue le focus au passage concerné.

### 9.4 Style visuel du repère

`Surligner` ouvre un choix compact entre :

- fond coloré ;
- soulignement ;
- aucune marque visuelle, pour une note ou un signet discret.

Une palette courte de couleurs tokenisées est proposée. Les couleurs doivent rester lisibles sur les fonds de lecture autorisés et en Celestial Light comme en Celestial Dark. Elles ne constituent jamais le seul signal : le type de trait, l'icône et le libellé restent disponibles.

Une couleur peut être associée à une intention personnelle, sans imposer une signification doctrinale universelle. Le vocabulaire initial proposé est :

- promesse ;
- question ;
- gratitude ;
- appel à agir ;
- à relire.

Le joueur peut changer cette association. Les intentions servent à retrouver ses repères, jamais à profiler sa spiritualité.

Lorsqu'une nouvelle plage recouvre un repère existant, la liseuse propose `Étendre`, `Modifier l'existant` ou `Créer séparément`. Elle ne superpose pas silencieusement plusieurs aplats illisibles.

### 9.5 Éditeur d'annotation

L'éditeur contient :

- citation et aperçu du passage ;
- style et couleur ;
- intention facultative ;
- texte de note facultatif ;
- tags personnels ;
- carnets auxquels appartient le repère ;
- liens éventuels vers d'autres passages ;
- action `Me le rappeler` prévue seulement si un cas d'usage et une politique de notification sont approuvés ;
- suppression avec annulation courte.

L'enregistrement est explicite lorsqu'un texte de note est saisi. Un changement simple de couleur ou de style peut être sauvegardé immédiatement avec un feedback discret et une possibilité d'annuler.

### 9.6 Tags personnels

Les tags sont des mots courts créés par le joueur pour classer ses annotations à travers toute la bibliothèque, par exemple `famille`, `prière` ou `préparer une leçon`.

Règles :

- tags privés ;
- longueur et nombre limités ;
- comparaison insensible à la casse et aux accents pour éviter les doublons ;
- suggestions tirées uniquement des tags déjà créés par cette personne ;
- aucun tag global populaire ;
- aucun envoi du nom du tag à l'analytics.

Les intentions prédéfinies et les tags libres restent deux mécanismes distincts : les premières simplifient le filtrage, les seconds appartiennent au vocabulaire personnel du lecteur.

### 9.7 Carnets de lecture

Un carnet regroupe des annotations et des signets dans un objectif personnel, par exemple :

- `Étude personnelle` ;
- `Préparer une leçon` ;
- `À partager en famille` ;
- `Psaumes de confiance`.

Une annotation peut appartenir à plusieurs carnets. Un carnet possède un nom, une description facultative et un ordre manuel. Les carnets sont privés au MVP ; partager un carnet entier ou collaborer dessus est un non-objectif tant que les droits et la confidentialité n'ont pas été conçus.

### 9.8 Liens entre passages

Le joueur peut relier son annotation à une autre référence canonique. Le flux est :

1. choisir `Relier à un passage` ;
2. rechercher un livre, chapitre ou verset dans le corpus interne ;
3. prévisualiser la cible ;
4. confirmer le lien ;
5. naviguer ensuite dans les deux sens depuis `Mes repères`.

Le lien est personnel et interne à la bibliothèque. Les URL web libres ne sont pas acceptées dans ce périmètre. La suppression du lien ne supprime aucun des deux repères.

### 9.9 Outils appliqués au texte

#### Rechercher

La recherche utilise la sélection comme requête dans le corpus scripturaire approuvé. Elle présente les occurrences par livre et chapitre et permet de revenir à la sélection d'origine. Elle n'envoie pas la requête à un moteur web.

#### Définir

`Définir` explique un mot ou une expression à partir d'un lexique approuvé et localisé. Le résultat indique sa source et la langue concernée. Sans définition approuvée, l'action affiche honnêtement qu'aucune définition n'est disponible ; elle ne génère pas une réponse doctrinale.

#### Copier

La copie contient par défaut le texte, la référence et un lien canonique. Elle n'inclut jamais la note, les tags ou le nom du carnet sans choix explicite.

#### Partager

Deux destinations sont distinguées :

- partage système vers une application choisie par le joueur ;
- partage vers le cercle de sa ward.

Dans les deux cas, un aperçu montre le contenu exact. Le partage vers le cercle suit en plus le contrat d'audience et d'autorisation de la section 11. La note privée n'est jamais préremplie dans le message social.

### 9.10 Annulation et cycle de vie

- Toute mutation donne un feedback immédiat sans interrompre la lecture.
- Une suppression reste restaurable pendant une courte fenêtre.
- `Annuler` restaure aussi bien un style qu'une suppression récente.
- Une restauration est confirmée côté serveur ; elle ne dépend pas seulement de l'état visuel local.
- Un brouillon de note est conservé localement en cas de perte réseau, sans être confondu avec une note sauvegardée.
- La sélection visuelle disparaît après l'action, mais le repère persistant reste identifiable.

### 9.11 Historique du chapitre

Le panneau `Mon histoire avec ce chapitre` affiche :

- première lecture qualifiée ;
- dernière lecture ;
- nombre de jours de lecture qualifiée ;
- dernière position ;
- repères classés chronologiquement ;
- carnets et tags liés à ce chapitre ;
- liens entrants et sortants créés par le joueur ;
- évolution des notes sans exposer un journal technique de toutes les modifications.

Le joueur peut filtrer par style, intention, tag ou carnet, puis rejoindre directement le verset concerné.

## 10. Mouvement de lecture

La liseuse doit faire sentir une présence collective avant même d'ouvrir la conversation.

Deux niveaux sont distingués :

- **mouvement Noche Live** : compteur global existant, secondaire et éventuellement visible sur les surfaces de découverte ;
- **mouvement de ma paroisse** : nombre de personnes de la ward ayant qualifié ce chapitre sur une période donnée.

Dans la liseuse authentifiée, le message principal est local, par exemple :

> 12 personnes de ta paroisse ont lu ce psaume cette semaine.

Règles :

- ne pas afficher les personnes une à une sans leur action sociale explicite ;
- masquer les très petits nombres si cela permettrait d'inférer l'activité d'une personne ;
- utiliser des paliers ou une formulation non chiffrée sous le seuil de confidentialité ;
- ne jamais produire de classement de lecteurs ou de wards ;
- ne pas confondre ouverture et lecture qualifiée.

Le seuil exact de confidentialité doit être validé avant lancement. La recommandation initiale est de n'afficher un nombre exact qu'à partir de cinq personnes distinctes.

## 11. Le cercle de la ward

### 11.1 Promesse

Le cercle répond à une question simple : « Qu'est-ce que ce passage fait résonner dans ma paroisse ? »

Il ne cherche pas à maximiser le temps passé ou les réactions. Il permet une conversation courte, lisible et rattachée au texte.

Dans le MVP, le « cercle d'amis » désigne ce cercle paroissial : tous les auteurs et lecteurs autorisés appartiennent à la ward actuelle du joueur. Il n'existe pas encore de graphe d'amitié, de demande d'ami ou d'abonnement individuel. Si un sous-cercle d'amis explicite est ajouté plus tard, les deux personnes devront appartenir à la même ward au moment de chaque accès et la relation deviendra inactive dès le transfert de l'une d'elles. Une amitié ne permettra jamais de contourner la frontière de ward.

### 11.2 Contrat d'accès

Le serveur applique ce contrat à chaque requête :

1. retrouver `current_street_person` ;
2. vérifier que cette personne est encore reconnue par un `PersonDevice` de l'appareil ;
3. vérifier que `person.ward_id` est présent ;
4. charger la conversation avec `ward_id: person.ward_id` et la référence canonique du chapitre ;
5. ignorer ou rejeter tout `ward_id` fourni par le client ;
6. refaire la même vérification avant création, réponse, modification, suppression, proposition de censure, vote, consultation de l'historique et abonnement temps réel.

Une politique dédiée, par exemple `ScriptureCircles::Access`, devient l'unique point de décision. Les contrôleurs ne reconstruisent pas cette logique séparément.

La liste privée des publications du propriétaire constitue la seule exception de lecture multi-wards : elle est autorisée par une politique distincte fondée sur `viewer_person.id == profile_person.id`, ne retourne que les propres publications du joueur et n'accorde aucun accès aux fils, réponses ou activités des anciennes wards.

### 11.3 États d'accès

- **Invité** : aperçu neutre de la promesse, sans aucune donnée de ward, et action pour créer ou retrouver sa fiche.
- **Profil sans ward** : explication et action pour associer une paroisse.
- **Ward valide, cercle désactivé** : mouvement de lecture éventuel, mais aucune conversation.
- **Ward valide, cercle en lecture seule** : messages visibles, publication fermée avec explication.
- **Ward valide, cercle actif** : lecture et publication autorisées.
- **Message avec vote ouvert** : auteur, heure et place dans le fil restent visibles, mais le corps est remplacé par l'invitation à voter et les résultats en direct ; le corps original n'est pas retourné par l'API normale.
- **Message conservé après vote** : corps restauré, accompagné d'un accès discret au résultat et à l'historique du scrutin.
- **Message censuré par la ward** : pierre tombale à la même place dans le fil, résultat final et historique consultables ; le corps original n'est jamais rendu dans le parcours normal.
- **Message supprimé par son auteur** : pierre tombale si des réponses ou un vote existent, sinon retrait de la liste courante ; l'historique requis reste conservé selon la politique de rétention.

### 11.4 Contenu d'un fil

Un fil correspond à une ward et un chapitre canonique. Un message peut être :

- une réflexion ;
- une question ;
- une réponse à un message existant.

Un message peut être ancré à un ou plusieurs versets. Les réponses sont limitées à un niveau pour éviter un forum illisible.

Le corps d'une réflexion, d'une question ou d'une réponse est limité à **500 caractères maximum**. Cette contrainte s'applique à la création comme à chaque modification : le cercle accueille une pensée courte rattachée au texte, pas un discours.

Le MVP n'inclut pas :

- likes publics ;
- score de popularité ;
- tri algorithmique ;
- hashtags ;
- pièces jointes ;
- liens externes ;
- messages anonymes ;
- messages privés.

Le tri par défaut est chronologique, avec possibilité éditoriale ultérieure de mettre en avant une question officielle clairement identifiée.

L'auteur peut modifier ou supprimer sa propre publication :

- la modification est autorisée tant que l'auteur appartient encore à la ward de publication et qu'aucun vote de censure n'est ouvert ; elle affiche `Modifié` et crée une révision append-only ;
- l'ancre scripturaire et la ward ne changent pas après publication ; une correction d'ancre exige une nouvelle publication ;
- l'ouverture d'un vote fige le corps et sa révision de référence jusqu'à la décision ;
- l'auteur peut retirer son message pendant le vote : le scrutin se termine alors comme `Annulé par l'auteur`, sans effacer son existence, ses suffrages ni son historique ;
- la suppression conserve une pierre tombale si le message possède des réponses, une proposition de censure ou un historique nécessaire à la compréhension du fil ;
- aucune autre personne ne peut réécrire ou supprimer directement ce message par un rôle de modération.

### 11.5 Passage du privé au cercle

Depuis un repère personnel, l'action `Partager au cercle` ouvre un nouveau brouillon social. Le brouillon copie seulement la citation choisie, jamais la note privée.

Avant publication, l'écran montre :

- le texte exact du message ;
- les versets cités ;
- le nom et l'avatar qui seront visibles ;
- l'audience `Membres de [nom de la ward]` ;
- un rappel que le message reste séparé de la note privée.

Le champ de composition affiche `N / 500` et annonce l'approche de la limite sans interrompre la saisie. À 501 caractères, la publication est refusée avec une erreur localisée et le brouillon reste intact. L'interface ne tronque jamais automatiquement le message ; la validation serveur demeure la source de vérité.

### 11.6 Transfert de ward

Lorsqu'une personne change de ward :

- son accès à l'ancien cercle cesse immédiatement ;
- tout abonnement temps réel à l'ancienne ward est interrompu ;
- elle rejoint le cercle de la nouvelle ward pour ses prochaines lectures ;
- ses anciens messages restent rattachés à la ward dans laquelle ils ont été publiés ;
- elle ne peut plus consulter, modifier ou répondre à ces anciens messages depuis sa nouvelle ward ;
- dans l'ancien cercle, ces messages sont affichés comme venant d'un `Ancien membre` et ne révèlent ni la nouvelle ward ni les évolutions ultérieures de sa fiche ;
- elle peut encore retrouver et supprimer ses propres anciens messages dans une vue privée `Mes publications`, sans rouvrir l'accès à l'ancien cercle ;
- un suffrage valablement exprimé dans l'ancienne ward reste attaché au scrutin et compte lors de sa résolution, mais la personne transférée ne peut plus le créer ni le modifier.

Le `ward_id` d'un message est donc figé à sa création. Il ne suit pas les transferts futurs de l'auteur.

### 11.7 Gouvernance communautaire par vote

#### Principe

Il n'existe ni modérateur, ni rôle de modérateur, ni pouvoir permanent de retrait individuel dans le cercle. Toute personne actuellement reconnue dans la ward du fil peut proposer qu'un message soit censuré ; la ward décide ensuite par un vote `Oui, censurer` ou `Non, conserver` limité dans le temps.

La modération reste un acte de responsabilité communautaire, pas une mécanique de compétition : aucun point, badge, classement ou récompense n'est associé aux propositions, aux votes ou à leurs résultats.

#### Ouvrir une proposition

Depuis le menu d'un message, l'action `Proposer une censure` suit ce parcours :

1. choisir un motif dans une liste courte, approuvée et localisée ;
2. ajouter éventuellement une explication brève ;
3. prévisualiser le nom du proposant, l'audience, la durée et l'effet immédiat sur le message ;
4. confirmer explicitement ;
5. valider côté serveur la personne, sa ward actuelle, le message et l'absence d'un autre scrutin ouvert ;
6. créer en transaction la proposition, l'instantané de la révision visée et l'événement d'ouverture ;
7. remplacer immédiatement le corps du message par la carte de vote pour toute la ward.

Une seule proposition peut être ouverte à la fois sur un message. La proposition est attribuée publiquement à son auteur dans la ward. Sa durée est calculée et imposée par le serveur ; elle est de `N` jours et ne peut jamais être inférieure à deux jours. Le client ne choisit ni ne raccourcit `ends_at`. La version de politique applicable est figée à l'ouverture afin qu'un changement ultérieur ne modifie pas les règles d'un vote déjà commencé.

L'ouverture d'une proposition ne crée pas automatiquement un vote `Oui` pour son auteur. Proposition et suffrage sont deux actes distincts ; le proposant vote ensuite comme les autres si la politique d'éligibilité l'y autorise.

#### Affichage dans le fil

Le message conserve exactement sa place parmi les autres messages du chapitre. Pendant le scrutin :

- l'en-tête conserve l'avatar, le nom de l'auteur, l'heure et l'ancre de verset ;
- le corps est remplacé par `Masqué pendant le vote` et `Vote de censure en cours` ;
- la carte nomme le proposant, présente le motif et rappelle la date de fin ;
- les actions `Oui, censurer` et `Non, conserver` ont une taille, un contraste et un poids visuel équivalents, sans code rouge/vert qui orienterait le choix ;
- les résultats sont visibles par tous les membres autorisés et mis à jour en temps réel : nombre et pourcentage de `Oui`, nombre et pourcentage de `Non`, total des suffrages valides et temps restant ; les pourcentages utilisent les suffrages valides exprimés comme dénominateur ;
- les messages ordinaires qui précèdent et suivent restent visibles afin que le fil demeure compréhensible ;
- un lien `Voir la proposition et l'historique` donne accès aux faits du scrutin sans révéler le corps masqué.

Un résultat à zéro, une égalité, de grands nombres et les libellés longs des quatre langues doivent rester lisibles à `390 px`. Les mises à jour sont annoncées avec parcimonie aux technologies d'assistance : le compteur visuel évolue en direct, sans lecture vocale répétitive à chaque suffrage.

#### Droit de vote

Un suffrage est accepté seulement si la personne :

- est reconnue par son appareil au moment du vote ;
- appartient actuellement à la ward du message ;
- dispose d'un cercle actif ou d'un droit de vote explicitement maintenu en lecture seule ;
- envoie son choix avant `ends_at`.

Chaque personne possède un choix courant par proposition. Elle peut passer de `Oui` à `Non`, ou inversement, jusqu'à `ends_at`. L'interface indique clairement `Ton vote`, la dernière heure d'enregistrement et la possibilité de le modifier. Chaque changement ajoute une révision immuable ; il ne remplace pas l'historique antérieur.

Les résultats publics sont agrégés. L'identité individuelle des votants n'est pas exposée dans le fil par défaut, mais le serveur conserve chaque suffrage et ses révisions. Chaque personne peut retrouver son propre choix dans l'historique auquel elle a accès.

#### Résolution automatique

Un cron appelle à fréquence configurée un job idempotent, par exemple `ScriptureCircles::Moderations::ResolveDueJob`, qui traite les propositions `open` dont `ends_at <= now` :

1. sélectionner un lot de propositions arrivées à échéance ;
2. verrouiller chaque proposition afin d'empêcher deux résolutions concurrentes ;
3. recompter la dernière version valide de chaque suffrage, sans faire confiance aux compteurs d'interface ;
4. appliquer la politique de décision versionnée approuvée pour ce scrutin ;
5. enregistrer en une transaction le résultat, les nombres finaux, le taux de participation disponible, la version de politique, l'heure et une empreinte d'intégrité ;
6. restaurer le message si la ward le conserve, ou le remplacer durablement par une pierre tombale si elle le censure ;
7. publier la décision sur le seul flux temps réel de la ward et du chapitre.

Le job est idempotent : une proposition ne peut produire qu'une résolution, même après reprise, concurrence ou nouvelle tentative. Une erreur laisse le scrutin dans un état récupérable et déclenche une alerte technique ; elle n'invente jamais un résultat. La fréquence du job, le quorum, la majorité requise et le traitement exact de l'égalité sont des paramètres de politique versionnés, à décider avant l'ouverture de l'écriture. Recommandation : une égalité ou un quorum non atteint conserve le message.

#### Historique et traçabilité

L'historique d'une proposition conserve de manière append-only :

- le message, sa ward, son auteur et l'empreinte de la révision soumise au vote ;
- le proposant, le motif, l'explication, l'ouverture et l'échéance ;
- chaque suffrage initial et chaque changement, avec son auteur et son heure ;
- les totaux en direct reconstruisibles à partir des suffrages ;
- les annulations, dont le retrait du message par son auteur ;
- la résolution finale, les totaux, la politique appliquée et l'empreinte d'intégrité ;
- les événements techniques nécessaires pour expliquer une reprise ou une erreur du job.

Dans l'interface, l'historique agrégé reste visible uniquement aux membres actuels de la ward. Le corps d'un message censuré n'est pas réexposé dans ce parcours. En base, les données sensibles sont filtrées des logs, chiffrées et soumises à la politique de conservation. Une demande d'effacement peut anonymiser une identité tout en préservant l'intégrité du scrutin et ses totaux. La rétention ne doit jamais écraser un vote ou une décision : elle peut archiver ou anonymiser les acteurs, mais l'enchaînement des événements et les résultats doivent rester reconstructibles.

#### Prévention des abus

- limiter propositions et votes par personne et appareil ;
- appliquer un délai de reprise après des propositions répétées qui n'aboutissent pas ;
- interdire une seconde proposition tant qu'un scrutin est ouvert ;
- refuser toute proposition sur un message déjà supprimé ou censuré ;
- conserver des motifs fermés et une explication courte, sans HTML ni URL ;
- protéger toutes les mutations par CSRF et revalider la ward à chaque action ;
- ne jamais permettre à un présentateur, un dirigeant de ward ou un administrateur technique de convertir son rôle en voix supplémentaire ou en décision unilatérale.

### 11.8 Conditions d'ouverture

L'écriture sociale ne peut être activée avant la disponibilité des éléments suivants :

- règles de communauté et motifs de proposition courts, approuvés et localisés ;
- durée de vote d'au moins deux jours, quorum, seuil, règle d'égalité et version de politique fixés ;
- proposition de censure, masque du corps, vote égalitaire et résultats en direct ;
- job de résolution idempotent, alerte technique et procédure de reprise ;
- historique durable des publications, propositions, suffrages, changements et décisions ;
- limitation de fréquence par personne et appareil ;
- politique de conservation, export et anonymisation ;
- possibilité de désactiver l'écriture par ward comme arrêt d'urgence technique, sans modifier rétroactivement un résultat.

Le déploiement commence en lecture seule, puis ouvre l'écriture sur quelques wards pilotes explicitement activées. Il n'exige et ne crée aucun outil ni rôle de modérateur.

### 11.9 Publications du cercle depuis le profil

La page de profil contient une section `Publications dans Le cercle`. Elle donne une continuité à la parole du joueur sans créer un profil social global.

#### Vue de son propre profil

Le propriétaire retrouve, par ordre antéchronologique, toutes les publications qu'il a créées :

- ward et chapitre de publication ;
- type `Réflexion`, `Question` ou `Réponse` ;
- date, ancre de verset et extrait lorsque le corps est affichable ;
- état `Publié`, `Modifié`, `Vote en cours`, `Conservé`, `Censuré` ou `Supprimé par toi` ;
- action `Ouvrir dans le chapitre` lorsqu'il appartient encore à la ward concernée ;
- action de modification seulement si les règles de la section 11.4 l'autorisent ;
- action de suppression de sa propre publication, y compris après un transfert de ward, sans rouvrir l'ancien cercle.

Cette vue privée inclut les publications des anciennes wards afin de constituer un historique réellement complet. Elle ne charge jamais les messages, réponses, auteurs, suffrages ou activités actuelles de ces anciennes wards. Une publication avec vote ouvert ou censurée reste représentée par son état et son historique autorisé ; son corps n'est pas réexposé par le profil.

#### Vue du profil d'un autre joueur

Un visiteur ne voit la section que si son profil est reconnu et si lui-même et le joueur consulté appartiennent actuellement à la même ward. La liste est alors limitée aux publications :

- créées dans cette ward commune ;
- encore accessibles dans le cercle selon leur état ;
- dont le visiteur pourrait charger le fil et le chapitre par les règles normales de `ScriptureCircles::Access`.

Les publications d'anciennes wards, les éléments supprimés qui ne laissent pas de pierre tombale et tout contenu d'une autre ward sont absents, sans compteur permettant d'en déduire l'existence. Un transfert de l'un des deux joueurs retire immédiatement cette section à l'autre. La page de profil n'accepte jamais de `ward_id` fourni par le client.

#### Présentation et navigation

La section n'affiche pas un mur de cartes : une liste calme et paginée montre d'abord la référence scripturaire, l'extrait et l'état. L'action principale est `Ouvrir dans le chapitre`, avec retour vers le profil. Sur mobile, chaque ligne possède une cible d'au moins `44 × 44px` et les filtres secondaires restent dans une feuille dédiée.

Filtres autorisés pour le propriétaire : chapitre, type, état et période. La vue d'un tiers reste plus simple et ne propose pas d'exploration historique avancée. Il n'existe ni tri par popularité, ni compteur d'engagement, ni recherche globale des publications d'un joueur. La section et ses liens ne sont pas indexables.

## 12. Vidéo liée au chapitre

### 12.1 Expérience

La vidéo est un prolongement facultatif. Elle apparaît :

- dans le panneau compagnon ; ou
- à la fin du chapitre.

Elle n'est jamais injectée entre deux versets, ne démarre jamais automatiquement et ne bloque jamais la lecture.

### 12.2 Sélection

La recherche automatique signifie ici **aider l'équipe éditoriale à trouver des candidats**, pas exposer une recherche ouverte aux joueurs.

Le pipeline cible est :

1. normaliser la référence et la langue ;
2. interroger `ChurchVideos::Catalog` uniquement dans les chaînes officielles configurées ;
3. proposer des candidats selon le livre, le chapitre, les thèmes et les métadonnées ;
4. vérifier chaîne, disponibilité, intégrabilité et langue ;
5. faire approuver manuellement l'association ;
6. publier un lien versionné entre chapitre et vidéo.

Une absence de candidat approuvé produit simplement l'absence de carte vidéo.

### 12.3 Consentement et données

- La miniature doit être proxifiée ou servie sans requête directe vers YouTube avant consentement.
- Le player utilise `youtube-nocookie` après consentement.
- Le refus de consentement laisse une alternative : titre, résumé et lien externe explicite si la politique le permet.
- Regarder une vidéo n'attribue aucun point.
- Les recherches de candidats se font côté serveur ou dans un outil éditorial, avec cache, jamais à chaque affichage du lecteur.

## 13. Modèle de données cible

Les noms restent indicatifs jusqu'à la migration, mais les responsabilités doivent rester séparées.

### 13.1 `ScriptureReaderPreference`

Une ligne par `Person` :

- `person_id`, unique ;
- `font_scale` ;
- `line_height_key` ;
- `measure_key` ;
- `font_family_key` ;
- `background_key` ;
- `illustrations_enabled` ;
- timestamps.

Les valeurs sont validées dans des ensembles fermés. Aucun CSS libre n'est accepté du client.

### 13.2 `ScriptureReadingProgress`

Une ligne par personne, référence et langue :

- `person_id` ;
- `reference` canonique ;
- `locale` ;
- `last_verse` ;
- `last_offset` facultatif ;
- `progress_ratio` ;
- `first_opened_at` ;
- `last_opened_at` ;
- `completed_at` ;
- timestamps.

Index unique : `person_id + reference + locale`.

Cette table sert à reprendre. Elle ne remplace pas `ScriptureChapterRead`, qui demeure la preuve quotidienne d'une lecture qualifiée.

### 13.3 `ScriptureMark`

Nouveau modèle canonique pour remplacer progressivement `ScriptureHighlight` et porter l'agrégat d'annotation :

- `person_id` ;
- `reference` ;
- `locale` ;
- `anchor_scope` : `chapter` ou `passage` ;
- `start_verse`, `start_offset`, `end_verse`, `end_offset`, nuls seulement pour une ancre de chapitre ;
- `selected_text` comme instantané pour une ancre de passage ;
- `source_digest` pour identifier la version du texte ayant servi à la sélection ;
- `visual_style` : `none`, `highlight` ou `underline` ;
- `color_key` facultatif, limité aux tokens approuvés ;
- `bookmarked_at` facultatif ;
- `intent_key` facultatif ;
- `note_body` facultatif ;
- `discarded_at` facultatif pour permettre une restauration courte ;
- timestamps.

Un même `ScriptureMark` peut donc être souligné, contenir une note, être marqué comme signet et appartenir à plusieurs carnets. Le modèle représente une ancre enrichie, pas une action unique.

Une validation exige au moins une propriété utile : marque visuelle, signet, note, tag, carnet ou lien. Une ancre vide n'est pas conservée durablement.

Le passage canonique est relu depuis la source quand il est disponible ; l'instantané permet de conserver le sens du repère si le texte source évolue.

Migration recommandée :

1. créer `scripture_marks` ;
2. recopier tous les `scripture_highlights` comme ancres de passage avec `visual_style: highlight` ;
3. écrire temporairement dans les deux modèles ;
4. comparer les comptes et les plages ;
5. basculer les lectures ;
6. retirer l'ancien modèle dans une version ultérieure seulement.

### 13.4 `ScriptureTag` et `ScriptureMarkTagging`

`ScriptureTag` contient :

- `person_id` ;
- `name` ;
- `normalized_name` ;
- timestamps.

Index unique : `person_id + normalized_name`.

`ScriptureMarkTagging` contient `scripture_mark_id` et `scripture_tag_id`, avec un index unique sur la paire. Les services vérifient que le tag et le repère appartiennent à la même personne.

### 13.5 `ScriptureNotebook` et `ScriptureNotebookEntry`

`ScriptureNotebook` contient :

- `person_id` ;
- `title` ;
- `description` facultative ;
- `position` ;
- timestamps.

`ScriptureNotebookEntry` contient :

- `scripture_notebook_id` ;
- `scripture_mark_id` ;
- `position` ;
- timestamps.

Index unique : `scripture_notebook_id + scripture_mark_id`. Une validation d'appartenance empêche d'ajouter le repère d'une autre personne.

### 13.6 `ScriptureMarkLink`

Lien privé entre un repère source et une cible scripturaire :

- `scripture_mark_id` ;
- `target_reference` ;
- `target_locale` ;
- `target_start_verse`, `target_start_offset`, `target_end_verse`, `target_end_offset` facultatifs ;
- `target_text` comme instantané facultatif ;
- timestamps.

La cible est validée par `Scriptures::Reference`. L'affichage inverse est calculé parmi les liens de la même personne ; aucune annotation d'un autre joueur n'est rendue visible.

### 13.7 `ScriptureChapterGuide`

Contenu éditorial localisé :

- `reference` ;
- `locale` ;
- `welcome_title` ;
- `summary` ;
- `historical_context` ;
- `literary_structure` ;
- `key_terms` structurés ;
- `source_citations` structurées ;
- `status` : `draft`, `review`, `published`, `retired` ;
- `revision` ;
- `reviewed_by` ;
- `published_at` ;
- timestamps.

Index unique recommandé : `reference + locale + revision`. Une seule révision publiée est active par paire référence/langue.

### 13.8 `ScriptureVideoLink`

- `reference` ;
- `locale` ;
- `youtube_video_id` ;
- `channel_id` ;
- `anchor_verse` facultatif ;
- `editorial_reason` ;
- `position` ;
- `status` ;
- `verified_at` ;
- timestamps.

Une validation vérifie que `channel_id` appartient aux chaînes officielles configurées.

### 13.9 `ScriptureCircleThread`

- `ward_id` ;
- `reference` ;
- `status` ;
- timestamps.

Index unique : `ward_id + reference`.

La langue n'isole pas le fil : une ward peut être multilingue. Chaque message conserve sa langue et l'interface peut filtrer ou indiquer celle-ci. Une traduction automatique des messages n'entre pas dans le MVP.

### 13.10 `ScriptureCirclePost`

- `scripture_circle_thread_id` ;
- `ward_id` redondant et immuable pour renforcer les requêtes et contraintes d'accès ;
- `person_id` ;
- `parent_id` facultatif ;
- `kind` : `reflection`, `question`, `reply` ;
- `locale` ;
- `body` ;
- plage de versets facultative ;
- `selected_text` facultatif ;
- `status` : `visible`, `vote_open`, `community_censored`, `author_deleted` ;
- `edited_at`, `deleted_at` facultatifs ;
- timestamps.

Validation ActiveRecord obligatoire dans `ScriptureCirclePost` :

```ruby
MAX_BODY_LENGTH = 500

validates :body,
  presence: true,
  length: { maximum: MAX_BODY_LENGTH }
```

Cette validation couvre les trois valeurs de `kind` et s'exécute à la création comme à la modification. Les contrôleurs et services ne dupliquent pas une constante différente. Une contrainte PostgreSQL `CHECK (char_length(body) BETWEEN 1 AND 500)` complète la validation applicative afin qu'un import ou une écriture hors ActiveRecord ne puisse enregistrer un discours plus long. Aucun chemin ne tronque silencieusement `body`.

Autres contraintes : texte brut ou Markdown très restreint, aucun HTML accepté, aucune URL au MVP, profondeur de réponse maximale de un.

Index de profil : `person_id + created_at DESC`. Pour la vue d'un tiers et les contrôles de périmètre : `person_id + ward_id + status + created_at DESC`.

### 13.11 `ScriptureCirclePostRevision`

- `scripture_circle_post_id` ;
- `editor_person_id` ;
- `ward_id` ;
- `revision_number` ;
- `body` et ancre tels qu'enregistrés à cette révision ;
- `change_kind` : `created`, `edited`, `vote_snapshot`, `author_deleted` ;
- `content_digest` ;
- `created_at`.

Cette table est append-only. Elle permet de prouver quelle révision a été soumise à un vote sans rendre son corps à l'interface après une censure.

### 13.12 `ScriptureCircleModerationProposal`

- `scripture_circle_post_id` ;
- `ward_id` immuable ;
- `proposer_person_id` ;
- `post_revision_id` ;
- `reason_key` et `reason_details` facultatif et limité ;
- `status` : `open`, `kept`, `censored`, `canceled_by_author` ;
- `starts_at`, `ends_at`, avec contrainte serveur et base de données `ends_at >= starts_at + 2 jours` ;
- `resolved_at` facultatif ;
- compteurs finaux `yes_count`, `no_count`, `valid_ballot_count` ;
- `policy_version`, `result_digest` ;
- timestamps.

Index partiel unique : une seule proposition `open` par message. Index de traitement : `status + ends_at`.

### 13.13 `ScriptureCircleModerationBallot`

- `scripture_circle_moderation_proposal_id` ;
- `ward_id` immuable ;
- `voter_person_id` ;
- `choice` : `yes` ou `no` ;
- `cast_at`, `updated_at`.

Index unique : `proposal_id + voter_person_id`. Le modèle représente le choix courant et alimente les résultats en direct ; la résolution recompte néanmoins les lignes valides sous verrou.

### 13.14 `ScriptureCircleModerationBallotRevision`

- `scripture_circle_moderation_ballot_id` ;
- `proposal_id`, `ward_id`, `voter_person_id` ;
- `previous_choice` facultatif, `new_choice` ;
- `created_at`.

Chaque création ou changement de choix écrit une nouvelle ligne append-only dans la même transaction que le suffrage courant.

### 13.15 `ScriptureCircleModerationEvent`

- `proposal_id`, `post_id`, `ward_id` ;
- `actor_person_id` facultatif ;
- `event_type` : `opened`, `ballot_cast`, `ballot_changed`, `canceled_by_author`, `resolution_started`, `resolved`, `resolution_failed` ;
- métadonnées structurées minimales et filtrées ;
- `created_at`.

Les événements ne remplacent ni les suffrages ni leurs révisions. Ils constituent le journal technique et fonctionnel qui permet de reconstruire le cycle de vie du scrutin.

### 13.16 Mode du cercle sur `Ward`

Ajouter un état administrable, par exemple `scripture_circle_mode` :

- `disabled`, valeur par défaut ;
- `read_only` ;
- `active`.

Seule la configuration technique fortement authentifiée peut modifier cet état. Ce réglage sert au pilote et à l'arrêt d'urgence global ou par ward ; il ne permet pas de décider du sort d'un message, ne change aucune règle d'isolation et ne peut pas ouvrir une ward à une autre.

### 13.17 Évolution de `ScriptureChapterRead`

Ajouter un `ward_id` nullable capturé au moment de la lecture qualifiée.

Cette valeur sert au mouvement historique de la ward. Elle ne change pas si la personne transfère ensuite sa fiche. Les anciennes lectures peuvent être rétro-remplies avec la ward actuelle de la personne, mais cette approximation doit être documentée et ne doit pas être présentée comme historiquement exacte.

## 14. Architecture serveur proposée

### 14.1 Agrégateur d'écran

Créer un service de lecture, par exemple `Scriptures::ReaderScreen`, responsable de composer :

- chapitre ;
- illustrations ;
- guide éditorial publié ;
- préférence et progression personnelles ;
- repères du chapitre ;
- preuve sociale globale et locale autorisée ;
- état du cercle, sans charger tout le fil par défaut ;
- vidéo approuvée.

Le contrôleur reste mince. Chaque source peut échouer sans empêcher le rendu du texte biblique.

### 14.2 Services dédiés

- `Scriptures::ReaderPreferences::Update`
- `Scriptures::ReadingProgress::Record`
- `Scriptures::Marks::Create`
- `Scriptures::Marks::Update`
- `Scriptures::Marks::Destroy`
- `Scriptures::Marks::Restore`
- `Scriptures::Tags::Assign`
- `Scriptures::Notebooks::Create`
- `Scriptures::Notebooks::Update`
- `Scriptures::NotebookEntries::Assign`
- `Scriptures::MarkLinks::Create`
- `Scriptures::MarkLinks::Destroy`
- `Scriptures::Search`
- `Scriptures::Definitions::Lookup`
- `Scriptures::ChapterHistory`
- `Scriptures::WardMovement`
- `ScriptureCircles::Access`
- `ScriptureCircles::ThreadFor`
- `ScriptureCircles::Publish`
- `ScriptureCircles::Posts::Update`
- `ScriptureCircles::Posts::Destroy`
- `ScriptureCircles::ProfilePosts`
- `ScriptureCircles::Moderations::Propose`
- `ScriptureCircles::Moderations::CastBallot`
- `ScriptureCircles::Moderations::LiveResults`
- `ScriptureCircles::Moderations::History`
- `ScriptureCircles::Moderations::ResolveDue`
- `Scriptures::VideoCandidates`

Les services de repères reçoivent une `person` et rechargent tous les objets dans son propre scope. Les services sociaux reçoivent une `person`, jamais seulement un `ward_id`.

### 14.3 Contrôleurs et routes

Les chemins exacts seront localisés comme le reste du produit. Le contrat logique recommandé est :

- `PATCH /escrituras/preferencias` ;
- `PUT /escrituras/progreso` ;
- CRUD `/escrituras/reperes` ;
- `POST /escrituras/reperes/:id/restaurar` ;
- CRUD `/escrituras/tags` ;
- CRUD `/escrituras/carnets` ;
- `POST /escrituras/carnets/:id/reperes` ;
- `POST /escrituras/reperes/:id/liens` ;
- `DELETE /escrituras/reperes/:id/liens/:link_id` ;
- `POST /escrituras/recherche` ;
- `POST /escrituras/definition` ;
- `GET /escrituras/historique-du-chapitre?reference=...` ;
- `GET /escrituras/cercle?reference=...` ;
- `POST /escrituras/cercle/messages` ;
- `PATCH /escrituras/cercle/messages/:id` ;
- `DELETE /escrituras/cercle/messages/:id` ;
- `POST /escrituras/cercle/messages/:id/propositions-de-censure` ;
- `PUT /escrituras/cercle/propositions/:id/vote` ;
- `GET /escrituras/cercle/propositions/:id/resultats` ;
- `GET /escrituras/cercle/propositions/:id/historique` ;
- `GET /profils/:person_id/publications-du-cercle?cursor=...`.

Aucune route du cercle ou du profil ne contient un `ward_code`. Si un identifiant de personne, de fil ou de message est envoyé, l'accès est revalidé avec le visiteur courant avant toute réponse. `ScriptureCircles::ProfilePosts` reçoit obligatoirement `viewer_person` et `profile_person` : il applique soit le scope propriétaire, soit l'intersection stricte de leur ward actuelle.

### 14.4 Temps réel

Les résultats du vote doivent évoluer en quasi-temps réel. Le contrat peut être réalisé par Turbo Streams ou WebSocket, avec un polling de repli lorsque le canal n'est pas disponible :

- le nom de flux inclut la ward, la référence et la proposition ;
- l'abonnement est signé ;
- le canal vérifie la personne et sa ward à l'abonnement puis périodiquement ;
- un transfert de ward invalide immédiatement l'abonnement ;
- chaque vote diffuse seulement les nouveaux totaux agrégés, jamais l'identité du votant ;
- l'ouverture remplace le corps par la carte de vote sur tous les clients autorisés ;
- la résolution automatique diffuse le résultat final et restaure le corps ou affiche la pierre tombale ;
- aucun broadcast global n'est produit pour un message, un vote ou un résultat de cercle.

Le polling de repli utilise les mêmes contrôles d'accès, un `ETag` ou une version de résultat et une cadence bornée. Il ne justifie jamais un cache partagé entre wards.

### 14.5 Pages publiques

Les pages SEO de chapitre restent séparées :

- elles montrent le texte, les illustrations sûres et les métadonnées publiques ;
- elles ne chargent ni préférences, ni progression, ni repères, ni mouvement de ward, ni cercle ;
- elles ne posent pas de cookies sociaux nécessaires à l'indexation ;
- elles ne contiennent aucune donnée permettant d'inférer l'appartenance d'une personne.

Les composants de rendu des versets peuvent être partagés sans partager le contrôleur d'accès aux données privées.

## 15. Sécurité et confidentialité

### 15.1 Isolation de ward

Les tests et le code doivent défendre contre :

- modification de `ward_id` dans une requête ;
- accès direct à l'identifiant d'un fil d'une autre ward ;
- accès direct à l'identifiant d'un message d'une autre ward ;
- ouverture d'une proposition, vote ou consultation d'historique par identifiant direct dans une autre ward ;
- consultation de l'identifiant d'un profil d'une autre ward pour déduire ses publications, ses anciennes wards ou leur nombre ;
- abonnement à un flux d'une autre ward ;
- conservation d'une page ouverte après transfert de ward ;
- décalage entre `current_ward` et `current_street_person.ward` ;
- cache fragment partagé entre wards ;
- compteurs de lecture ou de vote calculés à partir du mauvais périmètre ;
- suffrage créé deux fois avec plusieurs appareils pour une même personne.

Les clés de cache social doivent inclure au minimum `ward_id`, référence, statut de publication et version de contenu. Le cache de publications d'un profil distingue explicitement `owner_view` de `ward_view`; ce dernier inclut la ward courante du visiteur et les versions de ward des deux personnes. Aucun fragment de la vue propriétaire n'est réutilisé pour un tiers.

### 15.2 Contenu utilisateur

- Limiter taille et fréquence des messages.
- Recharger repères, tags, carnets et liens à travers les associations de `current_street_person`, jamais avec un `find` global.
- Vérifier qu'un tag, un carnet, un repère et un lien réunis dans une même mutation appartiennent à la même personne.
- Échapper tout contenu à l'affichage.
- Interdire le HTML et les URL au MVP.
- Protéger les mutations par CSRF.
- Refuser les messages composés uniquement de caractères invisibles.
- Refuser tout `body` supérieur à 500 caractères dans le modèle ActiveRecord, y compris lors d'une modification ou d'une réponse ; conserver le brouillon et retourner une erreur exploitable.
- Ne jamais rendre le corps d'un message `vote_open` ou `community_censored` dans une réponse normale, un fragment Turbo, un cache ou un historique public.
- Recharger la publication, la proposition et le suffrage par la ward actuelle avant toute mutation ; ne jamais se fier à l'appartenance envoyée par le client.
- Construire la liste de profil depuis `viewer_person` et `profile_person`, jamais depuis un simple booléen `is_owner` fourni par le client.
- Vérifier l'auteur pour la modification et la suppression, et figer la révision tant qu'un vote est ouvert.
- Appliquer la contrainte d'un suffrage courant par personne et proposition en base de données et dans le service.
- Conserver l'auteur pour la responsabilité, sans exposer d'identifiant technique.
- Ajouter `selected_text`, `note_body`, `body`, `reason_details`, `query`, noms de tags, titres et descriptions de carnets aux paramètres filtrés des logs.
- Ne pas transmettre une recherche ou une demande de définition à un service tiers non approuvé.

### 15.3 Identité à assurance limitée

Le profil joueur actuel est reconnu par appareil et n'est pas un compte fort avec e-mail ou mot de passe. Conséquences :

- aucun rôle de modérateur n'existe : la décision appartient au scrutin de la ward, jamais à une identité plus privilégiée ;
- pas de données hautement sensibles révélées par le cercle ;
- possibilité de déconnecter rapidement une fiche compromise ;
- limites par personne **et** par appareil pour les publications, propositions et suffrages ;
- écriture sociale activée progressivement.

### 15.4 Conservation et droits

Le plan de conservation doit définir avant lancement :

- durée des messages supprimés logiquement avant purge ;
- durée de conservation des repères marqués `discarded_at` après expiration de la fenêtre d'annulation ;
- durée des propositions de censure, suffrages, révisions de suffrages, révisions de messages et événements de résolution ;
- export des repères, notes, tags, carnets, liens, messages, propositions et suffrages propres à la personne dans la copie des données ;
- effacement ou anonymisation lors d'une demande de suppression, sans rendre les totaux du scrutin incohérents ;
- comportement des messages lorsqu'une personne quitte Noche Live ou change de ward.

L'historique public d'un scrutin reste limité aux agrégats de la ward. Les lignes individuelles de suffrage sont des données de responsabilité internes : elles sont accessibles à leur auteur dans son export et ne sont pas envoyées à un outil analytics tiers.

## 16. Accessibilité

La refonte est incomplète tant que les points suivants ne sont pas validés :

- zoom navigateur à 200 % sans perte d'action ;
- taille et interligne réglables sans recouvrement ;
- contraste WCAG AA au minimum pour texte et commandes ;
- ordre de focus prévisible ;
- retour du focus après fermeture des tiroirs ;
- bouton `Aa` nommé explicitement pour lecteur d'écran ;
- versets navigables et citations annoncées sans répéter inutilement les numéros ;
- création, édition et suppression d'un repère utilisables au clavier ;
- barre de sélection et feuille `Plus` utilisables sans geste tactile ;
- focus placé sur la première action contextuelle puis rendu à la plage d'origine ;
- couleurs nommées et accompagnées d'un style ou d'une icône ;
- poignées de sélection natives conservées lorsque la plateforme les fournit ;
- actions contextuelles d'au moins `44 × 44px`, sans libellé tronqué ;
- deux choix de vote d'au moins `44px`, de poids visuel égal, utilisables au clavier et explicitement nommés ;
- résultats en direct compréhensibles sans dépendre de la couleur, y compris à zéro et à égalité ;
- compteur `N / 500` associé au champ par `aria-describedby`, sans annonce vocale à chaque caractère ; l'erreur de dépassement est annoncée une fois et le focus reste dans le composeur ;
- état de sélection non indiqué seulement par la couleur ;
- alternative textuelle aux illustrations ;
- respect de `prefers-reduced-motion` ;
- respect des modes de contraste forcé ;
- aucune action uniquement disponible au survol ;
- annonces `aria-live` rares et non intrusives pour sauvegarde ou erreur.

## 17. États de chargement, erreur et absence

Le texte biblique est la dépendance critique. Tout le reste est progressif.

- **Chapitre indisponible** : erreur claire, nouvelle tentative et accès retour.
- **Guide absent** : pas de squelette permanent, le bloc n'apparaît pas.
- **Illustration absente ou risquée** : omission silencieuse.
- **Préférences indisponibles** : utiliser les valeurs locales ou par défaut.
- **Sauvegarde de progression en échec** : lecture non bloquée, nouvelle tentative limitée.
- **Repères en échec** : garder le brouillon local jusqu'à confirmation ou annulation.
- **Repère existant sélectionné** : ouvrir son état actuel et proposer modification ou suppression, pas une seconde création implicite.
- **Sélections qui se recouvrent** : proposer étendre, modifier ou conserver séparément.
- **Suppression récente** : action `Annuler` visible pendant une courte durée puis état définitivement retiré.
- **Recherche sans résultat** : message honnête et retour au passage d'origine.
- **Définition absente ou non approuvée** : aucune définition inventée, simple état indisponible.
- **Carnet ou tag indisponible** : conserver l'annotation principale et signaler l'échec de classement séparément.
- **Cercle indisponible** : le texte et les repères restent pleinement utilisables.
- **Message supérieur à 500 caractères** : refuser création ou modification, afficher l'erreur localisée près du champ et conserver intégralement le brouillon sans publication partielle.
- **Résultats temps réel indisponibles** : conserver le choix local confirmé, afficher l'heure de la dernière mise à jour et activer le polling de repli.
- **Vote arrivé à échéance pendant l'action** : refuser le suffrage, charger la décision finale et ne pas antidater le vote.
- **Résolution automatique retardée** : afficher `Vote terminé · décision en cours`, désactiver les choix et ne jamais extrapoler le résultat final côté client.
- **Échec du job de résolution** : conserver l'état récupérable, réessayer de manière idempotente et alerter techniquement sans exposer le corps.
- **Vidéo absente** : aucune carte vide.
- **Connexion lente** : aucun déplacement de mise en page lors de l'arrivée des images ou panneaux.

Une version hors connexion peut relire un chapitre déjà chargé et conserver temporairement progression et brouillons. La synchronisation sociale hors connexion n'entre pas dans le MVP.

## 18. Performance

Budgets initiaux :

- premier rendu du texte sans attendre le cercle ou YouTube ;
- pas de requête YouTube au chargement ;
- illustrations avec dimensions réservées et chargement différé ;
- aucun N+1 sur auteurs, repères ou lectures ;
- tags, carnets et liens préchargés seulement dans `Mes repères` ou à l'ouverture de l'éditeur ;
- recherche scripturaire paginée et limitée côté serveur ;
- recherche et définition absentes du chemin critique du premier rendu ;
- pagination du cercle, 20 messages maximum par page initiale ;
- pagination par curseur des publications de profil, sans `OFFSET` profond, avec préchargement borné du chapitre et de l'état de vote ;
- aucun N+1 sur les références, wards historiques et états associés aux publications du profil ;
- résultats en direct servis depuis des compteurs transactionnels, avec les suffrages comme source de vérité et réconciliation à la résolution ;
- index `status + ends_at` et traitement en lots bornés pour le job des scrutins arrivés à échéance ;
- historique du chapitre agrégé côté serveur ;
- sauvegarde de progression limitée à un changement de verset significatif ou un événement de cycle de vie ;
- cache des guides et liens vidéo publiés ;
- cache social toujours cloisonné par ward.

Le poids JavaScript du lecteur doit rester indépendant des outils d'administration éditoriale. La carte de vote est chargée avec le panneau du cercle, jamais sur le chemin critique du texte.

## 19. Internationalisation et contenu

### 19.1 Interface

Tout nouveau libellé doit être rédigé et revu en :

- espagnol ;
- portugais du Brésil ;
- français ;
- anglais.

Le vocabulaire doit évoquer une famille de chapelle et une lecture partagée, pas une plateforme sociale : `Le cercle`, `Ta paroisse lit aussi`, `Partager une réflexion` plutôt que `feed`, `followers` ou `engagement`.

### 19.2 Références canoniques

Le livre et le chapitre sont conservés sous une référence canonique indépendante de la langue. Les titres localisés ne servent pas de clés de jointure.

### 19.3 Workflow éditorial

Le workflow minimal est :

`brouillon → revue historique/doctrinale → revue langue → publication → version suivante`

Chaque guide, définition lexicale et association vidéo doit avoir :

- une source ;
- un auteur ou responsable ;
- un réviseur ;
- une date de publication ;
- une possibilité de retrait rapide.

## 20. Instrumentation

Événements autorisés, sans contenu spirituel :

- `scripture_reader_opened` ;
- `scripture_reader_resumed` ;
- `scripture_reader_preference_changed` ;
- `scripture_qualified_read_recorded` ;
- `scripture_mark_created` avec l'échelle et les capacités activées seulement, sans référence ni contenu ;
- `scripture_mark_updated` avec les familles de champs modifiées seulement ;
- `scripture_selection_action_used` avec l'action générique seulement ;
- `scripture_notebook_entry_added` sans nom de carnet ;
- `scripture_mark_link_created` sans références ni texte ;
- `scripture_chapter_completed` ;
- `scripture_circle_opened` ;
- `scripture_circle_post_created` sans corps ni citation ;
- `scripture_profile_posts_opened` avec `owner_view` ou `ward_view` seulement, sans personne, ward, référence ni contenu ;
- `scripture_circle_moderation_proposed` sans référence, motif libre, personne ni ward ;
- `scripture_circle_ballot_cast` et `scripture_circle_ballot_changed` sans choix ni identité ;
- `scripture_circle_moderation_resolved` avec le type de résultat seulement, sans contenu ni identifiant social ;
- `scripture_video_consent_opened` ;
- `scripture_video_started` si le consentement analytics le permet.

À exclure explicitement :

- texte sélectionné ;
- contenu de note ;
- contenu de message ;
- intention spirituelle ;
- requête libre ;
- nom de personne ;
- identifiant de ward dans un outil tiers non nécessaire.

### 20.1 Indicateurs de succès

- taux de lectures qualifiées par ouverture ;
- taux de reprise après une lecture incomplète ;
- part des lecteurs utilisant un réglage de lisibilité ;
- part des repères retrouvés ou rouverts ;
- taux d'actions de sélection terminées après ouverture de la barre contextuelle ;
- taux de restauration après une suppression, comme indicateur d'erreurs d'interaction ;
- taux de fin de chapitre ;
- ouverture du cercle après lecture, pas au détriment de la lecture ;
- nombre de propositions, participation aux scrutins, délai de résolution, résultats, annulations et erreurs du job ;
- taux de propositions répétées par personne ou appareil dans la télémétrie interne antifraude, sans transformer ces données en score public ;
- temps de réponse et erreurs par source secondaire.

Les métriques sociales ne doivent pas devenir des objectifs de maximisation isolés.

## 21. Plan de livraison

### Phase 0 — Fondations et décisions éditoriales

- Valider le modèle de guide, les sources et le workflow d'approbation.
- Valider le vocabulaire d'intentions et les règles du cercle.
- Fixer la durée par défaut des scrutins, leur durée maximale, le quorum, le seuil de décision, la règle d'égalité et la version initiale de politique ; la durée minimale reste deux jours.
- Valider les motifs de proposition, les règles d'éligibilité, les limites de fréquence et la conservation de l'historique des votes.
- Valider la palette de repères, la source du lexique et les règles de recherche scripturaire.
- Fixer les seuils de confidentialité des compteurs de ward.
- Définir conservation, export et effacement.
- Produire les composants desktop, tablette et mobile dans les deux ambiances issues des œuvres.
- Instrumenter les budgets d'accessibilité et de performance.

Critère de sortie : aucun contenu éditorial ou social ne dépend d'une décision encore implicite.

### Phase 1 — Chambre de lecture

- Recomposer la liseuse autour d'une colonne centrale dominante.
- Ajouter l'accueil du chapitre avec le résumé source existant comme premier fallback approuvé.
- Ajouter `Aa`, préférences serveur et fallback local.
- Ajouter progression, reprise et fin de chapitre.
- Préserver les illustrations éditoriales existantes.
- Valider clavier, lecteur d'écran et trois viewports.

Critère de sortie : un psaume long est confortable, personnalisable et reprenable sans repère social.

### Phase 2A — Annotation personnelle

- Introduire `ScriptureMark`.
- Migrer les surlignages existants sans perte.
- Remplacer la création automatique par `Surligner`, `Noter`, `Signet`, `Plus`.
- Ajouter fond coloré, soulignement, palette et intentions.
- Ajouter signets de chapitre et de passage.
- Ajouter notes, modification des plages et gestion des recouvrements.
- Ajouter suppression restaurable et annulation côté serveur.

Critère de sortie : une sélection précise devient une annotation accessible et réversible, sans création accidentelle et sans perte des anciens surlignages.

### Phase 2B — Organisation et outils de connaissance

- Ajouter tags personnels et carnets privés.
- Ajouter liens privés entre passages et navigation inverse.
- Ajouter copie et partage avec aperçu exact, sans note privée implicite.
- Ajouter recherche dans le corpus interne.
- Ajouter définition à partir d'un lexique sourcé et approuvé.
- Construire `Mon histoire avec ce chapitre`.
- Faire évoluer `/parole/historique` vers les nouveaux repères.

Critère de sortie : le joueur peut organiser et relier sa mémoire scripturaire sans que les outils secondaires ou une source indisponible bloquent la lecture.

### Phase 3 — Mouvement de la ward et cercle en lecture seule

- Capturer `ward_id` sur les nouvelles lectures qualifiées.
- Ajouter `Scriptures::WardMovement` avec seuil de confidentialité.
- Créer fils et messages, mais garder l'écriture désactivée.
- Implémenter l'autorisation fondée sur `current_street_person.ward`.
- Valider tous les tests négatifs inter-wards et de transfert.

Critère de sortie : aucune requête fabriquée ne permet de voir une donnée d'une autre ward.

### Phase 4 — Publication pilote et gouvernance communautaire

- Ajouter règles, composition, réponses, modification et suppression par l'auteur.
- Ajouter la validation ActiveRecord et la contrainte de base limitant chaque message à 500 caractères, avec compteur et erreur localisée dans le composeur.
- Enregistrer les révisions de message de manière append-only.
- Ajouter la proposition de censure, le masque en place et le vote `Oui` / `Non` pendant au moins deux jours.
- Diffuser les résultats agrégés en temps réel avec polling de repli.
- Ajouter le job de résolution idempotent, la politique versionnée et la reprise sur erreur.
- Ajouter l'historique des propositions, suffrages, changements et décisions.
- Ajouter au profil `Publications dans Le cercle`, avec historique complet pour le propriétaire et scope de ward pour les autres visiteurs.
- Ajouter une tâche de démonstration locale idempotente `bin/rails noche:scripture_circle_demo PERSON_ID=...` (avec repli `NAME=...`) qui peuple la ward du profil ciblé et imprime les URLs du chapitre et du profil à ouvrir.
- Ajouter limitation de fréquence par personne et appareil, puis activer quelques wards pilotes.
- Mesurer incidents, participation, tentatives coordonnées et erreurs de résolution avant extension.

Critère de sortie : chaque membre éligible de la ward peut proposer une censure et voter, le message est remplacé en place pendant le scrutin, les résultats sont visibles en direct, la décision automatique est reproductible et aucun rôle de modérateur n'existe.

### Phase 5 — Vidéos officielles liées

- Construire l'outil de recherche de candidats dans `ChurchVideos::Catalog`.
- Ajouter l'approbation et le modèle `ScriptureVideoLink`.
- Afficher la carte après le chapitre ou dans le panneau compagnon.
- Réutiliser le consentement et `youtube-nocookie`.
- Tester les quatre langues et les vidéos retirées.

Critère de sortie : aucun appel YouTube n'est effectué avant consentement et aucun résultat non approuvé n'apparaît au joueur.

### Phase 6 — Raffinement

- Évaluer audio officiel, rappels personnels et vues de parcours.
- Étudier une meilleure découverte des chapitres liés.
- Ajuster les seuils du mouvement de ward à partir de données agrégées.
- Retirer l'ancien modèle `ScriptureHighlight` après audit final de migration.

## 22. Stratégie de tests

### 22.1 Modèles et services

- validation des préférences dans des ensembles fermés ;
- progression monotone raisonnable et reprise par référence/langue ;
- migration exacte des plages de surlignage ;
- ancres de chapitre et de passage, styles, couleurs et restauration ;
- unicité et propriété des repères ;
- impossibilité d'associer le tag, le carnet ou le repère d'une autre personne ;
- normalisation des tags et déduplication par personne ;
- ordre et appartenance multiple des carnets ;
- validation des références cibles et liens inverses limités à la personne ;
- recherche limitée au corpus approuvé ;
- définition publiée et sourcée uniquement ;
- guide publié uniquement ;
- vidéo issue d'une chaîne officielle ;
- mouvement calculé sur des lectures qualifiées ;
- statut et profondeur des messages ;
- `ScriptureCirclePost` accepte exactement 500 caractères et refuse 501 caractères à la création comme à la modification, pour une réflexion, une question et une réponse ;
- le refus ne tronque pas le corps, n'écrit ni publication ni révision et restitue une erreur ActiveRecord localisée ;
- la contrainte PostgreSQL refuse également une écriture directe supérieure à 500 caractères ;
- propriété, modification, suppression et historique des révisions de message ;
- durée de scrutin refusée sous deux jours et calcul de `ends_at` uniquement côté serveur ;
- une seule proposition ouverte par message ;
- un seul suffrage courant par personne, modification du choix et conservation de chaque révision ;
- résultats agrégés cohérents après concurrence, nouvelle tentative et plusieurs appareils ;
- résolution idempotente, verrouillée et reproductible à partir des suffrages ;
- issues `kept`, `censored` et `canceled_by_author` ;
- service de publications du profil : propriétaire multi-wards limité à ses propres messages, tiers limité à la ward commune actuelle ;
- pagination stable et antéchronologique des publications du profil ;
- limitation de fréquence des publications, propositions et suffrages.

### 22.2 Tests critiques d'isolation

Créer systématiquement deux wards A et B, deux personnes et deux appareils.

Vérifier qu'une personne de A ne peut jamais :

- charger le fil de B en modifiant un paramètre ;
- lire un message de B par son identifiant ;
- publier dans B ;
- répondre à un message de B ;
- modifier ou supprimer un message de B ;
- proposer la censure d'un message de B ;
- voter ou consulter les résultats et l'historique d'une proposition de B ;
- consulter les publications du profil d'une personne de B ou en déduire le nombre ;
- obtenir depuis un profil de A les publications que cette personne avait créées dans une ancienne ward ;
- s'abonner au flux de B ;
- voir le nombre de lecteurs de B ;
- récupérer du contenu de B par un cache amorcé précédemment.

Vérifier aussi :

- profil sans ward ;
- cookie `noche_ward` différent de `person.ward_id` ;
- transfert A vers B pendant qu'un panneau est ouvert ;
- ancien message publié dans A après transfert vers B ;
- suffrage valablement exprimé dans A avant transfert, encore compté mais impossible à modifier depuis B ;
- vue propriétaire contenant ses propres publications de A et B sans aucune réponse ni activité des anciennes wards ;
- disparition immédiate de la liste publique d'un profil lorsque le visiteur ou l'auteur quitte la ward commune ;
- corps d'un message avec vote ouvert ou censuré absent des réponses, fragments, caches et logs.

### 22.3 Contrôleurs et système

- invité avec préférences locales ;
- personne reconnue avec préférences serveur ;
- reprise depuis un chapitre ;
- lien direct vers un verset prioritaire ;
- création, édition, recouvrement, suppression, annulation et restauration de chaque repère ;
- sélection au clavier et feuille `Plus` sans libellé tronqué ;
- fond coloré, soulignement et mode sans marque visuelle ;
- création et filtrage par tag et carnet ;
- navigation aller-retour entre deux passages liés ;
- recherche avec résultats et sans résultat ;
- définition disponible et absente ;
- copie et partage ne contenant jamais la note privée par défaut ;
- cercle fermé, lecture seule et actif ;
- création et modification réussies à 500 caractères, refus à 501 avec brouillon intact, erreur localisée et absence de troncature ;
- compteur cohérent avec la validation serveur pour texte accentué et emoji ;
- profil du propriétaire avec toutes ses publications, filtres et pagination ;
- profil d'un autre membre de la même ward avec seulement les publications autorisées de cette ward ;
- profil d'un joueur d'une autre ward sans liste, compteur ni état permettant d'inférer une publication ;
- retour `Profil → chapitre → Profil` et absence d'ouverture d'une ancienne ward ;
- états de profil `aucune publication`, chargement, erreur, vote en cours, censuré et supprimé ;
- fil mobile contenant des messages ordinaires autour d'un message remplacé en place par un vote ;
- ouverture attribuée d'une proposition, motif, échéance et historique ;
- vote `Oui`, vote `Non`, modification du choix et état `Ton vote` ;
- mise à jour en direct des nombres et pourcentages sur deux sessions de la même ward ;
- refus d'un suffrage après échéance et état `Décision en cours` jusqu'au passage du job ;
- restauration du corps après décision de conservation et pierre tombale après censure ;
- retrait par l'auteur pendant un vote et résultat `Annulé par l'auteur` ;
- vidéo avec consentement accepté, refusé et absent ;
- erreurs réseau non bloquantes ;
- navigation complète au clavier.

### 22.4 Régression visuelle

Captures obligatoires :

- `390 × 844` ;
- `768 × 1024` ;
- `1440 × 900` ;
- ambiance Celestial Light dérivée de l'œuvre ;
- ambiance Celestial Dark dérivée de l'œuvre ;
- taille de texte maximale ;
- barre de sélection et feuille `Plus` ouvertes ;
- éditeur de note avec clavier mobile ouvert ;
- palette sur chaque fond de lecture autorisé ;
- panneau repères ouvert ;
- cercle sans ward, vide et rempli ;
- profil propriétaire et profil d'un autre membre avec liste courte, longue, vide et paginée ;
- lignes de publication visible, modifiée, en vote, censurée et supprimée, sans fuite du corps ;
- cercle avec vote ouvert entre deux messages, résultats `0/0`, égalité, majorité nette et grands nombres ;
- proposition conservée, censurée et annulée par l'auteur ;
- boutons de vote et libellés longs dans les quatre langues, avec taille de texte maximale ;
- chapitre avec trois illustrations ;
- chapitre sans guide ni vidéo.

## 23. Critères d'acceptation globaux

La refonte est acceptable lorsque :

- le texte reste l'élément le plus visible sur tous les viewports ;
- un joueur peut modifier et retrouver ses préférences de lecture ;
- un psaume long reste lisible à la taille maximale sans colonne cassée ;
- une lecture peut être reprise au bon endroit ;
- les anciens surlignages sont conservés ;
- les nouveaux repères sont privés et explicitement éditables ;
- une sélection n'enregistre rien avant une action explicite ;
- fond coloré, soulignement, signet, note et absence de marque visuelle sont distinguables ;
- une suppression peut être annulée et restaurée côté serveur ;
- les tags et carnets d'une personne ne peuvent recevoir aucun repère d'une autre personne ;
- un lien entre passages permet une navigation privée dans les deux sens ;
- recherche et définition restent internes, sourcées et non bloquantes ;
- copier ou partager n'inclut jamais une note privée sans choix explicite ;
- l'historique raconte la relation avec le chapitre, pas seulement un compteur ;
- l'accueil éditorial affiché est sourcé, localisé et approuvé ;
- le mouvement de ward respecte un seuil de confidentialité ;
- le cercle ne lit jamais sa ward depuis l'URL ou le client ;
- une personne de la ward A ne peut obtenir aucune donnée sociale de la ward B ;
- un transfert de ward change immédiatement le périmètre accessible ;
- aucune note privée n'est publiée sans confirmation ;
- l'auteur peut modifier ou supprimer son message selon les règles annoncées et chaque révision nécessaire est conservée ;
- aucune réflexion, question ou réponse de plus de 500 caractères ne peut être créée ou enregistrée par modification, même en contournant le formulaire ;
- son propre profil lui permet de retrouver toutes ses publications, y compris celles d'anciennes wards, sans lui rouvrir ces anciens cercles ;
- le profil d'un autre joueur ne montre que ses publications de la ward commune actuelle déjà accessibles au visiteur ;
- aucune URL, compteur, cache ou réponse de profil ne permet d'inférer des publications d'une autre ward ;
- tout membre éligible de la ward peut proposer une censure sans recevoir un rôle ou un pouvoir durable ;
- une proposition dure au moins deux jours selon des dates calculées par le serveur ;
- pendant le vote, le corps du message est absent des réponses normales et remplacé à sa place par la carte de scrutin ;
- les choix `Oui, censurer` et `Non, conserver` ont un poids visuel égal et les résultats agrégés sont visibles en temps réel ;
- une personne ne possède qu'un suffrage courant mais chaque changement de choix est conservé ;
- le job de résolution recompte les suffrages, applique une politique versionnée et reste idempotent ;
- l'historique permet de reconstruire proposition, votes, changements, annulation éventuelle et décision sans réexposer le corps censuré ;
- aucun rôle, outil ou route de modérateur n'existe dans le cercle ;
- aucune vidéo non officielle ou non approuvée n'apparaît ;
- aucune requête YouTube ne part avant consentement ;
- les pages publiques ne contiennent aucune donnée personnelle ;
- les quatre langues et les états d'erreur sont couverts ;
- les tests, la revue visuelle et la revue Noche Live passent sans exception non documentée.

## 24. Découpage initial en tickets

### Fondation

1. Ajouter les modèles et migrations de préférences et progression.
2. Créer `Scriptures::ReaderScreen` et ses contrats de fallback.
3. Définir les tokens de chambre de lecture et le composant responsive.
4. Ajouter les tests d'accessibilité de base.

### Lecture

5. Construire l'en-tête, l'accueil du chapitre et le menu `Aa`.
6. Enregistrer et restaurer les préférences.
7. Enregistrer la position et proposer la reprise.
8. Construire la fin de chapitre et les prolongements.

### Mémoire personnelle

9. Créer `ScriptureMark` et la migration des surlignages.
10. Remplacer la création automatique par la barre `Surligner · Noter · Signet · Plus`.
11. Construire styles, palette, intentions et gestion des plages qui se recouvrent.
12. Construire l'éditeur de note et les signets de chapitre ou de passage.
13. Ajouter suppression restaurable et annulation côté serveur.
14. Créer `ScriptureTag` et les associations privées.
15. Créer les carnets et leur ordre manuel.
16. Créer les liens privés entre passages et la navigation inverse.
17. Construire recherche scripturaire et définition sourcée.
18. Construire `Mon histoire avec ce chapitre`.
19. Adapter `/parole/historique`.

### Éditorial

20. Créer `ScriptureChapterGuide` et son workflow de publication.
21. Créer l'outil de saisie/revue avec sources et versions, y compris le lexique.
22. Produire un lot pilote de chapitres, dont Psaume 52, dans les quatre langues.

### Ward et cercle

23. Capturer la ward sur les lectures qualifiées.
24. Construire le mouvement local avec seuil de confidentialité.
25. Créer fils et messages avec validation ActiveRecord `body <= 500`, contrainte PostgreSQL, compteur UI, modification/suppression par l'auteur et révisions append-only.
26. Implémenter `ScriptureCircles::Access` et les tests inter-wards.
27. Construire les états invité, sans ward, lecture seule, actif, vote ouvert et décision finale.
28. Construire la proposition de censure, l'instantané de révision et le remplacement en place du message.
29. Construire le suffrage `Oui` / `Non`, le changement de choix et les résultats agrégés en temps réel.
30. Construire le job planifié de résolution, le verrouillage, l'idempotence et les alertes de reprise.
31. Construire l'historique des propositions, suffrages, révisions, annulations et décisions.
32. Ajouter limites de fréquence, drapeau d'activation par ward et pilote progressif.
33. Ajouter au profil la liste paginée des publications, ses scopes propriétaire/ward, ses filtres et ses états de contenu.
34. Créer la tâche locale idempotente `noche:scripture_circle_demo` : cibler un profil existant, refuser l'exécution en production, ne jamais changer sa ward, générer plusieurs auteurs dans cette même ward et simuler Psaume 52 avec réflexions, question, réponses, modification, suppression avec pierre tombale, vote ouvert aux résultats visibles, décision passée et historique. Afficher à la fin les URLs exactes du chapitre et du profil.

### Vidéo

35. Créer `ScriptureVideoLink`.
36. Construire la recherche de candidats officiels et l'approbation.
37. Intégrer la carte vidéo avec consentement existant.

### Finalisation

38. Vérifier performance, job planifié et caches cloisonnés.
39. Réaliser les audits confidentialité, sécurité et accessibilité.
40. Exécuter les revues Noche Live et corriger tout score inférieur à 8.
41. Déployer progressivement avec possibilité de désactiver guide, cercle et vidéo indépendamment.

## 25. Risques et décisions encore ouvertes

### À décider avant la Phase 1

- Qui peut approuver une révision et comment son identité est-elle enregistrée ?
- Le fond `fort contraste` doit-il suivre les préférences système ou être un choix explicite dans `Aa` ?
- Quel comportement exact adopter lorsqu'une traduction biblique change le découpage des versets ?

### À décider avant les Phases 2A et 2B

- Nombre de couleurs et tokens accessibles de la palette.
- Les associations couleur-intention sont-elles proposées par défaut ou choisies entièrement par le joueur ?
- Limites de tags, de carnets et de liens par personne.
- Règle définitive pour les sélections qui se recouvrent.
- Source approuvée pour les définitions dans chaque langue.
- Corpus et stratégie d'indexation pour la recherche d'expressions.
- Durée exacte de la fenêtre de restauration après suppression.

### À décider avant la Phase 3

- Seuil exact avant d'afficher un compteur de ward.
- Fenêtre du mouvement : sept jours glissants ou semaine calendaire locale.
- Le nombre exact est-il utile, ou une formulation par paliers est-elle plus protectrice ?
- Faut-il conserver la langue originale des messages uniquement ou proposer un filtre multilingue ?

### À décider avant la Phase 4

- Durée par défaut et durée maximale d'un scrutin ; le minimum de deux jours est acquis.
- Quorum minimal et éventuelle adaptation aux petites wards.
- Majorité requise et règle exacte d'égalité ; recommandation actuelle : l'égalité conserve le message.
- L'auteur du message et le proposant peuvent-ils voter ? La recommandation est oui, sans voix supplémentaire.
- La proposition crée-t-elle un vote implicite ? La recommandation est non.
- Le droit de vote reste-t-il actif lorsque le cercle passe en lecture seule ?
- Durée de conservation des messages censurés, propositions, suffrages, révisions et événements.
- Niveau de détail public de l'historique : recommandation actuelle, résultats agrégés et vote propre uniquement, jamais la liste nominative des votants.
- Limites et délai de reprise après des propositions répétées qui n'aboutissent pas.
- Conditions de fermeture temporaire d'un cercle.
- Traitement d'une erreur de politique ou de résolution après décision, sans créer un pouvoir individuel de réécriture.

### Risques majeurs

- Surcharge de la liseuse si les panneaux secondaires deviennent permanents.
- Faux sentiment d'autorité si un accueil éditorial non sourcé est affiché comme certain.
- Fuite inter-wards par identifiant direct, cache ou flux temps réel.
- Confusion entre note privée et publication sociale.
- Fuite inter-wards par la page de profil, un compteur total, un extrait mis en cache ou une pagination mal scopée.
- Profil transformé progressivement en réseau social global au détriment de la conversation rattachée au chapitre.
- Campagne coordonnée de censure ou vote de représailles dans une ward.
- Effet d'entraînement produit par les résultats visibles en temps réel, choix assumé qui exige une présentation strictement neutre.
- Harcèlement par propositions répétées contre la même personne.
- Faible anonymat des suffrages dans une petite ward malgré l'affichage agrégé.
- Vote stratégique de dernière minute ou transferts de ward pendant un scrutin.
- Job de résolution retardé, exécuté deux fois ou fondé sur des compteurs devenus incohérents.
- Conservation excessive de corps censurés et d'historiques nominatifs.
- Dépendance excessive à YouTube ou disparition des vidéos liées.
- Perte de surlignages pendant la migration.
- Préférences trop nombreuses qui transforment `Aa` en panneau complexe.
- Barre de sélection transformée en grille dense de commandes secondaires.
- Palette peu contrastée ou significations de couleurs incompréhensibles.
- Tags, titres de carnets ou requêtes personnelles exposés dans les logs.
- Liens devenus imprécis après une évolution du texte source.
- Définition lexicale perçue comme une interprétation doctrinale si sa source n'est pas claire.

Chaque risque possède un garde-fou dans ce plan et doit devenir un test ou une condition d'activation.

## 26. Définition de terminé

Une phase n'est terminée que si :

- son comportement principal est utilisable de bout en bout ;
- les états vides, chargement, erreur et absence sont traités ;
- les tests ciblés et la suite pertinente passent ;
- les quatre langues sont présentes et relues ;
- les viewports `390 × 844`, `768 × 1024` et `1440 × 900` sont contrôlés ;
- les données privées ne figurent ni dans les logs ni dans l'analytics ;
- les notes, tags, carnets, liens et requêtes restent strictement limités à leur propriétaire ;
- la barre contextuelle conserve quatre actions de premier niveau et relègue les outils secondaires dans `Plus` ;
- les requêtes et caches de ward ont des tests négatifs ;
- les publications du profil distinguent la vue propriétaire de la vue de ward sans exposer une ancienne communauté ;
- les propositions et suffrages sont isolés par ward, limités et entièrement auditables ;
- la durée minimale, le temps réel, l'idempotence du job et les cas de concurrence sont couverts par des tests ;
- aucun rôle de modérateur ni retrait individuel n'a été introduit ;
- le texte sacré reste accessible si guide, repères, recherche, définition, cercle ou vidéo échouent ;
- la revue Noche Live documentée dans `docs/AGENT_REVIEWS/` obtient au moins 8/10 dans chaque dimension applicable ;
- une fonctionnalité sociale ou éditoriale non approuvée reste désactivée par défaut.

La Liseuse 3.0 sera réussie si elle donne davantage envie de rester avec le texte, si elle permet à chacun de lire selon ses besoins, et si le sentiment de rejoindre un mouvement naît sans jamais sacrifier le calme, la confidentialité ou les frontières de la paroisse.
