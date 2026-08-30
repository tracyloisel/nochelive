# M150 — Noche Live programmée / Player / Watch

Reviewed: 2026-08-30
Slice: revue du mockup initial et de la simplification produit
Tests: N/A — documentation de conception
Décision produit: aucun présentateur, quiz existant, inscription tardive et classement d'équipes

## Feeling

La promesse n'est plus « quelqu'un anime la soirée », mais « ma rama joue ensemble
pendant une heure et je peux encore rejoindre la course ». Le moment collectif vient
des équipes, des changements de tête et des notifications en temps réel.

## Verdict sur le mockup original

**VETO sur l'interface proposée ; PASS sur la séparation entre jeu et Watch.**

Le mockup original ajoute trop de fonctions, réinterprète inutilement le quiz et
ressemble à un tableau de bord de régie. La bonne cible est plus simple :

- la page Noche se transforme automatiquement avec l'heure ;
- Player reste `/jugar` sans nouveau thème ;
- Watch raconte la compétition des équipes et permet encore d'y entrer.

## Boucle retenue

| Phase | Verbe du joueur |
|---|---|
| avant T−30 | S'inscrire et préparer les lectures |
| lobby | Choisir une équipe déjà créée dans la rama |
| Live | Jouer, reprendre ou regarder la course |
| fin | Voir le résultat des équipes |

Il n'y a pas de bouton Host. Le lobby ouvre à T−30, le jeu commence à T0 et la
session se ferme à T+60.

## Player

Le quiz actuel passe le test des deux secondes : la question et l'action de réponse
restent prioritaires. Les événements Live utilisent la tuile Défi existante, une à la
fois, sans ajouter un rail de classement, une discussion ou un nouveau HUD.

Le joueur terminé voit son score normal et `Retour à la Noche Live`.

## Watch

Watch doit répondre immédiatement à quatre questions :

1. combien de temps reste-t-il ?
2. quelle équipe mène ?
3. jusqu'où les joueurs ont-ils avancé ?
4. comment puis-je rejoindre ou reprendre le jeu ?

Le CTA d'entrée reste visible pendant toute l'heure de jeu. Un nouveau joueur peut
s'inscrire, choisir une `WardTeam` existante, puis démarrer. Aucune équipe ne se crée
ou ne s'édite dans la Noche. Les équipes sont classées par
somme brute des points de leurs membres ; Watch ne met donc plus en avant un podium
individuel.

Le mobile montre CTA, top des équipes, progression compacte et dernier événement. La
TV donne plus d'espace au classement et aux événements, avec un QR d'entrée à la place
du bouton, sans transformer le même contenu en grille analytique.

## Art direction

L'illustration et la famille Light/Dark viennent du pack. La Noche n'a pas d'artwork
propre. Cela maintient une continuité immédiate entre l'inscription, Watch et le quiz
existant, tout en évitant un second thème visuel.

## Tension et finale

La session ne se ferme pas lorsque les joueurs actuels ont terminé, car un retardataire
peut encore arriver. La tension reste ouverte jusqu'à T+60. À cet instant, les scores
courants — y compris ceux des quiz inachevés — sont figés et le classement final des
équipes remplace le mode Live. Un joueur interrompu reçoit une sortie explicite
`Temps écoulé`, son score partiel et un retour Watch.

## Garde-fou d'architecture

Le quiz réutilise le moteur `/jugar`, mais chaque `QuizRun` porte un contexte Live.
Il n'apparaît ni dans l'aventure, ni dans les classements permanents, ni dans les
duels ordinaires. À T+60, un run inachevé devient `expired` ; `QuizRun.ends_at` reste
réservé au timer de la question et ne sert jamais d'horloge de session.

## Risques à traiter

- un CTA d'inscription trop discret transformerait Watch en cul-de-sac ;
- un formulaire affiché directement dans Watch nuirait à la lecture ;
- déplacer un joueur après son premier point fausserait les totaux d'équipe ;
- une barre en pourcentage peut reculer lorsqu'un retardataire commence : afficher
  aussi les comptes `réponses / joueurs éligibles` ;
- la somme brute favorise les grandes équipes, ce qui doit être expliqué clairement,
  sans ajouter une règle de compensation non demandée ;
- une cadence élevée doit transformer une tuile stable, sans empiler des toasts ni
  rejouer les événements devenus obsolètes.

## Required before approval

- montrer les états `non inscrit`, `sans équipe`, `quiz en cours` et `terminé` du CTA ;
- tester Watch à 390 px, tablette, desktop et TV 16:9 ;
- garantir une typographie lisible et des états non fondés uniquement sur la couleur ;
- montrer une égalité d'équipes et l'arrivée d'un joueur tardif ;
- valider le choix court parmi les `WardTeam` existantes ;
- tester une séquence réelle d'un événement toutes les deux secondes ;
- localiser les moments Live en es, pt-BR, en et fr.

## Score cible de la direction (/10)

Ces notes évaluent la direction retenue, pas encore son exécution visuelle finale.

| Dimension | Cible | Justification |
|---|---:|---|
| Fun | 8.5 | entrée tardive et retournements d'équipes maintiennent la course ouverte |
| Clarté | 9.2 | un CTA contextuel et trois blocs Watch |
| Impact visuel | 8.2 | artwork du pack plein cadre, verre local et signature or |
| Feedback | 8.8 | tuile Défi persistante et changements de tête à cadence dense |
| Progression | 8.7 | complétion des questions en comptes réels |
| Social | 9.1 | équipe choisie, total partagé et arrivée tardive visible |
| Immersion | 8.3 | même monde du pack avant, pendant et après le quiz |
| Accessibilité | 8.0 | hiérarchie courte ; validation sur appareils encore requise |
| Cohérence NocheLive | 9.0 | quiz existant, Celestial Light/Dark et or conservés |
| Envie de continuer | 8.6 | Watch permet de rejoindre, reprendre ou suivre jusqu'à T+60 |

## Night director

Oui, cette boucle peut être amusante sans présentateur : la possibilité de rejoindre
la course en retard empêche l'écran Live de devenir passif, et les équipes donnent un
enjeu collectif clair. La mise en scène doit rester au service du quiz existant : un
CTA net, un classement d'équipes lisible et un événement fort à la fois.
