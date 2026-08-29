# M131 — Les invitations envoyées occupent enfin la scène

Reviewed: 2026-08-29
Slice: `/desafios` — grille responsive des invitations envoyées
Tests: 1 test système / 42 assertions, 0 échec
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: N/A — aucune copie modifiée

## Feeling

Voir immédiatement l'état de toutes mes invitations sans avoir l'impression qu'une
colonne du Campus est cassée ou abandonnée.

## 1 — Game experience

La boucle sociale reste intacte : invitation envoyée → progression du reçu →
acceptation. La correction retire seulement l'espace mort qui séparait artificiellement
les invitations sur desktop.

## 2 — UI design

Au breakpoint 760 px, `is-outgoing` était la seule grande section oubliée dans la
liste des blocs pleine largeur. Elle restait donc dans une demi-colonne du conteneur
principal.

La section occupe maintenant toutes les colonnes disponibles. Sa grille interne
existante donne une carte par ligne à 390 px, deux colonnes à 768 px et trois colonnes
à 1440 px. Un garde-fou compare sa largeur à celle de `Résultats récents` aux deux
breakpoints larges.

## 3 — Art direction

Celestial Light inchangé. Les cartes ivoire et leurs rails dorés conservent leur
hiérarchie ; la correction redonne seulement un rythme horizontal cohérent et retire
la grande zone vide non intentionnelle.

## Theme engine

N/A — `/desafios` n'est pas le Hub `/`.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Lire l'état de chaque invitation envoyée |
| Mon rival | Recevoir, voir puis accepter |
| Invitation par lien | Suivre prêt → ouvert → accepté |
| Autour de moi | Comprendre l'activité sociale en un regard |

## Tension

Les reçus restent le moteur : envoyée, reçue, vue, acceptée. Aucun faux countdown ni
urgence supplémentaire.

## Finale

Inchangée.

## Languages

N/A — aucune chaîne ni clé i18n modifiée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.8 |
| Clarté | 9.8 |
| Impact visuel | 9.6 |
| Feedback | 9.2 |
| Progression | 9.4 |
| Social | 9.6 |
| Immersion | 9.4 |
| Accessibilité | 9.7 |
| Cohérence NocheLive | 9.7 |
| Envie de continuer | 9.2 |

## Verdict

PASS WITH NOTES — implémentation locale, non déployée.

## What works

- aucun espace mort latéral à partir de 760 px ;
- 1 / 2 / 3 colonnes selon le viewport ;
- les rails de progression et les dates restent lisibles ;
- aucune troncature ni débordement horizontal ;
- la section suit désormais le même contrat que les autres grands blocs.

## What feels weak

- sur un très grand écran, le Campus reste volontairement limité à 72rem ;
- contrôle sur appareils physiques encore souhaitable.

## Required before production approval

- Contrôle final sur iPhone et Android physiques.

## Evidence

- captures inspectées : section centrée à 390×844, 768×1024 et 1440×900 ;
- test système : 1 run, 42 assertions, 0 échec, 0 erreur ;
- console navigateur du scénario : aucune erreur sévère ;
- aucune permission, notification, destination ou règle éditoriale modifiée ;
- correction explicitement demandée par la responsable produit.

## Night director

Oui. Je peux maintenant comparer les invitations et leur progression sans que la
mise en page me donne l'impression que la liste s'est arrêtée en chemin.
