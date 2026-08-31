# M154 — Le Cercle, boîte de réception communautaire

Reviewed: 2026-08-30
Slice: lire un fil de paroisse et y contribuer sans quitter le Cercle
Tests: suite Circle ciblée (read model, démo, contrôleurs, contrat de chargement, locales, ActionCable et QA desktop/mobile) — 44 runs, 588 assertions, 0 failures; QA système Circle (desktop compact, mobile et brouillons WebSocket) — 6 runs, 101 assertions, 0 failures; smoke test de rendu de la liseuse — 1 run, 11 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — cette surface réutilise le HUD et le dock communs, sans modifier le thème du Hub.
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr validés par le test de parité.

## Feeling

Appartenance calme et capacité d’aider tout de suite : « je lis la question de ma paroisse, je vois la conversation entière, je peux répondre sans une succession de clics. »

## 1 — Game experience

La boucle est `arriver → lire le fil déjà ouvert → répondre → voir les autres contributions en direct → relire le chapitre seulement si je le choisis`. Le chapitre est l’expéditeur de la conversation ; les personnes sont ses participantes. Sur bureau, une inbox compacte et le fil coexistent. Sur mobile, l’inbox mène au fil plein écran et le retour est explicite. Il n’y a plus de rail spécifique ni de carte intermédiaire qui détourne le geste principal.

Les signaux ActionCable sont volontairement sans contenu et rechargent le même fil côté serveur. Un brouillon, un champ actif, un envoi ou un brouillon renvoyé après erreur de validation diffère ce rafraîchissement ; le membre peut ensuite l’appliquer explicitement sans perdre son texte.

## 2 — UI design

Le verbe en deux secondes est « répondre ». HUD et dock sont ceux du produit, pas une navigation latérale du Cercle. L’inbox n’affiche que le chapitre, la question, la dernière participante et l’état de réponse. Le composeur commence à quatre lignes, s’agrandit avec le texte, et l’envoi est une cible icône de 44 px — présente sans prendre la place de la réponse.

Les états vide, lecture seule, chargement Turbo, sélection, brouillon protégé, actualisation différée, focus, contraste forcé et mouvement réduit sont couverts. La QA système vérifie les largeurs 1440 × 900 et 390 × 844 sans débordement horizontal, texte tronqué ou répartition artificielle de l’espace vertical : un fil court reste court et les lignes de l’inbox restent contiguës.

## 3 — Art direction

La lumière du Cercle vient de l’illustration de rassemblement approuvée : ivoire pour la lecture, encre pour le texte, or réservé à l’action et au chapitre. Le mode Celestial Light n’est pas un toggle ; il est résolu par l’œuvre de rassemblement. La page reste une surface de parole dense, pas un tableau de bord décoratif.

## Theme engine (hub `/` only)

N/A — aucune atmosphère du Hub n’est modifiée.

## Four seats

N/A — boucle communautaire asynchrone. La « place » active est celle de la personne qui choisit d’apporter une réponse attentionnée à sa paroisse.

## Tension

Tension douce : une question sans réponse est visible immédiatement ; une contribution la fait passer de l’attente à la conversation. Le temps réel rend les présences vivantes sans voler l’attention du brouillon en cours.

## Finale

N/A — aucune mécanique de soirée Live ni de couronne n’est modifiée.

## Languages

PASS — les libellés Inbox, retour, relecture, confidentialité et actualisation sont présents en espagnol, portugais brésilien, anglais et français.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9.5 |
| Impact visuel | 8.5 |
| Feedback | 9 |
| Progression | 8 |
| Social | 9.5 |
| Immersion | 8.5 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Un clic sur une conversation suffit ; seul « Relire le chapitre » ouvre la liseuse.
- Le brouillon est traité comme une possession du membre, jamais comme une zone jetable lors d’un événement distant.
- Les données du fil transmises aux vues sont des objets de lecture sûrs : ni modèle `Person` ni modèle `ScriptureCirclePost` ne peuvent exposer une identité anonymisée par accident.
- Les composants de l’ancien tableau de bord, rail de lecture et résultats historiques sont retirés au lieu de cohabiter avec la nouvelle interface.

## What feels weak

- Le navigateur embarqué de cette session ne voit qu’un fallback PWA « hors connexion » ; la vérification visuelle authentifiée repose donc sur les tests système Chrome plutôt que sur une session interactive manuelle.

## Required before approval

- Aucun.

## Evidence

- Tests système : inbox desktop + fil visible, inbox mobile + ouverture/retour, réponse locale, réponse distante propre et brouillon préservé.
- ActionCable : le stream garde le target `circle_live_feed` et diffuse une action sans contenu afin que chaque session refasse son propre contrôle d’accès.

## Night director

Oui : je peux lire, reconnaître qui a besoin d’une parole, répondre dans la même respiration, et revenir à l’Écriture seulement par choix.
