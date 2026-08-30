Implémente intégralement le plan de refonte de la liseuse décrit dans `docs/SCRIPTURE_READER_3_0_PLAN.md` dans le dépôt NocheLive ouvert. Poursuis jusqu’à obtenir une expérience réellement utilisable, testée et inspectée ; ne t’arrête pas au scaffolding, aux migrations ou à une simple compilation.

Commence par lire entièrement le plan, les instructions du dépôt et les skills NocheLive applicables. Inspecte ensuite l’implémentation existante de La Parole, des Écritures, du profil, de l’identité par appareil, des wards, des jobs et des surfaces responsive. Préserve toutes les modifications concurrentes sans rapport avec cette refonte.

Décisions produit non négociables :

- La liseuse est une chambre de lecture plein écran, sans HUD joueur et sans dock global.
- Elle reste entièrement crème/ivoire, avec texte encre et signature or. Aucun fond, panneau ou état bleu dans la liseuse.
- L’illustration de chapitre est un paysage de montagnes monochrome or/ivoire avec lumière céleste, intégré à l’en-tête et au repère de défilement sans passer sous le corps du texte.
- Le texte reste grand et confortable. Le menu `Aa` règle au minimum taille, interligne, largeur et police ; les préférences sont persistées et réappliquées.
- La carte « Pour accueillir ce chapitre » contient seulement une invitation courte, un résumé bref et éventuellement un thème. Elle ne contient aucun lien vers un contexte et n’ouvre aucun panneau historique détaillé.
- Après le dernier verset, afficher obligatoirement `Origine du texte`, la traduction ou le corpus disponible et un lien explicite vers la page officielle correspondante de l’Église de Jésus-Christ des Saints des Derniers Jours. Ce bloc précède vidéos et prolongements facultatifs.
- Les trois destinations locales sont `Lire`, `Mes repères` et `Le cercle`.
- Le cercle est strictement scopé sur `current_street_person.ward`. Un paramètre client, un cookie de navigation ou un `ward_code` ne peut jamais élargir l’accès.
- Chaque message principal peut ouvrir un fil. La profondeur visible maximale est de un : les réponses à une réponse restent dans le fil racine et affichent `À Nom`, sans indentation supplémentaire. Conserver néanmoins le parent exact en base.
- Chaque réflexion, question ou réponse est limitée à 500 caractères par validation ActiveRecord et contrainte PostgreSQL. Aucun tronquage silencieux.
- L’auteur peut modifier et supprimer ses propres publications selon le plan. Les révisions et pierres tombales nécessaires restent conservées.
- Aucun rôle de modérateur. Tout membre éligible de la ward peut proposer une censure. Pendant le vote, le message ciblé reste lisible dans une carte de scrutin réservée à la ward actuelle ; les résultats Oui/Non sont visibles en temps réel. Après une censure, son corps n’est plus rendu. Le vote dure au moins deux jours et sa résolution est effectuée par un job idempotent. Tout l’historique est conservé.
- La page de profil liste les publications autorisées du joueur selon les scopes propriétaire/ward définis dans le plan.
- Les vidéos sont uniquement des associations éditorialement approuvées provenant des chaînes officielles configurées, avec consentement préalable et `youtube-nocookie`.

Assets et direction artistique :

- Tu es responsable de générer toi-même tous les assets manquants : illustration montagne or/ivoire, icônes, états graphiques et éventuelles variantes responsive. Ne demande pas au propriétaire de les fournir et n’utilise pas d’emoji ou de placeholder comme résultat final.
- Utilise la génération d’images lorsque l’asset doit être raster ; utilise des pictogrammes/SVG de production lorsqu’une icône vectorielle est plus appropriée.
- Range les fichiers dans l’arborescence média NocheLive, ajoute les entrées de manifest nécessaires, produis les dérivés responsive attendus et vérifie les crops réels.
- La lecture longue justifie une surface papier opaque. Évite le dashboard SaaS et les accumulations de cartes ou de verre.

Tâche de démonstration obligatoire :

- Crée `bin/rails noche:scripture_circle_demo PERSON_ID=<id>` avec repli `NAME='<nom exact>'`.
- La tâche ne crée pas un nouveau compte pour le propriétaire : elle retrouve son `Person` existant et utilise sa ward actuelle. Elle échoue clairement si le profil est introuvable ou sans ward, et refuse toute exécution en production.
- Elle est idempotente et ne supprime ni ne modifie les données réelles hors de ses propres fixtures identifiables. Elle ne change jamais la ward du profil ciblé.
- Elle crée plusieurs profils de démonstration dans cette même ward et un fil Psaume 52 contenant au minimum : deux messages ordinaires, une question, deux réponses dans un fil, une réponse adressée à une autre réponse mais affichée au même niveau, un message modifié, une pierre tombale après suppression, un vote de censure ouvert avec suffrages Oui/Non et résultats visibles, un vote déjà résolu, ainsi que les révisions et événements d’historique correspondants.
- Elle crée aussi les lectures/repères minimaux nécessaires pour rendre crédibles le mouvement de lecture et le profil.
- À la fin, elle imprime le profil ciblé, sa ward, les quantités créées ou réutilisées et les URLs exactes à ouvrir pour Psaume 52, Le cercle et `Publications dans Le cercle` sur le profil.
- Ajoute des tests de tâche ou de service couvrant idempotence, blocage production, profil sans ward, absence de fuite inter-ward et conservation des données non démo.

Méthode de livraison :

1. Découpe le travail en phases sûres suivant le plan, mais continue automatiquement entre les phases tant qu’aucune autorisation nouvelle n’est nécessaire.
2. Implémente migrations, modèles, validations, contraintes, policies/services, contrôleurs, routes, vues, composants, Stimulus, jobs, traductions françaises/espagnoles/portugaises/anglaises, tâche de seed et instrumentation autorisée.
3. Écris les tests de modèles, services, contrôleurs, jobs, sécurité inter-ward, profil, seed et système. Teste notamment les accès directs forgés, les transferts de ward, les doubles votes, les résolutions concurrentes et les corps dépassant 500 caractères.
4. Lance les tests pertinents puis la suite proportionnée au risque. Corrige toutes les régressions dans le périmètre.
5. Exécute la tâche de démonstration sur un profil local disponible sans modifier sa ward.
6. Inspecte personnellement l’interface réelle à 390 × 844, 768 × 1024 et 1440 × 900, avec contenu long, fil ouvert, vote en cours, résultats en direct, préférences `Aa`, fin de chapitre et provenance officielle. Vérifie clavier, focus, lecteurs d’écran, reduced motion, chargement, vide, erreur et refus d’accès.
7. Corrige tout débordement, texte trop petit, cible inférieure à 44 px, état illisible ou console non propre. Ne qualifie pas le résultat de prêt pour la production si une approbation éditoriale manque ; maintiens alors les contenus concernés fail-closed derrière les drapeaux prévus.
8. Termine par un compte rendu précis : fichiers majeurs, migrations, commande de seed, URLs de démonstration, assets générés, tests et résultats, viewports inspectés, état de la console, approbations éditoriales manquantes et risques résiduels.

Ne déploie pas et ne publie pas de contenu éditorial non approuvé. Ne crée aucun pouvoir individuel de modération et ne remplace jamais les contrôles d’accès serveur par un simple masquage d’interface.

## CONTRAT DE FINITION ET DE PERSISTANCE — INSTRUCTION PRIORITAIRE

Ne me rends pas la main après une première implémentation fonctionnelle. Une fonctionnalité qui fonctionne techniquement mais dont l’expérience reste moyenne, incohérente ou incomplète n’est pas terminée.

Tu peux communiquer de courtes mises à jour pendant le travail, mais tu ne dois produire aucune réponse finale tant que la liseuse n’a pas atteint un niveau de finition que tu jugerais réellement prêt à être présenté et utilisé.

Après chaque version, exécute obligatoirement une nouvelle boucle autonome :

1. Lance l’application avec les données de démonstration.
2. Ouvre la liseuse dans un véritable navigateur.
3. Inspecte chaque écran en desktop et en mobile.
4. Parcours toutes les interactions comme un utilisateur réel.
5. Recherche activement les défauts fonctionnels, visuels et éditoriaux.
6. Établis une liste précise des défauts observés.
7. Corrige-les.
8. Relance les tests et vérifie les régressions.
9. Reprends de nouvelles captures.
10. Recommence la boucle tant qu’un défaut significatif demeure.

Examine notamment :

- la lisibilité prolongée du texte sacré ;
- la taille, l’interlignage et la longueur des lignes ;
- la mémorisation des préférences ;
- la hiérarchie entre la Parole, les repères et le cercle ;
- la fidélité au layout et à l’identité Noche Live ;
- la cohérence crème, ivoire, encre et or ;
- la discrétion de l’illustration ;
- les alignements, espacements et rythmes verticaux ;
- le responsive à différentes largeurs, pas uniquement deux captures ;
- les états vides, longs, chargement, erreur et permissions refusées ;
- les messages proches de 500 caractères ;
- les conversations avec plusieurs réponses ;
- les contenus modifiés ou supprimés ;
- les votes ouverts, serrés, terminés ou sans participation ;
- l’actualisation en temps réel des résultats ;
- l’isolation stricte entre wards ;
- le profil et l’historique des publications ;
- la navigation clavier, le focus, les zones tactiles et les contrastes ;
- l’absence de débordement, texte tronqué, saut de layout ou contrôle factice.

N’utilise pas « conforme au mockup » comme unique critère. Le mockup est une direction : améliore-le lorsque l’usage réel révèle une solution plus lisible ou plus élégante, sans violer les décisions produit validées.

Ne laisse aucun bouton inactif, faux résultat, asset provisoire, TODO, écran à moitié traité ou détail manifestement inférieur au reste de l’expérience.

Avant de conclure, effectue une dernière revue contradictoire en te demandant :

- Qu’est-ce qui donne encore l’impression d’un prototype ?
- Qu’est-ce qui pourrait fatiguer une personne lisant un long chapitre ?
- Qu’est-ce qui paraît étranger à Noche Live ?
- Qu’est-ce qui devient confus avec beaucoup de messages ?
- Qu’est-ce qui pourrait casser avec des données réelles ?
- Qu’est-ce qu’un utilisateur ne comprendrait pas sans explication ?
- Qu’est-ce qu’un excellent designer, développeur Rails ou testeur refuserait encore ?

Corrige toutes les réponses concrètes à ces questions, puis refais une vérification complète.

Tu ne peux conclure que lorsque :

- aucun défaut fonctionnel connu ne reste ouvert ;
- aucun défaut visuel significatif observé ne reste sans correction ;
- tous les parcours critiques ont été essayés avec les données de seed ;
- les tests pertinents passent ;
- les consoles navigateur et serveur sont propres ;
- les vues desktop et mobile paraissent intentionnelles et abouties ;
- l’expérience supporte des données courtes, longues, vides et nombreuses ;
- tu peux expliquer avec des preuves ce qui a été vérifié.

Ne me sollicite pas pour les décisions ordinaires de conception ou d’implémentation : prends une décision cohérente, implémente-la et vérifie-la. Demande mon intervention uniquement en cas de blocage réel exigeant un secret, une autorisation externe, une opération irréversible ou un choix produit qui changerait matériellement le périmètre.

L’épuisement du temps, la longueur du travail ou l’existence d’une première version fonctionnelle ne sont pas des critères d’arrêt. Continue à inspecter, corriger et polir avant de revenir vers moi.
