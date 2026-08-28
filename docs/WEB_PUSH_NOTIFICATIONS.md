# Web Push — versets, défis et Noches Live

Statut : infrastructure déployée ; flow Noche Live en validation avant activation
Date : 2026-08-28  
Périmètre : PWA Noche Live, fichas persistantes, aventure Street et défis asynchrones

Le web et le worker Solid Queue sont déployés sur Render. Les essais sur appareils physiques restent une étape distincte ; voir [WEB_PUSH_DEVICE_TESTS.md](WEB_PUSH_DEVICE_TESTS.md).

## 1. Objectif

Permettre à un joueur qui l'a explicitement demandé de recevoir :

- un rendez-vous biblique régulier ouvrant le verset ou le passage concerné ;
- une invitation lorsqu'un autre joueur lui lance un défi ;
- le résultat d'un défi lorsque les deux joueurs ont terminé ;
- au maximum un rappel utile pour un défi encore sans réponse.
- deux rappels sobres pour une Noche Live programmée dans la paroisse choisie.

Le Push ne doit pas devenir un canal promotionnel. Chaque notification doit donner une raison immédiate de revenir dans l'aventure biblique ou vers une personne réelle.

La boucle cible est :

```text
anticipation → appui → ressource exacte → action → feedback → récompense → prochaine envie
```

## 2. Exigence absolue : ouvrir directement la destination

Un appui sur une notification ouvre automatiquement sa ressource, sans page d'accueil, menu ou écran de confirmation intermédiaire.

| Notification | Destination attendue |
|---|---|
| Verset | Passage exact, dans la langue de la notification |
| Lecture de la semaine | Semaine ou lecture exacte du parcours d'étude |
| Défi reçu | `/desafio/:token` du duel concerné |
| Résultat | État résolu du même duel |
| Rappel de défi | Défi encore actionnable, jamais un défi expiré |
| Noche Live | `/s/:session_code/name` de la soirée concernée |

Le service worker doit :

1. fermer la notification ;
2. valider que la destination appartient à l'origine Noche Live ;
3. chercher une fenêtre Noche Live existante ;
4. la naviguer vers la destination et lui donner le focus ;
5. sinon ouvrir directement la destination avec `clients.openWindow()` ;
6. utiliser `/` uniquement si la destination manque ou est invalide.

L'appui ouvre une ressource ; il ne réalise jamais silencieusement l'action métier. Ouvrir un défi ne signifie donc pas l'accepter automatiquement.

Sur un appareil partagé, la ressource s'ouvre immédiatement, mais Noche Live ne change jamais de ficha silencieusement. Si la ficha active n'est pas autorisée à agir, la page explique clairement qui a reçu le défi et propose le changement de ficha explicite.

### Critères d'acceptation du deep link

- Application fermée : la PWA s'ouvre directement sur la ressource.
- Application ouverte ailleurs : la fenêtre existante est réutilisée, naviguée et focalisée.
- Plusieurs fenêtres ouvertes : une fenêtre Noche Live est réutilisée sans ouvrir de doublon inutile.
- Destination localisée : la langue et la référence reçues sont conservées.
- Destination expirée : la page du défi affiche son état réel, sans erreur serveur.
- Destination absente, externe ou malformée : repli sûr vers `/`.
- Le comportement est vérifié sur Chrome Android, Chrome desktop, Safari macOS et une PWA installée sur iOS/iPadOS.

## 3. Contrat produit du MVP

### 3.1 Verset du jour

- Désactivé par défaut.
- Activé seulement après un choix explicite portant sur les versets et lectures.
- Fréquence initiale : quotidienne ou trois fois par semaine, choisie par le joueur.
- Maximum absolu : un rendez-vous biblique par jour et par personne.
- Heure définie dans le fuseau du joueur.
- Aucun envoi pendant la plage silencieuse.
- Texte court : une lumière, une référence et une invitation à ouvrir.
- La notification mène à un passage existant et vérifié, jamais à un texte biblique généré.
- La lecture peut prolonger une semaine d'étude publiée, mais ne doit pas créer artificiellement une obligation ou une culpabilité.

Boucle :

```text
une parole pour aujourd'hui
→ ouvrir le passage exact
→ lire dans son contexte
→ accomplir une petite action
→ voir sa progression
```

### 3.2 Défi reçu

- Désactivé par défaut tant que le joueur n'a pas choisi explicitement de recevoir ses défis.
- Envoyé uniquement pour un `StreetDuel` adressé à une `Person` identifiée.
- Envoyé immédiatement si la personne n'est pas déjà active dans Noche Live.
- Le Turbo Stream existant reste prioritaire lorsque la personne est en ligne.
- Aucun Push pour un défi anonyme encore partagé uniquement par lien.
- Le nom affiché est le nom public de la ficha, sans donnée supplémentaire.
- L'appui ouvre directement `/desafio/:token`.

Boucle :

```text
« Lucía te défie »
→ ouvrir l'arène
→ accepter
→ jouer
→ découvrir le résultat
→ revanche
```

### 3.3 Résultat et rappel

- Une notification de résultat lorsque le duel devient `resolved` et que le joueur n'est pas déjà présent.
- Au maximum un rappel pour un défi non traité.
- Le rappel est annulé si le duel est accepté, refusé, résolu ou expiré.
- Pas de relance quotidienne, pas de compte à rebours anxiogène.

### 3.4 Noche Live programmée

- Catégorie `Noches Live` désactivée par défaut et indépendante des versets et défis.
- Destinataires : fichas de la paroisse concernée ayant choisi cette catégorie sur un appareil abonné.
- Premier rappel la veille, si le consentement existait déjà au passage du coordinateur.
- Second rappel 15 minutes avant, y compris après une activation trop tardive pour le rappel de la veille.
- Aucun Push pendant une manche, une pause, une révélation ou la finale.
- Aucun message libre du présentateur et aucune relance « ton équipe t'attend » sans liste fiable de joueurs attendus.
- Un joueur déjà entré dans la session n'est plus notifié.
- Une soirée finie, commencée en avance ou déplacée hors de la fenêtre est revalidée puis annulée avant livraison.
- Le clic ouvre directement l'entrée de la session exacte : `/s/:session_code/name`.

La clé d'idempotence contient la soirée, son horaire et le type de rappel. Une soirée réellement reprogrammée peut donc produire les nouveaux rappels utiles sans dupliquer ceux de l'ancien horaire.

### 3.5 Hors MVP

- Messages libres envoyés par un présentateur ou une paroisse.
- Campagnes marketing et segmentation comportementale.
- Notifications de classement générales.
- Push pendant une manche Live.
- Versets ou exhortations générés automatiquement par IA.
- Abonnement anonyme sans ficha persistante.
- Pièces jointes riches, images distantes et actions multiples dans la notification.

## 4. Moment de permission et expérience joueur

### 4.1 Invariant : l'onboarding reste express

La demande Push n'appartient pas à l'onboarding. Le premier parcours reste :

```text
arriver → comprendre → jouer
```

Il n'ajoute aucune étape à :

- la première visite du hub ;
- la découverte ou le choix d'une paroisse ;
- la création, reconnaissance ou sélection d'une ficha ;
- le lancement du premier quiz ;
- l'entrée dans une partie Live ;
- l'acceptation urgente d'un défi déjà ouvert par deep link.

Créer une ficha ne déclenche pas immédiatement une demande. Un invité sans ficha ne voit aucune proposition Push : la création d'un profil doit rester motivée par la sauvegarde et le jeu, pas par une permission navigateur.

Le Push constitue un second rendez-vous après une valeur déjà vécue :

```text
vivre quelque chose
→ vouloir ne pas manquer la suite
→ choisir précisément laquelle
```

### 4.2 Déclencheurs contextuels

| Moment | Comportement |
|---|---|
| Première visite, choix de paroisse, création de ficha | Aucune proposition |
| Quiz Street générique terminé | Aucune proposition |
| Début, question ou cérémonie d'une partie Live | Aucune proposition |
| Carte d'une prochaine Noche Live de la paroisse active | Proposition `Noches Live`, seulement après la création de la ficha et hors action prioritaire |
| Premier défi adressé envoyé à une personne | Proposition `Défis` après le retour de l'action principale |
| Première ouverture volontaire de la boîte des défis | Proposition `Défis` si elle n'a jamais été traitée |
| Premier défi adressé terminé ou résultat consulté | Deuxième moment éligible seulement si la première proposition n'a pas été affichée |
| Première lecture ou unité d'étude réellement terminée | Proposition `Versets et lectures` |
| Ficha | Réglages toujours accessibles volontairement, sans attendre un déclencheur |

Un pack de quiz terminé n'est plus un déclencheur : il ne prouve ni l'intérêt pour les rendez-vous bibliques ni l'intérêt pour les alertes sociales.

Une proposition automatique exige toutes les conditions suivantes :

```text
ficha persistante active
+ contexte correspondant à la catégorie (`défi`, `lecture` ou `prochaine Noche`)
+ catégorie encore inactive
+ permission système non refusée
+ aucun snooze actif
+ aucune autre invitation ou cérémonie prioritaire à l'écran
+ aucune proposition Push déjà affichée dans cette session
```

### 4.3 Forme de l'invitation

L'invitation est un petit épilogue contextuel intégré à la surface concernée. Ce n'est pas :

- une étape de l'onboarding ;
- une modale au chargement ;
- un popup système sans explication ;
- une deuxième action dorée qui concurrence la récompense, `Suivant`, `Défier` ou `Accepter` ;
- un écran de réglages complet.

Elle apparaît après la résolution du moment principal, dans une carte ou une feuille courte avec une seule action dorée et un lien discret `Pas maintenant`.

Après un défi :

```text
NE MANQUE PAS SA RÉPONSE

Carmen peut te défier même quand
Noche Live est fermé.

[ Recevoir mes défis sur cet appareil ]

Pas maintenant
```

Après une lecture :

```text
UNE PAROLE POUR LA ROUTE

Reçois un nouveau passage
trois fois par semaine à 08:00.

[ Recevoir ces versets sur cet appareil ]

Changer la fréquence · Pas maintenant
```

À côté de la carte d'une prochaine Noche :

```text
LE DIRECT APPROCHE

Noche Live peut prévenir Lucía la veille,
puis 15 minutes avant la soirée.

[ Me prévenir pour cette Noche Live ]

Pas maintenant
```

La carte reprend la famille Celestial Light ou Dark du moment. Elle ne transforme pas la cérémonie en formulaire et ne masque pas l'artwork. Une seule catégorie est proposée à la fois.

### 4.4 Séquence de consentement

La séquence est :

```text
valeur vécue
→ invitation contextuelle Noche Live
→ CTA qui nomme le type, la fréquence éventuelle, la ficha et l'appareil
→ permission système, déclenchée par ce geste direct
→ création de la souscription
→ activation de ce type seulement
→ confirmation courte
→ retour immédiat à la destination courante
```

La permission système est uniquement l'autorisation technique donnée au navigateur. Elle ne vaut jamais consentement à recevoir toutes les catégories Noche Live. Une catégorie reste désactivée tant que le joueur ne l'a pas choisie séparément.

Si l'autorisation système est déjà accordée, le CTA explicite active seulement la catégorie choisie et enregistre ou répare la souscription sans afficher un nouveau prompt système.

Le CTA explicite et le prompt système forment deux confirmations différentes : le premier choisit le contenu ; le second autorise techniquement le canal. Si le prompt système est refusé, le choix de catégorie n'est pas marqué actif côté serveur.

### 4.5 Parcours iPhone et iPad

Sur iOS/iPadOS, Web Push exige une web app ajoutée à l'écran d'accueil et une demande déclenchée par une interaction directe. La PWA existante fournit déjà le manifeste et le guide d'installation. Référence : [WebKit — Web Push for Web Apps on iOS and iPadOS](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/).

Si la web app n'est pas installée, l'invitation contextuelle ne demande pas encore la permission :

```text
POUR GARDER LE LIEN

Ajoute d'abord Noche Live à l'écran d'accueil
pour recevoir tes défis sur cet iPhone.

[ Installer Noche Live ]

Pas maintenant
```

Après installation :

- ne pas enchaîner automatiquement installation et permission Push ;
- attendre le prochain moment pertinent ou une action volontaire dans la ficha ;
- ne jamais afficher l'invitation Push pendant que le guide d'installation est ouvert ;
- ne jamais afficher les deux invitations dans la même session ;
- conserver la catégorie d'intérêt pour pouvoir reprendre le bon contexte sans l'activer.

### 4.6 Anti-insistance

- Une seule catégorie peut être proposée par session.
- `Pas maintenant` masque cette catégorie sur cet appareil pendant 30 jours.
- Le joueur peut malgré tout l'activer immédiatement depuis la ficha.
- Une nouvelle valeur vécue pendant le snooze ne contourne pas le délai.
- Un refus du prompt système interdit toute nouvelle proposition automatique sur cet appareil.
- Après un refus système, seule la ficha explique comment réactiver depuis les réglages du système.
- Une catégorie déjà active n'est jamais reproposée.
- Une invitation déjà visible, un guide PWA, une cérémonie, un dialogue ou une action Live bloque la proposition.
- Aucun timer, badge rouge ou formulation culpabilisante ne pousse à accepter.

Le snooze est propre à la catégorie et au couple ficha/appareil. Dire `Pas maintenant` aux versets n'empêche donc pas une proposition ultérieure de défis ou de Noche Live, mais deux propositions ne peuvent pas apparaître dans la même session.

### 4.7 États UI

| État | Expérience |
|---|---|
| Non éligible : invité ou onboarding | Aucune proposition ; réglage absent tant qu'il n'y a pas de ficha |
| Non supporté | Explication courte dans la ficha, aucun CTA impossible |
| Installation requise sur iOS | Une action principale pour installer la PWA, sans permission Push enchaînée |
| Disponible, aucun type choisi | Choix séparé `Noches Live`, `Défis` ou `Versets`, sans catégorie précochée |
| Type choisi, permission inconnue | Une action dorée qui nomme précisément le type et la fréquence |
| Demande en cours | État d'attente non cliquable |
| Autorisé | Confirmation du type, de la ficha et de l'appareil concernés |
| Refusé | Aucune nouvelle sollicitation automatique ; aide depuis la ficha |
| Snooze actif | Invitation cachée jusqu'à la date prévue ; réglage volontaire disponible |
| Autorisé, aucun type actif | Canal techniquement disponible, mais aucun envoi |
| Type désactivé dans Noche Live | Réactivation explicite de ce type, sans nouveau prompt système |
| Abonnement expiré | Réparation proposée depuis la ficha |

### 4.8 Direction Noche Live

- Émotion recherchée : attention, proximité, curiosité et appartenance.
- Le réglage n'est pas un tableau de bord SaaS.
- Le joueur comprend l'action en moins de deux secondes.
- Une seule action dorée principale par état.
- Le composant fonctionne avec les tokens Celestial Light et Celestial Dark ; ce n'est pas un thème choisi par l'utilisateur.
- L'or reste une signature ou une action, jamais un empilement de titres dorés.
- Les cibles tactiles restent utilisables par Lucía comme par Abuela.
- Les animations respectent `prefers-reduced-motion`.

### 4.9 Préférences

L'écran distingue visuellement les deux niveaux :

```text
Cet appareil
Notifications autorisées par le système

Ce que Lucía veut recevoir
Rappels Noche Live        Désactivé
Défis entre joueurs       Désactivé
Versets et lectures       Désactivé
```

Les préférences vivent dans la ficha :

- `Versets et lectures` : activé/désactivé ;
- fréquence : quotidien ou trois fois par semaine ;
- heure locale ;
- `Défis entre joueurs` : activé/désactivé ;
- `Rappels Noche Live` : activé/désactivé ; rappel la veille et 15 minutes avant ;
- bouton `Désactiver sur cet appareil`.

Le MVP ne propose pas une grille de réglages complexe. Les règles initiales sont :

- aucune catégorie précochée ou activée par défaut ;
- choisir `Défis` n'active pas les versets ;
- choisir `Versets` n'active pas les défis ;
- choisir `Noches Live` n'active ni les défis ni les versets ;
- le choix `Versets` demande explicitement quotidien ou trois fois par semaine avant confirmation ;
- l'heure proposée est 08:00 locale, modifiable avant confirmation ;
- la plage silencieuse proposée est 21:00–08:00 ;
- une modification ultérieure est enregistrée immédiatement et confirmée sobrement ;
- désactiver la dernière catégorie suspend tous les envois, sans prétendre modifier la permission du système ;
- `Désactiver sur cet appareil` supprime la souscription de cet appareil, mais conserve les préférences de la ficha pour ses autres appareils.

### 4.10 CTA et consentement sans ambiguïté

Le libellé du CTA doit décrire l'effet réel. Sont interdits : `Activer`, `Continuer`, `Oui` ou `Autoriser` utilisés seuls.

Exemples de sens attendus, à localiser nativement :

```text
Défis :   « Recevoir mes prochains défis sur cet appareil »
Versets : « Recevoir un verset trois fois par semaine à 08:00 »
Noches :  « Me prévenir avant les prochaines Noches Live sur cet appareil »
Arrêt :   « Ne plus recevoir mes défis »
Appareil : « Désactiver les notifications sur cet appareil »
```

Le texte final est écrit et validé nativement en espagnol, portugais brésilien, français et anglais avant l'implémentation visuelle.

## 5. Identité et appareils partagés

Noche Live reconnaît une ficha grâce à `Person` et `PersonDevice`, sans compte ni mot de passe. Une souscription Push appartient à un navigateur et à une seule ficha active.

Règles :

- plusieurs appareils peuvent recevoir pour la même ficha ;
- un navigateur ne reçoit que pour une ficha à la fois ;
- l'activation affiche le prénom concerné ;
- activer le Push pour une autre ficha sur le même navigateur demande une confirmation explicite et réattribue la souscription ;
- changer de ficha dans l'interface ne réattribue pas automatiquement la souscription ;
- désactiver un appareil ne désactive pas les autres appareils de la personne ;
- fusionner deux fichas transfère les souscriptions sans dupliquer les endpoints.

Cette règle évite qu'une tablette familiale affiche les défis privés de plusieurs personnes sans qu'elles l'aient compris.

## 6. Architecture navigateur

### 6.1 Service worker

Étendre `app/views/pwa/service-worker.js` avec :

- événement `push` ;
- parsing défensif du payload ;
- `registration.showNotification()` ;
- événement `notificationclick` ;
- validation same-origin de la destination ;
- focus/navigation/ouverture directe ;
- événement `pushsubscriptionchange` lorsque disponible ;
- badge facultatif pour les défis non lus.

Payload minimal :

```json
{
  "title": "Noche Live",
  "body": "Lucía te défie dans Reyes y Profetas",
  "tag": "street-duel-842",
  "icon": "/icon-192.png",
  "badge": "/favicon-32.png",
  "data": {
    "path": "/desafio/abc123",
    "delivery_id": 151
  }
}
```

`path` est un chemin interne, jamais une URL fournie directement par le joueur.

### 6.2 Contrôleur Stimulus

Ajouter `push_subscription_controller.js` pour :

- détecter `serviceWorker`, `PushManager` et `Notification` par fonctionnalité ;
- attendre que le service worker soit prêt ;
- vérifier l'éligibilité contextuelle sans afficher quoi que ce soit pendant l'onboarding ;
- ne proposer qu'une catégorie par session ;
- respecter le snooze propre à la ficha, à la catégorie et à l'appareil ;
- distinguer PWA à installer, permission inconnue, permission accordée et permission refusée ;
- demander la permission après le CTA explicite ;
- appeler `pushManager.subscribe()` avec la clé publique VAPID ;
- transmettre la souscription, le fuseau IANA et la langue au serveur ;
- enregistrer `Pas maintenant`, l'activation ou le refus système ;
- refléter les états UI ;
- désabonner l'appareil ;
- réparer une souscription navigateur présente mais absente côté serveur.

Le fuseau provient de `Intl.DateTimeFormat().resolvedOptions().timeZone`. Le serveur valide sa présence dans `ActiveSupport::TimeZone`/TZInfo et utilise UTC si la valeur n'est pas exploitable.

## 7. Modèle de données

### 7.1 `web_push_subscriptions`

| Colonne | Rôle |
|---|---|
| `person_id` | Ficha destinataire |
| `device_token_digest` | Corrélation avec l'appareil sans recopier le cookie brut |
| `endpoint` | Endpoint Web Push chiffré au repos |
| `endpoint_digest` | Unicité et recherche sans exposer l'endpoint |
| `p256dh` | Clé publique de chiffrement, chiffrée au repos |
| `auth` | Secret d'authentification, chiffré au repos |
| `locale` | Langue de cet appareil |
| `time_zone` | Fuseau IANA |
| `user_agent_family` | Diagnostic minimal, sans chaîne complète si inutile |
| `last_success_at` | Dernière livraison réussie |
| `last_failure_at` | Dernier échec |
| `failure_count` | Nettoyage et diagnostic |
| `revoked_at` | Désactivation logique |

Contraintes :

- `endpoint_digest` unique ;
- une souscription active doit avoir une `Person` ;
- aucune clé ni endpoint dans `inspect`, logs ou messages d'erreur ;
- dépendance `Person` avec suppression des souscriptions lors de l'effacement de la ficha.

### 7.2 `notification_preferences`

Une ligne par personne :

- `verses_enabled`, `false` par défaut ;
- `verse_frequency` : `daily` ou `three_weekly` ;
- `verse_local_time` ;
- `verses_enabled_at` ;
- `challenges_enabled`, `false` par défaut ;
- `challenges_enabled_at` ;
- `quiet_hours_start` et `quiet_hours_end` ;
- `updated_at`.

Il n'existe pas de `consented_at` global qui pourrait laisser croire que tous les types sont acceptés. Les préférences métier et leur activation explicite appartiennent à la personne. La présence effective du canal appartient à chaque `WebPushSubscription`.

### 7.3 `notification_prompt_states`

Une ligne par `PersonDevice` et catégorie permet de ne pas harceler le joueur avant même qu'une souscription Push existe :

- `person_device_id` ;
- `category` : `verses` ou `challenges` ;
- `last_offered_at` ;
- `last_result` : `dismissed`, `selected`, `system_denied` ou `activated` ;
- `snoozed_until` ;
- `offer_context` : `challenge_sent`, `challenge_inbox`, `challenge_result`, `study_completed` ou `profile` ;
- `updated_at`.

Contraintes :

- unicité `person_device_id + category` ;
- aucun état créé pour un invité sans ficha ;
- `Pas maintenant` fixe `snoozed_until` à 30 jours ;
- `system_denied` bloque toutes les propositions automatiques sur l'appareil ;
- l'état navigateur réel reste l'autorité et est réconcilié lors d'une visite ;
- la suppression d'un `PersonDevice` supprime ses états de proposition.

### 7.4 `notification_deliveries`

Journal interne et idempotent :

- `web_push_subscription_id` ;
- `person_id` ;
- `kind` : `daily_verse`, `duel_invitation`, `duel_reminder`, `duel_result` ;
- `dedupe_key` unique ;
- `subject_type`/`subject_id` ;
- destination ;
- état : `queued`, `sent`, `failed`, `opened`, `cancelled` ;
- `scheduled_for`, `sent_at`, `opened_at` ;
- code d'erreur normalisé, jamais la réponse contenant les secrets.

Exemples de clés :

```text
daily-verse:person:42:2026-08-28
duel-invitation:duel:842:person:42
duel-reminder:duel:842:person:42
duel-result:duel:842:person:42
```

## 8. API HTTP

Routes envisagées :

```text
POST   /notifications/subscription
DELETE /notifications/subscription
PATCH  /notifications/preferences
PATCH  /notifications/prompt-state
POST   /notifications/deliveries/:id/open
```

Règles de contrôleur :

- ficha courante obligatoire ;
- cookie d'appareil et CSRF obligatoires ;
- paramètres strictement filtrés ;
- un service par cas d'usage ;
- aucune orchestration dans le contrôleur ;
- réponse JSON minimale pour Stimulus ;
- pas d'accès arbitraire à une souscription par identifiant fourni par le client.

Services :

```text
Notifications::Subscribe.call(person:, device_token:, subscription:, locale:, time_zone:)
Notifications::Unsubscribe.call(person:, device_token:, endpoint:)
Notifications::UpdatePreferences.call(person:, attributes:)
Notifications::RecordPrompt.call(person:, device_token:, category:, result:, context:)
Notifications::Deliver.call(delivery:)
Notifications::AcknowledgeOpen.call(delivery:, person:)
```

## 9. Jobs et déclencheurs

### 9.1 Envoi unitaire

`NotificationDeliveryJob` :

- recharge la livraison et la souscription ;
- annule si la préférence ou la souscription n'est plus active ;
- reconstruit le contenu depuis l'objet métier ;
- envoie avec VAPID ;
- marque `sent` après succès ;
- marque la souscription révoquée sur `404`/`410` ;
- réessaie les erreurs transitoires et `429` avec temporisation et jitter ;
- ne réessaie pas une payload invalide ;
- reste idempotent si le job est exécuté deux fois.

### 9.2 Défis

Le flux existant `Quizzes::ChallengeNotify` reste responsable du choix du canal :

- adversaire actif : Turbo Stream seulement ;
- adversaire absent et Push autorisé : création d'une livraison puis `perform_later` ;
- aucun adversaire nommé : aucun Push.

La résolution du duel crée les livraisons de résultat nécessaires. Un job différé ou un coordinateur crée le rappel uniquement si le duel est toujours actionnable.

### 9.3 Rendez-vous bibliques

Un coordinateur récurrent s'exécute toutes les quinze minutes :

1. sélectionne les personnes ayant une souscription active et les versets autorisés ;
2. convertit l'heure courante dans leur fuseau ;
3. vérifie fréquence et plage silencieuse ;
4. choisit le contenu éditorial du jour ;
5. crée la livraison avec une clé d'idempotence par date locale ;
6. met un job unitaire en file pour chaque souscription active.

Le coordinateur ne fait aucun appel Web Push lui-même et traite les personnes par lots.

## 10. Contenu biblique

Sources autorisées pour le MVP :

- semaine publiée de `StudyProgram`/`StudyUnit` ;
- références présentes dans les lectures et quiz éditoriaux ;
- passages résolus par `Scriptures::Reference` et `Scriptures::Read` ;
- petit catalogue YAML revu manuellement pour les jours sans semaine exploitable.

Chaque entrée éditoriale contient :

- identifiant stable ;
- référence canonique ;
- destination localisée ;
- titre et corps courts dans les quatre langues ;
- dates ou saison d'éligibilité ;
- thème émotionnel ;
- éventuelle unité d'étude associée.

Le texte biblique affiché doit venir de la source de lecture existante. L'IA peut aider un rédacteur hors production, mais ne sélectionne ni ne rédige dynamiquement la parole envoyée aux joueurs.

## 11. Langues

Toutes les chaînes sont disponibles en espagnol, portugais brésilien, français et anglais avant livraison.

- Espagnol : source de vérité, ton familial et `tú` pour un joueur.
- Portugais : brésilien naturel, `você`, `ala`, `equipe`.
- Français : `tu` pour la ficha individuelle, ponctuation française native.
- Anglais : chaleureux, jamais administratif ou télévisuel.
- `Noche Live`, les noms des personnes et les noms d'équipe ne sont pas traduits.

Les textes vivent dans les locales ou le catalogue éditorial, jamais dans un job, contrôleur ou service.

Exemples de sens à préserver, à faire valider nativement :

```text
es:    Lucía te desafía. ¿Entras en la arena?
pt-BR: Lucía desafiou você. Vai encarar?
fr:    Lucía te défie. Tu entres dans l'arène ?
en:    Lucía challenged you. Ready to play?
```

## 12. Infrastructure et Render

### 12.1 État actuel

- Rails 8.1 et Solid Queue sont déjà installés.
- La production utilise `config.active_job.queue_adapter = :solid_queue`.
- `bin/jobs` tourne dans le worker Render persistant `nochelive-jobs`.
- Web, worker et tables Solid Queue partagent PostgreSQL.
- `config/recurring.yml` planifie les coordinateurs dans ce worker.
- Le feature flag conserve la maîtrise de l'ouverture utilisateur.

Un redémarrage Puma ne perd donc plus une invitation ou un rendez-vous planifié.

### 12.2 Topologie déployée

- passer la production à `:solid_queue` ;
- connecter les tables Solid Queue au PostgreSQL Render ;
- déclarer un service Render `type: worker` exécutant `bundle exec bin/jobs` ;
- partager `DATABASE_URL`, `RAILS_MASTER_KEY` et les secrets VAPID ;
- ajouter le coordinateur dans `config/recurring.yml` ;
- garder les envois HTTP hors du processus Puma ;
- configurer un délai d'arrêt permettant aux petits lots en cours de finir proprement.

Solid Queue stocke la file dans PostgreSQL : aucun Redis supplémentaire n'est requis pour ce volume. Le même superviseur exécute les jobs immédiats et planifie les tâches récurrentes ; un service cron Render séparé n'est donc pas nécessaire pour le MVP. Le coordinateur des Noches passe toutes les cinq minutes dans ce même scheduler.

Topologie cible :

| Service Render | Présent dans le MVP | Rôle |
|---|---|---|
| `web` | Oui | Puma, requêtes Rails et UI |
| `worker` | Oui | `bin/jobs`, jobs immédiats, scheduler Solid Queue et tâches de `config/recurring.yml` |
| PostgreSQL | Oui | Données applicatives et file persistante |
| `cron` | Non | Inutile tant que Solid Queue planifie le coordinateur dans le worker |

Il n'existe donc pas un « worker » plus un « cron worker ». Il existe un seul service Render `worker` persistant. Son processus Solid Queue contient les workers de file et le scheduler récurrent. Les coordinateurs de versets (quinze minutes) et de Noches Live (cinq minutes) sont déclarés une seule fois dans `config/recurring.yml`.

Un service Render `type: cron` ne sera envisagé que si une tâche future doit être isolée de Solid Queue et s'exécuter comme une commande ponctuelle. Dans ce cas, elle remplacera la planification Solid Queue correspondante ; les deux mécanismes ne doivent jamais planifier le même envoi.

Référence : [Rails — Active Job Basics, Solid Queue et recurring tasks](https://guides.rubyonrails.org/active_job_basics.html).

### 12.3 Décision d'architecture

ADR-006 a été amendée par l'implémentation :

```text
Decision:
Les notifications utilisent Solid Queue persistant et un worker Render.
Le cache peut rester en mémoire ; les jobs de notification ne le peuvent pas.

Why:
Une invitation personnelle et un rendez-vous programmé doivent survivre aux
redémarrages et ne pas ralentir les requêtes web.
```

### 12.4 Secrets

```text
VAPID_PUBLIC_KEY
VAPID_PRIVATE_KEY
VAPID_SUBJECT
```

- La clé publique peut être envoyée au navigateur.
- La clé privée reste exclusivement dans les secrets Render/credentials.
- `VAPID_SUBJECT` est une URL HTTPS ou une adresse de contact valide.
- La rotation des clés exige de réabonner les navigateurs ; elle doit être planifiée, pas improvisée.

La gem Ruby `web-push` fournit l'envoi chiffré et VAPID : [pushpad/web-push](https://github.com/pushpad/web-push).

## 13. Fiabilité et règles d'envoi

- Déduplication en base avant mise en file.
- Payload reconstruite au moment du job afin de vérifier l'état réel.
- TTL court pour une invitation déjà vue ; TTL cohérent avec `expires_at` pour un défi.
- Aucun envoi après expiration.
- Une erreur permanente révoque la souscription.
- Les erreurs transitoires utilisent un nombre limité de tentatives.
- Un lot lent n'empêche pas les invitations de défi : files ou priorités séparées.
- Les jobs de défi ont priorité sur les rendez-vous éditoriaux.
- Un déploiement ne doit pas créer une deuxième livraison grâce aux clés d'idempotence.

Files proposées :

```text
notifications_transactional  # défis et résultats
notifications_editorial      # versets et lectures
maintenance                  # nettoyage
```

Les rappels Noche Live utilisent la file transactionnelle : ils ont une durée de vie courte et ne doivent jamais arriver après le début de la soirée.

## 14. Sécurité et confidentialité

- Consentement explicite, révocable et daté.
- Consentement enregistré séparément pour chaque catégorie ; aucune autorisation globale implicite.
- Catégories désactivables indépendamment.
- Endpoint et clés chiffrés au repos.
- Aucun endpoint, token de duel ou clé dans les logs.
- Payload de lock screen minimale.
- Pas de texte sensible déduit de l'activité privée.
- Destination interne créée par le serveur et validée same-origin par le service worker.
- Protection CSRF et ficha courante sur toutes les mutations.
- Rate limit sur souscription, réparation et ouverture.
- État de proposition limité à la catégorie, au contexte, au résultat et au snooze ; aucun historique comportemental détaillé.
- Effacement des souscriptions avec la ficha.
- Effacement des états de proposition avec le lien ficha/appareil.
- Nettoyage périodique des souscriptions révoquées et livraisons anciennes.
- Mise à jour de la politique de confidentialité : données enregistrées, finalité, durée, révocation et sous-traitants techniques du navigateur.

La notification peut être visible sur un écran verrouillé. Le corps doit donc rester compréhensible sans révéler un détail personnel ou spirituel que le joueur n'a pas choisi d'afficher.

## 15. Mesure produit et exploitation

Mesures first-party, sans outil publicitaire :

- invitation de permission affichée ;
- contexte de l'invitation : défi, lecture, prochaine Noche ou ficha ;
- `Pas maintenant`, snooze et refus système ;
- activation, refus et désactivation ;
- souscriptions actives ;
- livraisons réussies, temporaires et révoquées ;
- ouverture d'une notification ;
- ouverture directe réussie vers la destination ;
- défi ouvert puis accepté ;
- passage ouvert puis lecture/progression engagée ;
- notifications par personne et par semaine.

Garde-fous :

- taux d'erreur permanent inférieur à 2 % après nettoyage ;
- aucun doublon métier ;
- aucune personne au-delà de la fréquence choisie ;
- aucune proposition automatique pendant l'onboarding ou une session Live ;
- aucune seconde proposition Push dans la même session ;
- désactivation réalisable en moins de deux actions ;
- alerte si le worker ne traite plus la file ou si son retard dépasse quinze minutes.

Les ouvertures peuvent être enregistrées par le chemin de destination ou par un `delivery_id` opaque. Elles ne doivent pas bloquer l'ouverture de la ressource si le suivi échoue.

## 16. Tests

### 16.1 Modèles

- validations et associations des quatre nouvelles tables ;
- unicité de l'endpoint et de la clé de déduplication ;
- préférences et plages silencieuses ;
- état de proposition unique par ficha/appareil/catégorie ;
- snooze de 30 jours et blocage après refus système ;
- fusion et suppression de fichas ;
- fixtures pour chaque nouveau modèle.

### 16.2 Services

- souscription et réattribution explicite sur appareil partagé ;
- désabonnement d'un seul appareil ;
- aucune catégorie activée par un consentement générique ;
- activation d'un type sans activation de l'autre ;
- refus système sans préférence marquée active ;
- invité, création de ficha et quiz générique sans proposition Push ;
- déclencheur `Défis` seulement dans un contexte de défi ;
- déclencheur `Versets` seulement après une lecture ou unité terminée ;
- déclencheur `Noches Live` seulement depuis la carte d'une soirée future de la paroisse active ;
- une seule proposition par session ;
- `Pas maintenant` propre à la catégorie et à l'appareil ;
- contenu dans la bonne locale ;
- sélection du passage et de la date locale ;
- invitation seulement pour un adversaire identifié ;
- aucun Push si le joueur est déjà actif ;
- annulation d'un rappel devenu inutile ;
- idempotence de chaque type de livraison.

### 16.3 Jobs

- succès VAPID ;
- `404`/`410` révoque sans retry ;
- `429`/`5xx` réessaie ;
- préférence désactivée entre création et exécution ;
- duel expiré avant l'envoi ;
- exécution double sans notification double ;
- rappel Noche annulé si la session n'est plus au vestibule ou si le joueur a déjà rejoint ;
- horaire reprogrammé produisant une nouvelle clé sans doubler l'ancien rappel ;
- coordinateur autour d'un changement d'heure saisonnier.

### 16.4 Contrôleurs

- ficha et cookie d'appareil obligatoires ;
- CSRF ;
- paramètres invalides ;
- impossibilité de modifier la souscription d'une autre personne ;
- destination d'ouverture associée à la bonne livraison.

### 16.5 Service worker et système

- payload valide et payload absente ;
- URL externe rejetée ;
- application fermée ;
- application ouverte sur une autre page ;
- fenêtre déjà ouverte sur la destination ;
- destination localisée ;
- rappel Noche ouvrant directement `/s/:session_code/name` ;
- permission refusée ;
- iOS non installé : installation proposée sans prompt Push ;
- iOS installé : permission seulement lors d'un moment ultérieur ;
- guide d'installation et invitation Push jamais visibles ensemble ;
- aucune proposition pendant l'onboarding, une cérémonie prioritaire ou une partie Live ;
- navigation Turbo après ouverture.

### 16.6 Qualité Noche

- test mobile à une main ;
- cibles tactiles enfant/abuela ;
- contraste Celestial Light et Dark ;
- `prefers-reduced-motion` ;
- copie native `es`, `pt-BR`, `fr`, `en` ;
- review Conseil dans `docs/AGENT_REVIEWS/` avant livraison ;
- toutes les dimensions du Conseil à 8/10 minimum ;
- suite Minitest complète et couverture d'application maintenue à 90 % minimum.

## 17. Découpage recommandé

### Lot 0 — Contrat et ADR

- Valider les catégories, fréquences et heures proposées, sans aucune catégorie préactivée.
- Valider les CTA explicites et contextualisés dans les quatre langues.
- Valider la matrice des déclencheurs post-onboarding et les exclusions absolues.
- Valider le snooze de 30 jours par catégorie/appareil.
- Ajouter l'ADR amendant ADR-006.
- Définir le schéma du catalogue biblique éditorial.
- Écrire la review Conseil initiale.

Terminé quand le produit sait précisément pourquoi, quand et vers quoi chaque notification part.

### Lot 1 — Persistance et services de souscription

- Migrations, modèles, états de proposition, fixtures et tests.
- Services `Subscribe`, `Unsubscribe`, `UpdatePreferences`, `RecordPrompt`.
- Endpoints HTTP protégés.
- Secrets VAPID en environnement de développement et production.

Terminé quand une ficha peut activer et retirer proprement un navigateur.

### Lot 2 — Navigateur et ouverture directe

- Service worker `push` et `notificationclick`.
- Contrôleur Stimulus et états UI.
- Réglage à deux niveaux depuis la ficha : autorisation de l'appareil puis catégories de la personne.
- CTA contextualisés sans bouton générique d'activation.
- Cartes post-défi et post-lecture non bloquantes.
- `Pas maintenant`, limite d'une proposition par session et blocage après refus système.
- Parcours iOS installation puis activation lors d'un moment ultérieur.
- Tests du deep link sur les navigateurs cibles.

Terminé quand appuyer sur une notification de test ouvre directement sa ressource exacte.

### Lot 3 — Premier parcours réel : défi

- Intégration à `Quizzes::ChallengeNotify`.
- Invitation hors ligne.
- Résultat de duel.
- Un rappel maximum et annulation selon l'état.
- Mesure ouverture → acceptation.

Terminé quand deux fichas sur deux appareils accomplissent le parcours complet hors ligne → notification → duel → résultat.

### Lot 4 — Rendez-vous biblique

- Catalogue éditorial quatre langues.
- Sélection depuis la semaine d'étude.
- Coordinateur fuseaux/fréquences/plages silencieuses.
- Progression après lecture.
- Absence de répétitions et de doublons.

Terminé quand une semaine simulée livre la bonne référence, au bon jour et à la bonne heure locale.

### Lot 5 — Worker Render et observabilité

- Solid Queue persistant.
- Un seul service Render `worker` déclaré dans `render.yaml`, lancé avec `bin/jobs`.
- Scheduler Solid Queue chargé depuis `config/recurring.yml` dans ce worker.
- Aucun service Render `cron` pour les notifications du MVP.
- Déploiement et migrations de file.
- Nettoyage des endpoints expirés.
- Mesures, logs sûrs et alerte sur retard.
- Mise à jour confidentialité.

Terminé quand un redémarrage du web n'annule ni un défi en file ni un rendez-vous planifié.

### Lot 6 — Pilote et ouverture

1. Appareils internes : un iPhone installé, un Android et un ordinateur.
2. Appareil partagé avec deux fichas.
3. Petit groupe de cinq à dix joueurs pendant une semaine.
4. Une paroisse pendant une semaine supplémentaire.
5. Activation progressive du rendez-vous biblique après validation des défis.

Le Push reste derrière un feature flag jusqu'à la fin du pilote.

## 18. Ordre de priorité

1. Ouverture directe et sûre de la destination.
2. Consentement et désabonnement fiables.
3. Défi adressé à une personne réelle.
4. Persistance des jobs en production.
5. Rendez-vous biblique éditorial et localisé.
6. Rappel, badge et raffinements.

Les défis constituent le premier parcours de production : le domaine, les adversaires, les tokens et les états existent déjà. Ils valident toute la chaîne avec un événement humain et immédiatement compréhensible avant d'ajouter la planification éditoriale.

## 19. Définition de terminé

La fonctionnalité est terminée lorsque :

- [x] le Push est désactivé par défaut ;
- [x] l'onboarding, la création de ficha et le premier quiz restent sans demande Push ;
- [x] seules une action de défi, une lecture terminée ou la ficha peuvent rendre une proposition éligible ;
- [x] un invité sans ficha ne voit aucune proposition Push ;
- [x] la permission suit toujours une action explicite ;
- [x] aucune catégorie n'est précochée ou activée par un consentement générique ;
- [x] le CTA nomme le type, la fréquence éventuelle, la ficha et l'appareil concernés ;
- [x] un refus système ne marque aucune préférence comme active ;
- [x] `Pas maintenant` snooze la catégorie pendant 30 jours sur cet appareil ;
- [x] une seule catégorie est proposée par session et aucune invitation ne concurrence une cérémonie ou le Live ;
- [x] installation PWA et permission Push ne sont jamais enchaînées dans la même session ;
- [x] une souscription appartient clairement à une ficha et un appareil ;
- [x] versets et défis sont réglables séparément ;
- [x] chaque appui ouvre automatiquement la ressource exacte ;
- [x] aucune destination externe ne peut être injectée ;
- [x] les défis en ligne restent en Turbo et les absents reçoivent le Push ;
- [x] les notifications expirées ne partent pas ;
- [x] les doublons sont empêchés en base ;
- [x] les endpoints morts sont révoqués ;
- [x] les jobs survivent au redémarrage du web ;
- [x] un seul worker Render exécute jobs et scheduler Solid Queue, sans cron Render concurrent ;
- [x] les passages sont éditoriaux, vérifiés et localisés ;
- [x] la copie est native en `es`, `pt-BR`, `fr` et `en` ;
- [x] la politique de confidentialité décrit le nouveau traitement ;
- [x] les tests couvrent appareils partagés, fuseaux et deep links ;
- [x] la couverture reste à 90 % minimum ;
- [x] la review Conseil atteint 8/10 ou plus sur chaque dimension ;
- [ ] le pilote ne révèle aucun doublon, fuite de profil ou pression excessive.

## 20. Estimation

Ordre de grandeur : huit à douze jours de développement pour les lots 0 à 5, puis une à deux semaines de pilote progressif. Cette estimation inclut les états post-onboarding, le snooze par catégorie/appareil et le worker Solid Queue unique. Elle suppose que le catalogue initial reste petit et que Solid Queue utilise le PostgreSQL Render existant.
