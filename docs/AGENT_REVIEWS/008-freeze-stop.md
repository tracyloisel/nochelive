# M8 — La danza de David review

Reviewed: 2026-08-24
Slice: Freeze as a real stop (room body + remote catch)
Tests: `bundle exec rails test`
Gate: `.cursor/skills/noche-night/SKILL.md`.

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | ¡CONGELADOS! |
| Equipo en sala | Freeze the body |
| Jugador en casa | Catch the figure in 2s (B) |
| Espectador | The dancer on the TV |

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

- The verb is DANCE, then STOP. Not “wait while the presenter talks.”
- Presenter has one gold slam: ¡CONGELADOS! Every screen shouts together.
- Lucía puts the phone on the table and freezes mid-spin. Carlos can wobble and lose.

## What feels weak

- Category race and the Solomon vote are still cards.
- Room scoring is still the presenter’s eye. Correct for a freeze.

## Highest-value improvement

Make round 15 itself feel like a finale. Do not add a camera.

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

- Grade B: Daniel’s figure dances. When CONGELADOS hits, he has two seconds to slam ¡ME QUEDÉ!
- Tapping during the dance does nothing. He is not “press OK when the room is finished.”
- Late tap is incorrect. Server clock, not the phone’s.

## What feels weak

- Home cannot dance with the room. The figure is a different fun, not the same fun.
- Jonah is still 1-in-3 if he cannot see the mime.

## Highest-value improvement

Keep this B. Do not ask Daniel to film himself.

## Required before approval

- None. This is B, not D.

---

## Evidence

Party & Social Designer

## Verdict

PASS

## Score impact

Social: 5/5

## What works

- The room looks ridiculous. That is the point.
- The TV shouts BAILAD then CONGELADOS so the sofa and the hall stop on the same beat.

## What feels weak

- One early shouter can freeze the mood before the presenter slams. Presenter owns the stop. Fine.

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

- Remote catch uses the same correct/incorrect path.
- Room stills use the presenter’s Quietos / Se movió.

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

- A gold stick figure sways, then pauses. Reduced motion already kills the sway.
- CONGELADOS reuses the gold lock, not a new palette.

## What feels weak

- The figure is a mark, not a person. Enough.

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

- Lock plays dramatic_fire. The stop has a sound.

## What feels weak

- There is no music to cut. The presenter is the music. Acceptable for v1.

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

- Abuela can stay seated and still freeze her arms.
- Remote button is the same giant slam as the buzz.
- Two seconds is tight for Carlos and reachable for Daniel.

## What feels weak

- Category and vote still pause the body later.

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

- `Rounds::Lock` is the stop. `Freezes::Catch` locks the row, writes latency, grades, broadcasts.
- Early catch raises and redirects. Second catch is a no-op.
- Hosted “El presentador dirige” is gone from this screen.

## What feels weak

- ScoreApplier still lives in `app/models`. Out of scope.

## Boring test

Without the title, it is still “dance, then freeze when the word hits.” Pass.

## Required before approval

- None.

---

## Night director

M8 approved. The memory is: someone froze mid-spin and the room screamed.

Quality: **65 / 75**. No category moves. Agency stays 4 because category and vote still steal later rounds. Remote stays 4 because this B does not fix Jonah.

Do not inflate. The slice is done because Lucía had to stop, not because the scorecard ticked.

Next: make round 15 itself feel like a finale. Not accounts.
