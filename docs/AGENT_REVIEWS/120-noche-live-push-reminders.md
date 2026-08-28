# M120 — Le rappel qui ouvre la porte de la Noche

Reviewed: 2026-08-28
Slice: Noche programmée → consentement choisi → rappel utile → entrée dans le lobby
Tests: 1 005 runs, 15 227 assertions, 0 failure, 0 error, 93,37 % de couverture ; correctif de file : 5 runs, 39 assertions ; 5 tests Service Worker verts
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — aucun manifest, artwork ni token du Hub ne change
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr à parité

## Feeling

Se sentir personnellement attendu à la soirée de sa branche, puis retrouver la
bonne porte en un geste. Le rappel doit créer une petite montée d'anticipation,
jamais une pression ni le sentiment d'être poursuivi.

## 1 — Game experience

Le Hub révèle l'invitation contextuelle seulement lorsqu'une Noche de la branche
est programmée. Le joueur choisit d'abord la catégorie « Noche Live », puis le
navigateur demande son autorisation après le CTA explicite. Deux battements
prolongent cette décision : environ 24 heures avant pour se projeter, puis
15 minutes avant pour entrer. Un appui ouvre directement le lobby de cette Noche.

Les personnes déjà entrées sont exclues. Une soirée déplacée est recalculée ; une
soirée annulée, commencée ou terminée ne pousse plus rien. Aucun Push n'interrompt
une manche : une fois le spectacle lancé, le Live possède déjà ses propres sièges,
sons et tensions.

## 2 — UI design

L'invitation est placée juste après le billet de la Noche sur le Hub et garde un
verbe unique en or. Elle nomme le bénéfice avant d'appeler le dialogue natif. La
fiche Réglages sépare « Noche Live » des passages et des défis ; désactiver une
catégorie ne touche pas les autres. Aux formats 390, 768 et 1 440 px, le panneau
reste dans la colonne de jeu sans compression ni débordement.

## 3 — Art direction

Le panneau Dark appartient au monde nocturne de la Noche : bleu céleste, halo,
cloche claire et action or. Sa composition reste courte pour ne pas concurrencer
le billet Live. Il reprend la signature Noche sans inventer un dashboard ou une
modale d'autorisation maison.

## Theme engine

N/A. Le panneau hérite du mode Celestial de la scène existante ; aucune préférence
Light/Dark n'est ajoutée et le Home n'est pas dupliqué.

## Four seats

| Seat | Verb tonight |
|---|---|
| Host | Programmer la Noche puis la lancer à l'heure annoncée |
| Chapel (controller) | Appuyer sur le rappel, entrer et prendre sa place dans le lobby |
| Remote | Rejoindre la même porte avant le direct, puis jouer avec la branche |
| TV / Twitch | N'émet aucun Push ; devient le spectacle seulement après l'entrée |

## Tension

J−1 installe l'attente ; H−15 transforme l'attente en mouvement. La tension reste
hors des manches : aucun rappel marketing ne vient casser le compte à rebours, un
buzz ou une finale.

## Finale

Cette slice ne change ni les points ni le dernier round. Elle protège la finale en
cessant toute notification dès que la Noche quitte son lobby.

## Languages

Titres, corps, invitation, réglages et politique de confidentialité ont été lus
en es, pt-BR, en et fr. L'heure est rendue dans le fuseau enregistré par appareil.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 9.5 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 8.5 |
| Social | 9.5 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.5 |

## Verdict

PASS WITH NOTES

## What works

- ciblage limité à la branche, au consentement actif et aux joueurs pas encore entrés ;
- deux temps compréhensibles, dédupliqués et résistants à un passage du scheduler en retard ;
- appui vers `/s/:code/name`, sans boîte de réception intermédiaire ;
- annulation défensive si l'heure, la branche ou l'état de la Noche change ;
- aucune permission native dans l'onboarding ni aucun Push pendant le direct.

## What feels weak

- le rendu simulé ne remplace pas un essai réel Chrome Android et Safari iOS installé ;
- sans Noche programmée en production, ni invitation contextuelle ni rappel ne peut exister ;
- un joueur qui consent après la fenêtre J−1 ne recevra naturellement que H−15.

## Required before approval

- Programmer en production la Noche du 29 août 2026 avec sa branche et son heure exactes.
- Effectuer au moins un essai physique d'autorisation, réception et ouverture directe avant l'envoi général.

## Evidence

Tests de ciblage, fuseau, déduplication, reprogrammation, état Live, branche et
participant déjà entré. Captures vérifiées à 390×844, 768×1024 et 1440×900.
En production, Solid Queue a chargé les quatre queues séparées puis exécuté les
deux premiers `NightNotificationCoordinatorJob` sans erreur.
Le Hub ignore aussi une session `playing` datée dans le futur afin qu'elle ne
masque jamais le véritable lobby programmé ni son invitation de consentement.

## Night director

Oui : le rappel ne demande pas de chercher la soirée. Il ouvre sa porte, puis
disparaît dès que le jeu commence pour laisser toute la scène au Live.
