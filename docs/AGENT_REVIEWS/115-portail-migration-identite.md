# 115 — Portail de migration d’identité

Reviewed: 2026-08-28
Slice: passage de `nochelive.onrender.com` à `nochelive.com`, avec conflit de profils
Tests: modèles + contrôleur + service de fusion — 21 runs, 113 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr validés, 15 clés en parité

## Feeling

Sécurité, reconnaissance et soulagement : le joueur voit que Noche Live déménage avec lui, puis comprend que ses deux histoires seront réunies sans écraser son profil récent.

## 1 — Game experience

La boucle est courte et cérémonielle : apparition du portail → lecture immédiate de l’ancienne et de la nouvelle adresse → action dorée → comparaison éventuelle des deux profils → confirmation → progression réunie → retour au Hub. Le lien reste disponible quinze minutes et n’est consommé qu’après la décision du joueur. Un profil incompatible n’est jamais fusionné automatiquement.

## 2 — UI design

Le verbe à deux secondes est **Continuer** puis, en cas de conflit, **Fusionner mes deux profils**. La modale est centrée, réellement modale, accessible au clavier et non fermable par erreur avec Échap. États couverts : entrée, focus, pression, chargement, départ, mouvement réduit, lien expiré, comparaison compatible et refus sécurisé. Le compte récent et son appareil restent actifs jusqu’à la confirmation.

## 3 — Art direction

La composition reprend un portail arqué ivoire et or, une icône en halo, trois éclats célestes et un unique CTA doré. Le plan d’animation suit quatre actes : voile, arche, emblème et copie, puis départ lumineux. Les couleurs utilisent les jetons sémantiques Celestial Light/Dark et restent dictées par l’atmosphère existante.

## Theme engine

Même structure dans les deux atmosphères : surface, encre, texte secondaire, or et voile passent uniquement par les jetons. Aucun toggle et aucun markup parallèle.

## Four seats

N/A street — qui : le profil actuellement sélectionné ; où : ancienne puis nouvelle adresse ; quoi maintenant : continuer ou réunir les profils ; autour : les deux cartes de profil, leur date et leurs points.

## Tension

La tension vient de la crainte légitime de perdre un profil récent. La comparaison met les deux identités côte à côte, explique ce qui sera gardé et n’offre l’action irréversible que si le prénom normalisé et la paroisse correspondent.

## Finale

N/A — la récompense est la restitution de toute l’histoire : appareils, parties, quiz, études, lectures, surlignages, duels et attribution virale sont rattachés au profil conservé.

## Languages

PASS — les quinze clés `identity_migration` sont présentes en es, pt-BR, en et fr. Les termes locaux utilisent *rama*, *ala*, *ward* et *paroisse* ; aucun texte de contrôle n’est codé en dur.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Le POST reste sur l’ancien domaine, puis le navigateur suit une redirection complète hors Turbo vers le nouveau domaine.
- Le profil récent n’est jamais remplacé silencieusement ; les deux cartes sont montrées avant toute fusion.
- La fusion est transactionnelle, conserve le profil le plus ancien et rattache l’appareil actuel ainsi que l’ancien.
- Un second clic, un lien expiré ou une identité incompatible ne produit ni doublon ni perte de données.

## What feels weak

- Deux personnes différentes portant le même prénom dans la même paroisse peuvent encore être proposées à la comparaison ; la confirmation visuelle, l’avatar, le nom de famille, la date et les points restent donc indispensables.

## Required before approval

- None.

## Evidence

Mockup Light/Dark : `tmp/street-shots/temple-mockups/mockup-identity-migration-modal-light-dark.png`. Contrôles supplémentaires : syntaxe Ruby/JavaScript, YAML et `git diff --check` verts.

## Night director

Oui : ce passage administratif devient un petit rituel de retour à la maison, avec une promesse claire et une récompense concrète — retrouver toute son aventure au même endroit.
