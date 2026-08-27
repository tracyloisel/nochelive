# 066 — Street pack ceremony: overlay final score

Reviewed: 2026-08-27
Slice: `/jugar` pack-complete is a Celestial Light overlay (HUD + gateway still + medallion + stats + two boards + gold map CTA). Night ceremony (`shared/_ceremony`) untouched.
Tests: `bin/rails test` — 740 runs, 0 failures (1 fixture-load deadlock retried green on `Quizzes::WorldTest`); line coverage 95.21% of `app/`
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A (`/jugar`, not `/`)
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es / pt-BR / en / fr (`street.ceremony_shout_*`, `ceremony_finished`, stats, `share_my_score`, `quiz.combo_tag`)

## Feeling

Fierté + accomplissement + merveille (la porte céleste), puis appartenance (classements), puis envie suivante (carte / défi / partage). Pas « accéder au score ».

## 1 — Game experience

Boucle : dernière réponse → acte 1 (hall, shout, médaillon, coffre fermé) → acte 2 (count-up, coffre `chest`, particules, `+N` HUD) → acte 3 (stats, boards, CTA or qui respire) → Retour à la carte.

`royal_fanfare` à l’entrée. Pas de voile `level` sur l’overlay. Combo de fin = toutes les réponses. `+N` = dernière question si correcte. Série HUD = combo de fin ; stats = max streak.

## 2 — UI design

2 secondes : le score métal + **Retour à la carte**. HUD jugar (avatar, pack 10/10, couronne, flamme + tag, hamburger). Pills, pas hex. Lien partager, pas carte cadeau. Light tokens. Reduced-motion = état final.

## 3 — Art direction

Celestial Light from `ceremony-gateway`. Or = médaillon, couronne, un CTA, coffre. Titres shout / score en métal, sous-titre ink. God rays overlay, pas un voile laiteux.

## Theme engine

N/A.

## Four seats

Street — un siège (tú). N/A live.

## Tension

Le pack se ferme en spectacle, pas en fiche de résultats.

## Finale

N/A night. Street pack-complete is the street ceremony.

## Languages

noche-i18n: PASS

- es: ¡Increíble! / ¡Terminaste el quiz! / Mejores jugadores / Comparte mi puntaje / ¡Racha!
- pt-BR: Incrível! / Você terminou o quiz! / Melhores jogadores / Sequência!
- en: Incredible! / You finished the quiz! / Top players / Streak!
- fr: Incroyable ! / Tu as terminé le quiz ! / Meilleurs joueurs / Série !

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.6 |
| Clarté | 8.7 |
| Impact visuel | 8.5 |
| Feedback | 8.6 |
| Progression | 8.5 |
| Social | 8.3 |
| Immersion | 8.6 |
| Accessibilité | 8.2 |
| Cohérence NocheLive | 8.7 |
| Envie de continuer | 8.6 |

## Verdict

**PASS** — overlay jugar, mockup Celestial Light, chorégraphie 3 actes, métier live.

## What works

- Gateway still + HUD sticky + hamburger (mute/lang in drawer)
- Médaillon or, lauriers, coffre, stats 4, deux boards 3 personnes
- CTA or pill + défi ivoire + lien partager
- Count-up, coffre, particules, haptic legend, skip / reduced-motion

## What feels weak

- Sur 390, le lien partager peut passer sous la ligne si un défi en cours affiche la note d’attente (KEEP live).
- Jump test à la Q10 → stats 1/10 honnêtes, pas le 10/10 du PNG démo.

## Required before approval

- None.

## Evidence

`tmp/street-shots/temple-themed/ceremony-phone.png` vs `tmp/street-shots/temple-mockups/mockup-street-ceremony-celestial-light.png`

## Night director

Would I play another pack? Yes — the hall pays off the last hit, then the map is the next want.
