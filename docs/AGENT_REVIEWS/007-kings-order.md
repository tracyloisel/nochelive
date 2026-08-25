# M7 — El orden de los reyes review

Reviewed: 2026-08-24
Slice: Ordering as a tap sequence (same scramble for the team, auto-score)
Tests: `bundle exec rails test`
Gate: `.cursor/skills/noche-night/SKILL.md`.

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Abrir; auto-score does the rest |
| Equipo en sala | Tap the kings in time |
| Jugador en casa | Same scramble, same taps (A) |
| Espectador | The order board |

---

## Evidence

Gameplay Designer

## Verdict

PASS

## Score impact

Gameplay: 5/5
Agency: 4/5
Replayability: 4/5

## What works

- The verb is TAP THE TIME, not “wait while the presenter lines the names up.”
- Room and home get the same three names, scrambled the same way.
- Third tap sends the sequence. Wrong order is incorrect; right order is correct.
- Lucía does not need a Bible degree. Saúl before David is a story she already knows.

## What feels weak

- Freeze-dance, category race, and the Solomon vote are still cards.
- Three names is short. Fine for this night. A later theme can grow the list.

## Highest-value improvement

Freeze as a real stop, or make round 15 itself feel like a finale. Do not add drag-and-drop chrome.

## Required before approval

- None.

---

## Evidence

Remote Play Designer

## Verdict

PASS

## Score impact

Remote: 4/5

## What works

- Grade A: Daniel taps the same names in the same scramble. He is not watching the room solve it.
- Watch does not print the true order.

## What feels weak

- Jonah is still 1-in-3 if he cannot see the mime.
- The night’s remote grade is still pulled down by leftover B/C cards.

## Highest-value improvement

Keep this A. Do not invent a remote-only puzzle.

## Required before approval

- None. This is A.

---

## Evidence

Party & Social Designer

## Verdict

PASS

## Score impact

Social: 5/5

## What works

- Teammates see the same scramble and can shout “¡David segundo!”
- The TV asks who reigned first without handing the answer.

## What feels weak

- One player can tap all three before the table talks. Same as choice rounds.

## Highest-value improvement

Leave it. Talking is the room’s job.

## Required before approval

- None.

---

## Evidence

Progression & Reward Designer

## Verdict

PASS

## Score impact

Progression: 5/5
Reward: 5/5

## What works

- Correct writes the same `ScoreApplier.correct!` path as a choice.
- Wrong still pays the participation XP.

## What feels weak

- No new chest beat. Correct.

## Required before approval

- None.

---

## Evidence

UI / Visual / VFX Designer

## Verdict

PASS

## Score impact

Visual: 4/5
VFX: 4/5

## What works

- Names are the same choice buttons as true/false.
- The trail fills 1. 2. 3. before the post.
- Press + tokens. No new palette.

## What feels weak

- The trail is quiet. Fine. The gold still belongs to a lock-in, not a tap.

## Required before approval

- None.

---

## Evidence

Audio Designer

## Verdict

PASS

## Score impact

Sound: 4/5

## What works

- No new cue. Correct / incorrect reuse the existing score sounds on broadcast.

## What feels weak

- Three taps have no click of their own. Acceptable.

## Required before approval

- None.

---

## Evidence

Pacing & Accessibility Designer

## Verdict

PASS

## Score impact

Pacing: 4/5
Accessibility: 4/5
Clarity: 4/5

## What works

- Intro shows the names. Open turns them into buttons.
- Borrar undoes the last tap.
- Abuela can tap large names. No drag.

## What feels weak

- Freeze still stops the night’s body for a card.

## Required before approval

- None.

---

## Evidence

Technical Reliability

## Verdict

PASS

## Score impact

Reliability: 4/5

## What works

- `Answers::Submit` locks, is idempotent, grades choice / taboo / mime / ordering, then broadcasts.
- Hosted “El presentador dirige” is gone from this screen.
- Second submit is a no-op (existing answer).
- Shuffle is seeded by `round.id` so teammates match.

## What feels weak

- ScoreApplier and NightBroadcaster still live in `app/models`. Out of scope.

## Boring test

Without the title, it is still “tap the three kings in time.” Pass.

## Required before approval

- None.

---

## Night director

M7 approved. The memory is: someone slapped Saúl, then David, then Salomón, and the room knew.

Quality: **65 / 75**. No category moves. Gameplay and Social are already 5. Agency stays 4 because freeze, category, and vote still steal later rounds. Remote stays 4 because this A does not fix Jonah.

Do not inflate. The slice is done because Lucía can tap the time, not because the scorecard ticked.

Next: freeze as a real stop, or make round 15 itself feel like a finale. Not accounts.
