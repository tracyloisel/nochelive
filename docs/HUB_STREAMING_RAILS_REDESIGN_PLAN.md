# Hub Noche Live — séquence éditoriale

Statut : implémentation locale, non déployée  
Date : 30 août 2026  
Périmètre : la Home joueur `/` et `#street_world`

## Décision

Le Hub est une entrée dans l’aventure, pas un catalogue ni un dashboard. En deux secondes, il doit répondre à quatre questions : qui suis-je, où en suis-je, que puis-je faire maintenant, et que se passe-t-il dans ma rama.

Un seul carrousel horizontal subsiste : `Continuer l’aventure`. Il porte l’action `JOUER`. Toute la suite est une séquence verticale lisible, dont chaque élément a une priorité et une destination claire.

Le HUD existant est hors périmètre de cette refonte.

## Ordre canonique

1. `Continuer l’aventure` — le héros et son carrousel précédent / courant / suivant.
2. `Prochaine Noche Live` — une seule carte pleine largeur.
3. `À faire maintenant` — une pile de une ou deux actions personnelles réelles.
4. `Installer Noche Live` — utilité compacte et conditionnelle.
5. `À la rama` — une courte pile d’événements réels et du Cercle de la rama.

Les contenus qui ne répondent pas à une action immédiate ne sont pas répétés ici :

- l’avancement global et la carte du monde vivent dans `/mapa` ;
- les défis vivent dans `/desafios` et ne remontent que s’ils constituent une des deux actions immédiates ;
- les vidéos officielles vivent dans `/iglesia/videos` ;
- le programme complet Viens et suis-moi vit dans `/parole/semaines`.

## Architecture rendue

`app/views/street_hub/index.html.erb` rend exactement cette suite :

```text
desktop_navigation
hero
live
now_cards (si une action réelle existe)
install (seulement si installable)
rama_block (seulement si un contenu réel existe)
```

Les vues, contrôleurs Stimulus, services et règles CSS de l’ancien dashboard et de ses rails ne font pas partie de cette architecture. Aucun alias historique ne doit rester pour le héros ou son CTA.

## Le héros

Le héros est la seule expérience de carrousel du Hub.

- L’artwork reste le sujet visuel ; le texte est protégé par un scrim local et jamais par un voile global.
- `JOUER` est la seule CTA dorée principale. Son API est `.hub-play` ; aucun ancien bouton ou alias ne doit coexister.
- Les points de pagination commandent le voyage, sans devenir des story ticks.
- Sur mobile, le héros devient un tableau pleine largeur, non une tuile posée dans une page.
- Sur tablette et desktop, le même markup s’élargit ; les changements sont uniquement des tokens et de la composition CSS.
- L’image courante est l’unique image LCP prioritaire. Les illustrations des autres diapositives sont différées.

Le voyage utilise `Hubs::Screen#voyage`, et le héros `Hubs::Screen#hero`. Les trois diapositives ne créent aucune donnée supplémentaire.

## Prochaine Noche Live

La Noche Live est une carte pleine largeur immédiatement après le héros. Elle provient de `Hubs::Screen#live` et ne doit jamais être dupliquée dans `À la rama`.

- `playing` propose de rejoindre ;
- `imminent` peut afficher un compte à rebours réel ;
- une soirée future montre son programme ;
- `none` est honnête et n’invente pas de date ;
- `ward_missing` explique l’action utile : choisir une rama.

Les transitions de compte à rebours restent courtes, GPU-friendly et désactivables avec `prefers-reduced-motion`.

## À faire maintenant

Cette section est une pile verticale de zéro à deux cartes, jamais un rail.

Les cartes sont construites par `Hubs::NowCards`, avec cet ordre :

1. défi qui demande une réponse ;
2. défi actif ;
3. chapitre recommandé par le quiz ;
4. lecture de la semaine.

Chaque carte est une seule cible interactive. Elle n’a ni bouton imbriqué ni donnée inventée.

### Lecture recommandée

`Hubs::ReadingCards` reçoit les suggestions de `Quizzes::ReadingSuggestions`. Une question et une autre question qui renvoient vers le même `study` donnent une seule carte. Chaque chapitre distinct reste une carte distincte, qui ouvre sa destination réelle au `cite` ciblé.

Le statut est issu de `ScriptureReadingProgress` :

- `À lire` lorsqu’aucune progression reprenable n’existe ;
- `En cours · N %` lorsqu’une progression réelle et reprenable existe ;
- `Lu` seulement lorsque `completed_at` est présent.

Une ouverture accidentelle ne crée pas un faux état `En cours`. La barre, l’icône et le libellé affichent la même information. Les textes existent en français, anglais, espagnol et portugais brésilien.

### Programme Viens et suis-moi

Le programme de la semaine reste accessible par le lien secondaire de `À faire maintenant`. Il ne redevient pas une grande carte qui mélange plusieurs chapitres. La destination canonique est `study_unit_path(week)` puis `/parole/semaines`.

## Installer Noche Live

La tuile PWA est conservée après les actions personnelles et avant la rama.

- Elle apparaît uniquement si le navigateur peut réellement installer l’application et si le joueur ne l’a pas déjà installée ou refusée.
- Elle est dismissible et respecte cet état.
- Elle réutilise le flux existant `beforeinstallprompt` ou l’aide iOS honnête.
- Elle est pleine largeur, compacte et ne masque jamais le dock mobile.

Elle n’est ni un événement, ni une carte éditoriale, ni une seconde CTA `JOUER`.

## À la rama

`À la rama` n’est pas un rail : c’est une courte pile verticale de cartes, omise sans contenu réel.

Elle agrège uniquement :

- les `WardEvent` publiés, approuvés, non expirés et correctement scopés à la paroisse du joueur ;
- la carte du Cercle de la rama lorsque sa découverte est réelle.

La Noche Live n’y est jamais dupliquée. Les annulations futures restent visibles, honnêtement non cliquables avec leur motif. Les contenus fictifs des mockups ne doivent pas devenir des seeds de production.

Les types autorisés de `WardEvent` sont : collecte de vêtements, de jouets, de livres et fournitures scolaires, collecte alimentaire, activité sportive, musicale ou artistique. Le workflow reste `draft → published → cancelled` avec audit et approbation explicites.

## Thème et direction artistique

Le thème dépend du manifeste de l’artwork : `Celestial Light` ou `Celestial Dark`. Il n’existe pas de toggle utilisateur et aucune Home parallèle.

- Les couleurs, surfaces, bordures, ombres et contrastes utilisent des tokens sémantiques.
- L’or est réservé à la progression, aux récompenses et à `JOUER`.
- La lumière est locale : scrim, verre Noche et contraste au voisinage du texte ; jamais un voile intégral sur l’illustration.
- Light conserve une scène lumineuse et des panneaux nacrés ; Dark conserve la profondeur indigo et les lueurs célestes sans transformer toute la page en tuiles opaques.

## Responsive et accessibilité

- Mobile : gouttières de 16 px, dock fixe avec safe area, scroll vertical prioritaire ; seul le héros se glisse horizontalement.
- Tablette : colonne fluide centrée, sans desktop compressé.
- Desktop : navigation supérieure et largeur éditoriale stable ; pas de grille de dashboard qui réapparaît après le héros.
- Toute cible interactive atteint au moins 44 × 44 px.
- Focus visible, navigation clavier, zoom 200 %, forced colors et `prefers-reduced-motion` sont couverts.
- Aucun auto-scroll et aucune requête réseau liée au scroll.

## Garde-fous d’implémentation

1. Réemployer les routes et données existantes avant de créer un modèle ou un service.
2. Ne jamais remplir un état vide avec une histoire, une illustration ou un événement fictif.
3. Précharger les progressions de lecture nécessaires en une requête ; aucune N+1 dans les partials.
4. Garder les services métier hors des partials : `Hubs::Screen`, `Hubs::NowCards`, `Hubs::ReadingCards`, `Hubs::RamaEvents` et `Hubs::CircleDiscovery` fournissent des objets de présentation.
5. Toute suppression de surface doit aussi retirer ses partials, contrôleurs, services, CSS et assertions qui ne servent plus ; ne pas laisser d’alias de compatibilité ou de sélecteur dormant.

## Vérification

Les tests de Home vérifient notamment :

- la séquence exacte des enfants du feed ;
- l’unicité du héros, du Live et de la CTA `.hub-play` ;
- l’absence de contenu personnel inventé pour un visiteur ;
- la déduplication des chapitres et les trois statuts de lecture ;
- le scope, la publication et l’annulation des événements ;
- l’état PWA installable / refusé / incompatible ;
- les thèmes Light et Dark, les tailles 320, 390, 768, 1024, 1440, 1536 et 1920 px, l’overflow et la console.

Les captures vérifiées sont conservées sous `tmp/street-shots/temple-mockups/`. Elles servent au contrôle visuel, jamais comme contenu de production.
