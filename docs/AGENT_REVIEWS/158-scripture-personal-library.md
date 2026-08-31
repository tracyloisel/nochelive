# M158 — Bibliothèque personnelle des Écritures

Reviewed: 2026-08-31
Slice: one editorial stream from desire to read, not a dashboard
Tests: resolver, controller, i18n, navigation, reader, Circle, deep-route and visual system tests — green
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
| Fun | 9.2 |
| Clarté | 10 |
| Impact visuel | 9.4 |
| Feedback | 9.2 |
| Progression | 9.3 |
| Social | 9.2 |
| Immersion | 9.5 |
| Accessibilité | 9.4 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.4 |

## Verdict

PASS

## What works

- The cinematic opening immediately separates the experience from a dashboard.
- Resume owns the first fold without competing widgets.
- Real data sources remain truthful: resumable reader position, missed-Quiz recommendation, published weekly readings, bookmarks, canonical history, verified Rama completions, annual chronology.
- The Circle remains separate and is reached only through the shared scriptural object.
- The compact hero search resolves canonical aliases across es, fr, en and pt-BR, and progressively enhances a server-rendered GET form with an abortable keyboard combobox.
- Historical aggregators now issue temporary redirects to safe Bibliothèque anchors; the historical rama code is ignored.

## Editorial note

A week without an editorial `theme` falls back to its factual published heading. Editorial may enrich that copy later; no invented theme is shown.

## Evidence

- Visual captures inspected: `tmp/street-shots/scripture-library/library-390x844.png`, `library-768x1024.png`, `library-1440x900.png`.
- Console: no severe browser entries.
- Preview fixture is development/test-only; production always uses current records.
- Artwork: the approved responsive `media/study/psalms-refuge-2026.png` manifest was reused; no duplicate generated asset was retained.
- Final concerned-suite run: 71 tests, 3,087 assertions, all green; Zeitwerk eager-load check green.
- Visual/search run: 3 tests, 30 assertions, all green — keyboard combobox, deep-link focus, reduced motion and no severe console entries.

## Night director

Yes: the first fold makes the unfinished passage feel like an invitation, and every later line answers one distinct reason to keep reading.
