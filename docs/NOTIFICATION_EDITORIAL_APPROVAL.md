# Validation éditoriale des notifications

Statut : **BLOQUÉ — aucun envoi réel autorisé**

Deux verrous indépendants protègent la production :

- `WEB_PUSH_ENABLED` autorise l’interface et la création d’un abonnement ;
- `WEB_PUSH_DELIVERY_ENABLED` autorise la création et l’envoi des messages.

Les deux restent à `false` sur le Blueprint de production. Le second ne devra passer à `true` qu’après validation de cette fiche, des quatre langues et du calendrier des versets.

## Messages actuellement codés — à valider ou réécrire

| Type | Titre français | Corps français | Destination au toucher |
|---|---|---|---|
| Passage du jour | Une lumière pour aujourd’hui | `%{référence} est ouvert pour toi.` | Passage exact dans les Écritures |
| Reprise d’une lecture | Ton chemin continue | `Reviens à %{titre}.` | Lecture en cours |
| Noche Live demain | Noche Live, c’est demain | `Rendez-vous à %{heure}. Appuie pour ouvrir l’entrée de ta soirée.` | Entrée de la Noche concernée |
| Noche Live bientôt | Noche Live commence bientôt | `Rendez-vous à %{heure}. Ton entrée est prête.` | Entrée de la Noche concernée |
| Invitation à un défi | Un défi t’attend | `%{joueur} te défie dans %{parcours}. Tu entres dans l’arène ?` | Défi exact |
| Rappel de défi | Ton rival t’attend encore | `Le défi de %{joueur} dans %{parcours} est toujours ouvert.` | Défi exact |
| Résultat de duel | Ton duel a son résultat | Victoire : `Tu as battu %{joueur} dans %{parcours}. Découvre le résultat.` | Résultat exact |
| Résultat de duel | Ton duel a son résultat | Terminé : `Le résultat contre %{joueur} dans %{parcours} est prêt.` | Résultat exact |
| Résultat de duel | Ton duel a son résultat | Égalité : `Égalité avec %{joueur} dans %{parcours}. L’arène appelle la revanche.` | Résultat exact |

Les versions espagnole, portugaise brésilienne et anglaise existent dans les locales, mais elles ne constituent pas une approbation. La validation doit porter sur le sens et le ton de chaque langue, pas seulement sur leur présence technique.

## Comment les versets sont choisis aujourd’hui

Le code actuel n’utilise ni IA, ni hasard, ni profil spirituel. Il prend le numéro du jour dans l’année et applique un modulo sur une liste fixe de sept références. Tous les joueurs reçoivent donc la même référence pour leur date locale :

1. Jean 3:16 — amour
2. Psaumes 23:1 — paix
3. Matthieu 11:28 — repos
4. Proverbes 3:5 — confiance
5. Moroni 10:4 — recherche
6. Ésaïe 41:10 — courage
7. Doctrine et Alliances 121:7 — espérance

Le rythme choisi par le joueur est ensuite appliqué :

- quotidien ; ou
- trois fois par semaine, actuellement lundi, mercredi et vendredi ;
- à l’heure locale choisie ;
- jamais pendant les heures calmes ;
- une seule livraison par personne et par date locale.

Cette rotation technique n’est **pas considérée comme une règle éditoriale validée**.

## Règle recommandée avant activation

Remplacer la rotation modulo par un calendrier éditorial explicite et fermé :

- une date de publication ;
- une référence canonique ;
- un thème ;
- un statut `approved` ;
- une validation des citations et destinations dans les quatre langues ;
- éventuellement un lien avec le parcours d’étude en cours, mais jamais une interprétation spirituelle automatique du joueur ;
- **aucun verset approuvé pour la date = aucun envoi**.

Cette règle permet de relire chaque passage à l’avance, d’éviter les répétitions involontaires et de garder une responsabilité humaine sur le contexte.

## Décisions requises

1. Valider ou réécrire chaque titre et corps de message.
2. Choisir la source éditoriale des passages : calendrier manuel recommandé, rotation fixe, ou parcours d’étude.
3. Valider le premier calendrier de passages et ses quatre citations localisées.
4. Décider si les rappels de défi sont autorisés, et après quel délai.
5. Signer explicitement l’activation de `WEB_PUSH_DELIVERY_ENABLED=true`.

Tant que ces cinq points ne sont pas clos, l’interface peut être testée localement mais aucun message de production ne doit être envoyé.
