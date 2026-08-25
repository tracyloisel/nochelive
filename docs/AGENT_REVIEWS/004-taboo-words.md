# M4 — Palabras prohibidas review

Reviewed: 2026-08-24
Slice: Nabot taboo as a spoken party round (explainer / guessers / remote type-in / presenter slip catch)
Tests: `bundle exec rails test` — 22 runs, 160 assertions, 0 failures
Gate: `.cursor/skills/noche-night/SKILL.md`.

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Catch a slip; one lock |
| Equipo en sala | Shout without the forbidden words |
| Jugador en casa | Type a guess (B) |
| Espectador | Forbidden list / put the phone down |

---

## Evidence

Gameplay Designer

## Verdict

PASS

## Score impact

Gameplay: 5/5
Tension: 5/5
Replayability: 4/5

## What works

- The title does not spoil. The explainer sees the target. Guessers do not.
- Room guessers shout. They do not get a text field that turns the living room into a quiz.
- A wrong typed guess does not sink the team while the room is still talking.
- A matching remote guess can steal. The presenter can also tap “¡Lo adivinaron!” when the room shouts.
- Forbidden words live on the explainer phone, the presenter desk, and the TV. The room can catch a slip.

## What feels weak

- The explainer is “first player by id,” not a chosen storyteller.
- Ordering and scavenger are still cards.
- No slip sound. The catch is visual and social, not sonic.

## Highest-value improvement

A finale that feels larger than question 15. Taboo is now a memory; the last minute is not.

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

- Grade B: Daniel types a guess. Not “press OK when they finish.”
- A miss stays a guess. It does not auto-incorrect and kill the room’s chance.
- A hit auto-scores. Casa can steal from the sofa.

## What feels weak

- If there is no audio link, Daniel is guessing in the dark. The card says listen; it does not require video.
- Remote Jonah is still 1-in-3 if he cannot see the mime.

## Highest-value improvement

Keep Grade B. Do not add a three-choice crutch that turns taboo back into a quiz.

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

- One person talks. The rest lean in. Someone will say “viña.”
- The TV shows the forbidden words, not the target. The crowd is a referee.
- Lucía can shout the answer without knowing 1 Reyes 21.

## What feels weak

- Nobody on the guesser phone is named as “do not look at Marta” until the lede loads. It does name her now.

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

- Lucía: ¡ADIVINAD! / ¡Gritad! No form in the room.
- Abuela María: TÚ EXPLICAS, huge target, struck-through red words.
- Daniel: a real text guess at home.
- Presentador: two obvious verbs — they guessed / they said a word.

## What feels weak

- Explainer assignment is silent until the card appears. Fine for a family of four; awkward for eight on one team.

## Required before approval

- None.

---

## Evidence

Game QA / Red Team

## Verdict

PASS WITH NOTES

## Score impact

Reliability: 4/5

## What works

- Guess keys match Nabot / Naboth / “Es la historia de Nabot.”
- Wrong body does not write `incorrect`.
- Room guesser HTML has no type-in. Remote HTML does.
- Second submit on the same team is a no-op.
- Watch does not print the target.

## What feels weak

- `matches_guess?` is a substring. “nabot” inside a longer joke still scores. Acceptable for a family night.
- Explainer is `min_by(&:id)`, not a role column.

## Boring test

Without biblical graphics, this is still “don’t say the word.” Pass.

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

- YAML already sat this round in the mid-night laughter band. It now plays as talk, not a card.
- Explainer can read the secret during intro. The clock starts on open.

## What feels weak

- Round 15 is still a 25-point buzzer with thin celebration.

## Required before approval

- None.

---

## Night director

M4 approved. The night has a new memory: someone almost said Jezabel.

Quality: **64 / 75**. Iteration gate holds. **Major milestone 64 claimed** on an honest Tension move (4 → 5). Gameplay / Remote / Clarity / Reliability stay at 4+. No category below 3.

Do not raise Gameplay, Social, or Remote again on this slice. They did not get better; Tension did.

Next: a finale that feels larger than question 15 — podium, names, fanfare that the room can stand up for. Not another quiz. Not accounts.
