# Parcours Iglesia — plan de transition et d’animation

Le parcours forme un voyage continu : **seuil → accueil → foi → service → dimanche**. Le HUD joueur et le dock global restent identiques au hub ; **Église** demeure le repère or pendant tout le parcours.

## `/iglesia` — Le seuil

- Émotion : invitation, curiosité, sécurité.
- Entrée : décor en fondu ; titre monte de 18 px en 600 ms ; les quatre portes suivent à 260 ms.
- Idle : trois poussières d’or lentes dans la profondeur, sans détourner du choix.
- Action : les portes réagissent immédiatement au toucher ; la destination conserve la famille visuelle nuit/ivoire/or.
- Sortie : Turbo remplace la scène ; le dock ne change pas de géométrie.

## `/iglesia/misioneros` — Être accueilli

- Émotion : quelqu’un t’attend, sans pression.
- Entrée : le bandeau de chapitre est déjà lisible ; le titre et la carte montent ensuite en 550 ms.
- Idle : mouvement atmosphérique très lent, concentré autour de la lumière de la porte.
- Action : un seul CTA or, « Demander une visite » ; le reste reste narratif.
- Sortie externe : ouverture dans un nouvel onglet, le parcours Noche reste intact.

## `/iglesia/creencias` — Traverser les arches

- Émotion : contemplation puis compréhension.
- Entrée : héros plein écran, texte au dernier tiers ; l’image guide le regard vers l’horizon.
- Scroll : passage naturel du Celestial Dark du héros aux cartes ivoire ; chaque croyance devient un chapitre lisible.
- FAQ : révélation native par accordéon, sans animation spectaculaire afin de privilégier la confiance.
- Retour : le dock persistant conserve « Croyances » en or même dans la partie longue.

## `/iglesia/mision` — Aller deux par deux

- Émotion : mouvement, service, compagnonnage.
- Entrée : la perspective du chemin porte le titre ; carte de récit en verre sombre.
- Idle : particules ascendantes discrètes, comme de la lumière après la pluie.
- Action : le CTA vers la rencontre reprend le même verbe que le premier chapitre.

## `/iglesia/adorar` — Une place t’attend

- Émotion : chaleur familiale, paix du dimanche.
- Entrée : la nef simple apparaît avant le panneau de texte ; le CTA or conclut la scène.
- Idle : aucune agitation de foule ; seulement la respiration lumineuse commune au parcours.
- Action : « Trouver une chapelle » est l’unique action primaire.

## Règles communes

- Toutes les animations respectent `prefers-reduced-motion` et deviennent instantanées.
- Pas d’animation en boucle sur le texte ni le CTA ; seules trois particules décoratives bougent lentement.
- Le HUD conserve l’identité, le rang, les couronnes, la série et le menu du joueur.
- Le dock global reste fixe : Accueil, Aventure, Live, Église, Profil. La navigation interne passe par les portes du décor.
- Les titres restent crème sur les décors ; l’or est réservé au métal, au repère actif et au CTA.
