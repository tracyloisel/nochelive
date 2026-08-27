# M095 — Profile selection belonging

Reviewed: 2026-08-27
Slice: `/ficha` device profile selection
Tests: locale YAML parse + browser QA at 390 × 844; Rails tests blocked by sandbox PostgreSQL socket access
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr reviewed

## Feeling

Belonging and anticipation: choosing a profile should feel like joining the group at the threshold of an adventure.

## 1 — Game experience

The loop is immediate: recognize yourself → tap your profile → enter the adventure. The technical device-memory explanation is replaced by an invitation. Add-profile and sign-out remain visibly secondary.

## 2 — UI design

The 2-second verb is the selected profile card. The main target is 88 px high on phone, with a strong selected state, while the add-profile action remains a ghost control. Motion respects reduced-motion preferences.

## 3 — Art direction

Celestial Light. A multigenerational group walks through a gold-trimmed arch toward the morning light. The composition creates a narrative threshold and fades into ivory behind the glass profile panel. Gold is reserved for the emblem, selection state, and restrained architectural material.

## Theme engine

N/A — this is `/ficha`, not the hub.

## Four seats

N/A street identity surface. Who: named ficha. Where: rama. What now: choose the player. Around me: other profiles on this device.

## Tension

Street arrival. Anticipation comes from seeing the group already moving into the world before the player chooses to join.

## Finale

N/A.

## Languages

es / pt-BR / fr / en read naturally as a direct invitation. Noche Live remains untranslated.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- The scene makes profile choice a threshold moment instead of an account setting.
- The current profile remains the first and strongest interactive target.
- Copy is warmer and shorter in all four locales.

## What feels weak

- Multi-profile layouts beyond two rows still rely on page scrolling.

## Required before approval

- None.

## Evidence

Browser QA: 390 × 844, no horizontal overflow, dock remains available, no console errors.

## Night director

Yes. The screen now promises a shared adventure immediately after the tap.
