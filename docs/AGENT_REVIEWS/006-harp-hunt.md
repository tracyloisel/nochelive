# M6 — El arpa de David review

Reviewed: 2026-08-24
Slice: Scavenger as a hunt (stand up, find something that sounds, slam ¡LO TENEMOS!)
Tests: `bundle exec rails test` — 26 runs, 227 assertions, 0 failures
Gate: `.cursor/skills/noche-night/SKILL.md`.

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Open the hunt; grade the slam |
| Equipo en sala | Stand up, find something that sounds, ¡LO TENEMOS! |
| Jugador en casa | Hunt something that sounds at home (B) |
| Espectador | Who found it |

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

- The verb is RUN, not “wait for the presenter.”
- Room and home both hunt. The slam is the same giant button as the buzz, with different words.
- A claim does not auto-score. Lying with an empty hand does not pay until the presenter sees an object.
- Lucía can win this with a saucepan. Carlos’s Bible knowledge does not matter.

## What feels weak

- Ordering, freeze-dance, category race, and the Solomon vote are still cards.
- A team can slam with nothing in their hands. The presenter is the referee, which is correct and also a hole.

## Highest-value improvement

Ordering as a real drag-or-tap sequence, or freeze as a real stop. Do not add a photo pipeline.

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

- Grade B: Daniel hunts in his kitchen. Keys, a pot, his voice.
- He slams the same claim. He is not “press OK when the room is finished.”

## What feels weak

- The presenter cannot see Daniel’s pot unless there is a call. Confirming casa is trust.
- Jonah is still 1-in-3 if he cannot see the mime.

## Highest-value improvement

Keep Grade B. Do not ask for a camera.

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

- The room stands up and rummages. That is a story.
- The TV shouts who found first. People will argue about whether a spoon is a harp.

## What feels weak

- Social was already 5. A good hunt does not raise it again.

## Required before approval

- None.

---

## Evidence

UX Accessibility Tester

## Verdict

PASS

## Score impact

Clarity: 4/5
Accessibility: 4/5

## Personas

- Lucía: ¡BUSCAD! / huge ¡LO TENEMOS!
- Abuela María: “cualquier cosa que suene” — a glass is enough.
- Daniel: “En casa: caja, llaves, olla, voz.”
- Presentador: Lo tienen / siguen buscando. One confirm.

## What feels weak

- The hunt button text is long on a small circle. Readable enough.

## Required before approval

- None.

---

## Evidence

Pacing Director

## Verdict

PASS

## Score impact

Pacing: 4/5

## What works

- YAML already sat this in a movement band. It now plays as movement.

## What feels weak

- Round 15 is still a 25-point buzzer.

## Required before approval

- None. Do not take Pacing to 5.

---

## Evidence

Game QA / Red Team

## Verdict

PASS

## Score impact

Reliability: 4/5

## What works

- Claim writes an answer and does not write `correct`.
- Hosted “El presentador dirige” is gone from the hunt screen.
- Watch lists the first team that slammed.
- Second submit is a no-op (existing answer).
- Remote and room both get the slam.

## What feels weak

- Claim body is a fixed string. Fine.
- Presenter can score a team that never slammed. Same as other hosted verbs.

## Boring test

Without the harp title, it is still “find a thing that makes noise.” Pass.

## Required before approval

- None.

---

## Night director

M6 approved. The memory is: someone ran for a pot and slammed the phone.

Quality: **65 / 75**. No category moves. Gameplay, Social, and Reward are already 5. Agency stays 4 because leftover cards still steal later rounds. Remote stays 4 because Jonah and silent taboo are unchanged.

Do not inflate. The slice is done because Lucía can run, not because the scorecard ticked.

Next: ordering as a real sequence, freeze as a real stop, or make round 15 itself feel like a finale. Not accounts.
