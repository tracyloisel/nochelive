# M5 — Stand-up finale review

Reviewed: 2026-08-24
Slice: Night end is a ceremony (stand up, names, podium) on play / watch / presenter
Tests: `bundle exec rails test` — 25 runs, 196 assertions, 0 failures

---

## Agent

Gameplay Designer

## Verdict

PASS

## Score impact

Gameplay: 5/5
Reward: 5/5
Replayability: 4/5

## What works

- Closing the night is no longer leftover round chrome. Everyone sees the same ritual.
- The first line is a body verb: ¡TODOS DE PIE!
- The TV says a name. Lucía can point at herself.
- A tie is a shared crown, not a broken first row.

## What feels weak

- Round 15 is still a 25-point buzzer. The celebration is after the last question, not inside it.
- Ordering and scavenger are still cards.

## Highest-value improvement

Make the last *round* feel like a finale, or turn scavenger into a real verb. Do not add another score animation.

## Required before approval

- None.

---

## Agent

Art Director / VFX Artist

## Verdict

PASS WITH NOTES

## Score impact

Visuals: 4/5
VFX: 4/5

## What works

- The podium has height. First place is actually taller.
- Sparks are CSS, reduced-motion safe (they stop).
- The sky warms when a ceremony is on screen.

## What feels weak

- It is still rectangles and 10 sparks, not a designed burst.
- The crown illustration is the same mid-night art.

## Highest-value improvement

A distinct finale mark, still original SVG. Not more gold flash.

## Required before approval

- None. Do not call this a 5.

---

## Agent

Sound Designer

## Verdict

PASS

## Score impact

Sound: 4/5

## What works

- The existing `royal_fanfare` still fires on finished. One cue, one meaning.

## What feels weak

- No new stand-up sting. The room has to make the noise.

## Required before approval

- None. Do not add a second fanfare on the same beat.

---

## Agent

Party & Social Designer

## Verdict

PASS

## Score impact

Social: 5/5

## What works

- The room is asked to stand. That is a shared beat, not a leaderboard refresh.
- Names on the TV give Abuela María a reason to cheer a child.

## What feels weak

- Nobody is told *when* to sit down. Fine. The night is over.

## Required before approval

- None. Social was already 5. It does not rise again.

---

## Agent

Remote Play Designer

## Verdict

PASS

## Score impact

Remote: 4/5

## What works

- Daniel sees the same ceremony and his own place line.
- He is not a spectator leftover.

## What feels weak

- He cannot stand up *with* the room unless he is on a call. The card does not pretend otherwise.

## Required before approval

- None. Same ritual, Grade A for the ending. Remote as a category stays 4 because Jonah and silent taboo are unchanged.

---

## Agent

UX Accessibility Tester

## Verdict

PASS

## Score impact

Clarity: 4/5
Accessibility: 4/5

## Personas

- Lucía: her name, a tall step, “Sois los campeones.”
- Abuela María: huge stand-up line, short blessing.
- Daniel: “Quedáis 2.º” — he knows he played.
- Presentador: no Abrir, no +5. The night is closed.

## What feels weak

- Ten spark dots can still distract. Reduced motion kills them.

## Required before approval

- None.

---

## Agent

Pacing Director

## Verdict

PASS

## Score impact

Pacing: 4/5

## What works

- CELEBRATION now exists as a screen, not a comment in YAML.

## What feels weak

- The last playable verb is still a buzzer. The curve’s last *round* did not change.

## Required before approval

- None. Do not take Pacing to 5 on the after-party alone.

---

## Agent

Game QA / Red Team

## Verdict

PASS

## Score impact

Reliability: 4/5

## What works

- Champion / tie / visual order are covered in model tests.
- Play, watch, and presenter all render the stand-up copy.
- Presenter no longer offers Abrir or Cerrar noche after finish.
- Watch lists both room and remote names.

## What feels weak

- `cached_score` is what the podium trusts. If a presenter never awarded, everyone ties at 0 and shares a crown. Honest.

## Boring test

Without the crown SVG, it is still “stand up, here are the names.” Pass.

## Required before approval

- None.

---

## Game Director

M5 approved. The memory is: the room stood up and a child’s name was on the wall.

Quality: **65 / 75**. The only move is Reward 4 → 5. Gameplay, Social, Remote, VFX, and Pacing stay put — the last *round* is still a question, and the sparks are still CSS.

Next: a real verb for scavenger or ordering, or make round 15 itself feel like a finale. Not accounts. Not another gold flash.
