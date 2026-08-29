# Liga — plan d’animation et de transition

Statut : implémenté  
Surface : `/liga`, synthèse et classement complet  
Intention : **aspiration → rivalité locale → action**

## Principes

- Le mouvement explique la hiérarchie avant de décorer l’écran.
- La première entrée dure au maximum 890 ms et ne se rejoue pas pendant la session.
- Une visite Turbo suivante reste calme : seule la transition entre surfaces accompagne le changement de contexte.
- Un changement de rang anime la position réelle de la personne, sans inventer de gain ou de score.
- Les entrées utilisent seulement `opacity`, `transform` et `filter`; aucune propriété de mise en page n’est animée.
- Aucun son n’est lancé à l’arrivée. Le son et le retour haptique restent réservés à l’action explicite d’envoyer un défi.

## Chorégraphie de la synthèse

| Temps | Élément | Mouvement | Sens produit |
|---:|---|---|---|
| 60–380 ms | Titre et contexte | Fondu + descente de 8 px vers la position finale | Entrer dans la Cour |
| 160–600 ms | Places 2 et 3 | Montée courte, légère remise en saturation | Lire le terrain concurrentiel |
| 250–710 ms | Place 1 | Montée plus ample avec dépassement de 2,5 % | Créer l’aspiration |
| 430–750 ms | Couronne et lauriers | Couronne qui se pose, lauriers qui s’ouvrent | Consacrer le leader |
| 470–790 ms | Carte de rivalité | Montée de 12 px + fondu | Ramener l’objectif à portée |
| 500–860 ms | CTA principal | Éclat unique sur l’or | Indiquer la prochaine action |
| 560–890 ms | Voisinage et défi | Apparition en trois temps | Ouvrir les actions secondaires |

L’ordre visuel du podium est volontairement **2 → 3 → 1** : les deux places latérales installent le cadre, puis la place centrale reçoit la révélation dominante.

## Classement complet — fenêtres de 100

- Le panneau, le sélecteur de portée et la recherche apparaissent par niveaux.
- Seules les huit premières lignes visibles sont révélées en cascade (30 ms entre lignes).
- Les 92 autres lignes restent immédiatement disponibles : pas de cascade de 100 éléments, pas de coût inutile, pas d’attente artificielle.
- Recherche et pagination utilisent la navigation Turbo existante. La transition de monde sort en 170 ms et entre en 300 ms.
- Le champ de recherche conserve son indicateur de chargement rotatif ; le résultat remplacé ne produit pas de mouvement décoratif supplémentaire.

## Changements de rang

Avant la mise en cache Turbo, la position et le rang des personnes rendues sont mémorisés. Au retour :

1. les personnes dont le rang a réellement changé sont identifiées ;
2. les lignes proches du viewport sont déplacées depuis leur ancienne position avec une transition FLIP de 480 ms ;
3. un halo or confirme le changement sans afficher de faux delta ;
4. l’état visuel est nettoyé à la fin de l’animation.

Un maximum de douze lignes est animé simultanément pour garder un défilement fluide sur les fenêtres de 100.

## Interactions

| Déclencheur | Réponse |
|---|---|
| Survol clavier/souris du podium | Levée courte du candidat et renforcement du médaillon |
| Pression | Compression à 98,5 % |
| Ligne défiable | Décalage horizontal de 3 px et voile or léger |
| CTA / liens directionnels | La flèche avance dans la direction de navigation |
| Focus clavier | Anneau or de 3 px, toujours visible |
| Invitation envoyée | Dialogue et feedback existants, puis fermeture après succès |

## Retour, répétition et accessibilité

- `sessionStorage[noche_liga_seen]` empêche de rejouer la cérémonie d’entrée dans le même onglet.
- `prefers-reduced-motion: reduce` retire la classe d’entrée, désactive animations et transitions, et conserve tous les états finaux visibles.
- Le changement de contenu ne dépend jamais du mouvement pour être compris.
- Les surfaces conservent leurs contrastes Celestial Light et les cibles tactiles existantes.

## Contrat de validation

- 390 × 844, 768 × 1024 et 1440 × 900 : aucun débordement horizontal.
- Première visite : titre, podium, rivalité et action ont une animation calculée.
- Visite suivante : aucune classe de cérémonie d’entrée.
- Réduction des animations : `animation-name: none` sur le titre et le podium.
- Vue complète : exactement 100 lignes rendues pour 1 000 joueurs.
- Console : aucune erreur sévère.
