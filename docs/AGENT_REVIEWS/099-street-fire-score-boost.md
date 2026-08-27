# 099 — Street fire score boost

Reviewed: 2026-08-28
Slice: secured streak fires boost the pack ceremony score
Tests: 28 service/i18n runs + 1 responsive system run — 347 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validated
Sound: `.agents/skills/noche-sfx/SKILL.md` — existing named `fire_whoosh`, single JS trigger

## Feeling

Pride and suspense: the player sees the consistency built during the pack return as a material score reward.

## 1 — Game experience

The first fire is secured at three consecutive hits, then another every two hits. A miss resets the live combo but never removes secured fires. Each fire adds 5% of base points, capped at five fires / 25%. The server persists base score, fires, bonus, and boosted total before duel resolution or leaderboard reads.

## 2 — UI design

The ceremony starts on the honest base score. Earned fires land one by one; each step raises the number toward the final total. The medallion keeps both explanations visible: percentage and `base + bonus`. Reduced motion resolves immediately. Phone, iPad, desktop, and XL keep the HUD, hero, boards, and actions readable.

## 3 — Art direction

Orange fire is the transient power-up; gold remains the final metal reward. Fire becomes celestial sparks before the chest opens. The headline uses ink on the Light beam, reserving gold for the medallion and primary CTA.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 10 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- The animation explains the arithmetic rather than hiding it.
- Secured fires prevent a late miss from erasing the whole achievement.
- Duels receive the boosted server score before resolution.
- Existing named SFX, mute, and reduced-motion contracts remain intact.

## Required before approval

- None.

## Night director

Yes. Every correct answer after the first fire now carries visible end-of-pack stakes, and the ceremony pays those stakes off instead of showing a static total.
