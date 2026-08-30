# 149 — Historique privé des réponses joueur

Reviewed: 2026-08-30
Slice: depuis sa fiche, revoir chaque réponse Aventure/Parole, comprendre l’erreur et repartir jouer
Tests: 55 runs / 25 752 assertions ciblées + architecture, 4 runs / 263 assertions système visuel — 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr présentes, parsées et exercées

## Feeling

Le joueur doit ressentir de la maîtrise et l’envie de progresser, jamais la honte d’une mauvaise réponse : « je vois ce que j’ai choisi, je comprends la solution et je peux faire mieux la prochaine fois ».

## 1 — Game experience

Revue `noche-night` effectuée en premier.

La boucle personnelle est courte : la fiche annonce le volume et les réussites ; le joueur ouvre « Mes réponses » ; chaque ligne donne immédiatement verdict, réponse choisie, bonne réponse et temps ; les références scripturaires reconnectent le résultat au contenu ; le retour profil ou l’état vide invite à reprendre Aventure.

Les sessions Aventure et Parole sont regroupées chronologiquement plutôt que versées dans une pile technique. Les réponses Live sont exclues : leurs formats hétérogènes ne garantissent pas une vérité individuelle ni une durée par question. Aucun faux score de connaissance n’a été inventé.

## 2 — UI design

Revue `noche-ui` effectuée en second.

Le test des deux secondes répond à trois questions : combien de réponses, quel taux de réussite, combien de temps en moyenne. Chaque session est un seul panneau de verre ; ses réponses sont des lignes séparées par des hairlines, pas une mosaïque de cartes imbriquées. Le bleu nuit signifie correct, le corail signifie incorrect, mais chaque état possède aussi un symbole et un libellé explicite.

Les durées historiques inconnues affichent « Non disponible » et sont exclues de la moyenne. La pagination limite le chargement à huit sessions. Les textes, réponses longues, données partielles, état vide, cibles tactiles et absence de débordement sont couverts à 390 × 844, 768 × 1024 et 1440 × 900.

## 3 — Art direction

Revue `noche-art` effectuée en troisième.

Emotion : progrès calme et confiant. Composition : lockup céleste, retour profil, trois repères métalliques, puis chronologie de sessions. Univers : rassemblement lumineux du profil. Famille : Celestial Light dictée par l’artwork, sans toggle. Hiérarchie : le titre et les trois agrégats précèdent les détails ; l’encre porte les titres, l’or reste hairline, métal et CTA unique de l’état vide.

Le verre ivoire laisse l’architecture sacrée visible. Aucun VFX supplémentaire n’est justifié pour cette surface de lecture soutenue ; les profondeurs, reflets locaux et états pressés existants suffisent, avec reduced motion conservé. Le médaillon « Mes réponses » a été généré spécialement pour la feature et vérifié avec un canal alpha réel. Deux variantes au damier rasterisé ont été refusées.

La page appartient immédiatement à Noche Live : peinture pleine hauteur, oculus, or métallique, serif monumentale, dock de jeu et médaillon original — pas un tableau de bord SaaS posé sur un fond.

## Theme engine

N/A : surface Profil Celestial Light déterminée par son artwork. Aucun thème utilisateur ni markup parallèle.

## Four seats

N/A — surface Street privée.

| Question Street | Réponse immédiate |
|---|---|
| Qui ? | Le joueur reconnu sur cet appareil |
| Où ? | Dans sa fiche privée Noche Live |
| Quoi maintenant ? | Comprendre une réponse puis retourner jouer |
| Autour de moi ? | Rien de social n’expose cet historique personnel |

## Tension

Pas de tension de manche. La progression vient de la comparaison honnête entre choix et solution, puis de l’envie de refaire un parcours. Aucun timer animé ni récompense artificielle n’est ajouté.

## Finale

N/A.

## Languages

La copie factuelle a été livrée dans les quatre langues, sans décision éditoriale ou conseil personnalisé : es, pt-BR, en et fr. Les YAML sont valides ; les rendus français et espagnols sont exercés par les tests, et les clés ont la parité requise.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.4 |
| Clarté | 9.7 |
| Impact visuel | 9.3 |
| Feedback | 9.6 |
| Progression | 9.4 |
| Social | 8.0 |
| Immersion | 9.3 |
| Accessibilité | 9.5 |
| Cohérence NocheLive | 9.6 |
| Envie de continuer | 9.1 |

## Verdict

PASS

## What works

- L’historique est utile sans devenir punitif ni administratif.
- La confidentialité est imposée côté serveur et testée avec un autre profil.
- Le détail reste lisible sur mobile avec toutes les preuves nécessaires à l’apprentissage.
- Les anciennes durées inconnues sont traitées honnêtement.
- Le nouveau médaillon donne à la destination une identité propre.

## What feels weak

- Une ancienne définition de quiz supprimée ne peut plus restituer son texte exact ; le fallback reste explicite mais moins riche.
- La destination ne propose pas encore de relancer directement le même pack depuis chaque session.

## Required before approval

- None.

## Evidence

- Route privée : `GET /ficha/respuestas`.
- Captures : `tmp/street-shots/profile-dashboard/profile-answer-history-*.png` et `profile-answer-history-empty-390x844.png`.
- Viewports inspectés : 390 × 844, 768 × 1024 et 1440 × 900.
- Console : aucun WARNING ni SEVERE.
- Données : Aventure et Parole, durée connue/inconnue, bonne/mauvaise réponse, pagination et exclusion d’un autre profil.
- Qualité : 16 fichiers Ruby inspectés par RuboCop, aucune offense ; `git diff --check` propre.

## Night director

Oui, j’ai envie de rejouer : chaque erreur devient une piste claire et chaque bonne réponse une preuve de progression, sans transformer la foi en note publique.
