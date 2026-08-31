# M158 — Bibliothèque personnelle des Écritures

Reviewed: 2026-08-31
Slice: one editorial stream from desire to read, not a dashboard
Tests: targeted controller, i18n, recommendation, weekly-reading and visual system tests — green
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr present and validated

## Feeling

Contemplation first, then the quiet desire to take one clear next step. The player sees a living relationship with scripture, never an account-management surface.

## 1 — Game experience

The loop is Quiz curiosity → personalized passage → exact reading position → saved memory or Circle conversation → next weekly reading. Resume is always the strongest action. Progress reassures without scoring or ranking.

## 2 — UI design

The two-second verb is **Continue**. One row carries one information and one intention. The HUD and dock remain recognizable but subordinate. All rows exceed the 44 px interaction minimum; progress bars expose accessible values; focus and reduced-motion states are present.

## 3 — Art direction

Celestial Dark is derived from the approved Psalms refuge artwork. The gold beam establishes contemplation; the ivory stream reads as a scripture page. Gold is reserved for guidance and progress, not decoration.

## Theme engine

N/A — this is a dedicated Celestial Dark scripture surface, not the Hub backdrop engine.

## Four seats

N/A — personal street surface. Who: the current player. Where: their scripture library. What now: resume or open one editorially grounded reading. Around me: Rama completion and passage-linked Circle conversations.

## Tension

Quiet progression: unfinished chapter → useful recommendation → weekly arc → annual horizon. No competitive escalation.

## Finale

N/A. This surface feeds reading and conversation rather than a live final round.

## Languages

Copy read in **es**, **pt-BR**, **en**, **fr**; YAML and parity tests green. Quiz citations are rebuilt with the canonical localized book name rather than leaking the source language.

## Scores

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- The cinematic opening immediately separates the experience from a dashboard.
- Resume owns the first fold without competing widgets.
- Real data sources remain truthful: resumable reader position, missed-Quiz recommendation, published weekly readings, bookmarks, canonical history, verified Rama completions, annual chronology.
- The Circle remains separate and is reached only through the shared scriptural object.

## What feels weak

- A week without an editorial `theme` falls back to its full heading, which is factual but less lyrical.

## Required before approval

- Editorial may add localized weekly `theme` copy to the published quiz payload; the layout already supports it. This is not a launch blocker.

## Evidence

- Visual captures: 390×844, 768×1024, 1440×900.
- Console: no severe browser entries.
- Preview fixture is development/test-only; production always uses current records.

## Night director

Yes: the first fold makes the unfinished passage feel like an invitation, and every later line answers one distinct reason to keep reading.
