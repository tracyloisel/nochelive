# M103 — Duel viral WhatsApp

Reviewed: 2026-08-28
Slice: fin d’un pack → inviter un ami → jouer → résultat → revanche
Tests: `bin/rails test` ciblé — 60 runs, 379 assertions, 0 failures; suite complète — 827 runs, 9305 assertions, 30 failures et 23 erreurs préexistantes dans les travaux parallèles hub/profil/étude
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: Celestial Light généré pour l’arène, la porte de cérémonie et quatre médaillons sociaux
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validés

## Feeling

Rivalité joyeuse et personnelle : « Carmen pense vraiment que je ne peux pas battre 77 ? »

## 1 — Game experience

Boucle : score célébré → défi personnel → partage natif → score à battre → partie immédiate → face-à-face → revanche. Le nouvel invité n’a pas à créer de compte ; une fiche légère suffit. La revanche remplace le retour carte comme prochain désir principal.

## 2 — UI design

Le verbe se lit en moins de deux secondes : Accepter le défi, puis Revanche. Le score à battre est le héros. Un seul CTA or demeure sur la landing et le résultat. États couverts : attente, invité, pris, expiré, jeu, résultat, égalité, victoire, défaite.

## 3 — Art direction

L’arène devient un croisement de deux chemins lumineux. La cérémonie ouvre une porte céleste sur un podium réel. Les quatre médaillons peints — défi, partage, revanche, victoire — lient les deux moments. Papier ivoire, encre et un seul CTA métallique restent lisibles au-dessus du décor.

## Four seats

N/A — street duel asynchrone. Qui : les deux visages. Où : le pack. Maintenant : battre le score. Autour de moi : rival, résultat et historique.

## Tension

Le score précis est annoncé avant la première question. Le résultat n’est révélé qu’après les deux parcours, puis la revanche réouvre immédiatement la rivalité.

## Finale

N/A — la cérémonie du pack devient le départ du duel.

## Languages

noche-i18n: PASS. Espagnol chaleureux, portugais brésilien avec « ala », français tutoyé et ponctuation native, anglais direct et familial.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 9 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 10 |
| Immersion | 8 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Invitation personnelle avec nom, pack et score, jamais un message publicitaire générique.
- Illustrations verticales et icônes propriétaires générées pour ce flux, optimisées en WebP lorsque pertinent.
- Arrivée jouable sur un nouvel appareil sans compte.
- Funnel attribué du prompt jusqu’au retour du binôme à J+7.
- Annulation du partage non comptée comme envoi.

## What feels weak

- Le navigateur ne peut pas prouver que WhatsApp a réellement livré le message ; `invite_share_completed` signifie que la feuille de partage ou la copie s’est terminée.

## Required before approval

- None.

## Night director

Oui : le résultat ne termine plus l’histoire, la revanche est déjà le prochain round.

## Visual evidence

- Landing vérifiée à 390 × 844 : deux pistes convergent derrière l’arène, CTA et score lisibles.
- Cérémonie vérifiée à 390 × 844 : podium, score, stats, classements et actions restent accessibles avec 97 px de défilement interne.
