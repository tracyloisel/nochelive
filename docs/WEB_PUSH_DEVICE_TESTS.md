# Web Push — recette appareils et ouverture progressive

Statut : infrastructure déployée ; recette physique et événement pilote à exécuter
Feature flag initial : `WEB_PUSH_ENABLED=false`

## Avant le pilote

- [x] Déployer la migration et le service `nochelive-jobs` depuis `render.yaml`.
- [x] Renseigner les mêmes `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY` et `VAPID_SUBJECT` sur le web et le worker.
- [ ] Vérifier que la clé privée n'apparaît ni dans les logs, ni dans le navigateur, ni dans une capture.
- [x] Confirmer qu'il existe un seul scheduler : Solid Queue dans le worker, sans service Render cron.
- [x] Observer `/up`, le démarrage du worker et le chargement de `config/recurring.yml`.
- [ ] Activer `WEB_PUSH_ENABLED=true` sur web et worker uniquement pour les appareils internes.

## Matrice minimale

| Appareil | Installation | Permission | Défi fermé → appui | Noche → entrée exacte | App ouverte ailleurs | Verset localisé | Désabonnement |
|---|---|---|---|---|---|---|---|
| iPhone Safari, PWA écran d'accueil | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| iPad Safari, PWA écran d'accueil | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Chrome Android | N/A | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Chrome desktop | N/A | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Safari macOS | N/A | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

## Parcours iPhone/iPad

1. Ouvrir un moment contextuel sans PWA installée.
2. Vérifier que seule l'installation est proposée et que le prompt Push système ne s'ouvre pas.
3. Ajouter Noche Live à l'écran d'accueil puis fermer l'app.
4. Rouvrir la PWA : aucune permission Push ne doit être demandée automatiquement.
5. Vivre un nouveau moment pertinent ou ouvrir volontairement la ficha.
6. Choisir une catégorie précise ; vérifier que le prompt système suit ce geste direct.
7. Refuser sur un second appareil : aucune catégorie ne doit devenir active et aucune nouvelle relance automatique ne doit apparaître.

## Deep links à vérifier

Pour chaque ligne, tester app fermée, app ouverte sur une autre page et plusieurs fenêtres quand le système le permet.

- [ ] Invitation : appui → `/desafio/:token` exact, sans passage par `/`.
- [ ] Résultat : appui → même duel résolu.
- [ ] Rappel : appui → duel encore actionnable ; aucun envoi après expiration.
- [ ] Verset : appui → passage exact dans la langue de la notification.
- [ ] Noche la veille : appui → `/s/:session_code/name` de la bonne soirée.
- [ ] Noche 15 minutes avant : même entrée exacte, jamais le hub générique.
- [ ] Destination invalide ou externe injectée en environnement de test → repli `/`.
- [ ] Ficha différente active sur tablette partagée → aucun changement silencieux de ficha.
- [ ] Fenêtre exacte déjà ouverte → focus sans doublon.
- [ ] Fenêtre Noche Live ouverte ailleurs → navigation puis focus.

## Consentement et appareil partagé

- [ ] Défis seuls : aucun verset reçu.
- [ ] Versets seuls : aucun défi reçu.
- [ ] Noches seules : aucun verset ni défi reçu.
- [ ] Changer fréquence/heure : libellé puis envoi suivant cohérents.
- [ ] `Pas maintenant` : catégorie masquée trente jours sur cette ficha et cet appareil.
- [ ] Un refus système bloque toutes les propositions automatiques sur l'appareil.
- [ ] Réattribuer un navigateur à une autre ficha exige la confirmation nommée.
- [ ] Désactiver une catégorie conserve l'autre.
- [ ] Désactiver l'appareil supprime son abonnement et conserve les préférences pour les autres appareils.
- [ ] Fusionner deux fichas ne duplique aucun endpoint.

## Fiabilité et exploitation

- [ ] Deux déclenchements du même événement créent une seule `NotificationDelivery`.
- [ ] Un joueur déjà entré dans la session ne reçoit pas le rappel de 15 minutes.
- [ ] Aucun Push ne part après le passage de la session à `playing`, `paused` ou `finished`.
- [ ] Un redémarrage du web ne perd pas les jobs déjà persistés.
- [ ] Un arrêt `SIGTERM` du worker respecte le délai de 60 secondes.
- [ ] Une réponse 404/410 révoque l'endpoint ; 429/5xx déclenche les tentatives bornées.
- [ ] Les invitations sont traitées avant la file éditoriale sous charge.
- [ ] Le coordinateur respecte Europe/Madrid, un fuseau américain et un changement DST réel.
- [ ] Endpoints révoqués supprimés après 30 jours ; journaux supprimés après 90 jours.
- [ ] Alerte Render configurée sur worker indisponible ou retard de file supérieur à quinze minutes.

## Ouverture progressive

1. [ ] Appareils internes pendant 48 heures.
2. [ ] Cinq à dix joueurs, défis uniquement, pendant une semaine.
3. [ ] Une paroisse, défis uniquement, pendant une semaine.
4. [ ] Activer les rendez-vous bibliques pour le même petit groupe.
5. [ ] Revoir doublons, taux de refus, ouvertures, acceptations et désabonnements.
6. [ ] Élargir seulement si aucune fuite de ficha, pression excessive ou régression de deep link n'est constatée.

En cas d'incident, remettre `WEB_PUSH_ENABLED=false` sur le web et le worker. Ce coupe toute création et tout envoi sans supprimer les préférences, afin de permettre une reprise contrôlée.
