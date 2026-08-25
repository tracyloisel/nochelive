# M1 — First Buzz Night review

Reviewed: 2026-08-24
Playable build: Rails 8.1 night with join, teams, presenter, spectator, race-safe buzzer, remote David tap, XP, chest.
Tests: `bundle exec rails test` — 14 runs, 70 assertions, 0 failures.
Gate: `.cursor/skills/noche-night/SKILL.md`. Evidence below is history of this slice, not a Cursor persona.

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Abrir / Cerrar the buzzer |
| Equipo en sala | Slam Buzz, wait for place |
| Jugador en casa | Same Buzz (A). David later is tap (B) |
| Espectador | Watch who slammed first (*Solo ver*) |

Later slices gave mime, statue, and taboo real verbs. This file stays the M1 record.

---

## Evidence

Gameplay Designer

## Verdict

PASS WITH NOTES

## Score impact

Gameplay: 4/5
Tension: 4/5
Replayability: 3/5

## What works

- The first verb is BUZZ, not a form submit. The button is the whole screen.
- Place is server-authoritative. The phone waits. That is the beat.
- David is a different verb (throw / tap), so round 3 is not quiz 3.

## What feels weak

- Hosted YAML rounds (mime, taboo, statue) still read as presenter-led cards.
- Three implemented types is enough for a first night, not for a second visit.

## Highest-value improvement

Give mime/statue a real remote verb before claiming a full 15-round night.

## Required before approval

- None for M1. Do not ship five seated questions in a row.

---

## Evidence

Progression Designer

## Verdict

PASS

## Score impact

Progression: 4/5

## What works

- Correct answer becomes XP, rank, streak, and a visible bar toward Explorador.
- After the first score the player is not the same as in the lobby.

## What feels weak

- Most first nights will only reach Novicio / Explorador.
- Roles (Rey, Profeta) are still design-only.

## Highest-value improvement

Show a rank-up beat when the bar fills, not only a label change.

## Required before approval

- None.

---

## Evidence

Reward & Loot Designer

## Verdict

PASS WITH NOTES

## Score impact

Reward / surprise: 4/5

## What works

- 20 XP unlocks Cofre de Salomón. Opening is a tap + shake + named loot.
- Corona, Fuego, Escudo, Sabiduría are free and family-safe.
- Double-score crown is a real next-round power.

## What feels weak

- Random among four rewards is thin. No collection yet.

## Highest-value improvement

A second chest at 100 XP with a different illustration.

## Required before approval

- None. Do not add purchases.

---

## Evidence

Remote Play Designer

## Verdict

PASS

## Score impact

Remote: 4/5

## What works

- Join asks "En la sala / En casa."
- Salomón buzzer is Grade A: same giant button, same race, same place.
- David is Grade B: hold/tap sling with a power bar, not "press OK."
- Spectator is a chosen seat, not the remote default.

## What feels weak

- Hosted physical rounds without a strong variant still lean C/D if the presenter jumps ahead in the YAML.

## Highest-value improvement

Presenter console should warn when a round is Grade D for remote players.

## Required before approval

- None for the first three playable rounds.

---

## Evidence

Party & Social Designer

## Verdict

PASS

## Score impact

Social: 4/5

## What works

- Spectator shouts the first team name.
- First place gets a crown the room can see.
- Physical David tells the room to put the phone down.

## What feels weak

- No team chant or crowd prediction yet.

## Highest-value improvement

A 3-second "¿quién va a buzzear?" crowd prompt on intro.

## Required before approval

- None.

---

## Evidence

Art Director

## Verdict

PASS WITH NOTES

## Score impact

Visual identity: 4/5

## What works

- Navy, gold, parchment, original SVG marks. Not a SaaS dashboard.
- Solomon, David, Elijah, Daniel, and emblems exist as local art.

## What feels weak

- Marks are still simple. They are not finished illustrations.
- Type is system Palatino, not a custom display face.

## Highest-value improvement

One painted David vs Goliath background for that round only.

## Required before approval

- None. Do not hotlink stock biblical art.

---

## Evidence

VFX / Motion Designer

## Verdict

PASS WITH NOTES

## Score impact

VFX: 4/5

## What works

- Intensity 4 on first buzz: gold flash, sparks, crown.
- Score flies on reveal. Chest shakes. Reduced motion is honored.

## What feels weak

- Level-up and finale still share the same gold flash.

## Highest-value improvement

A distinct intensity-5 finale (confetti, not another spark).

## Required before approval

- None.

---

## Evidence

Sound Designer

## Verdict

PASS WITH NOTES

## Score impact

Sound: 3/5

## What works

- Named cues (`buzzer_hit`, `correct_gold`, `chest`) live in one controller.
- Mute is global. Autoplay failure is silent. No loops.

## What feels weak

- Oscillator beeps are semantic, not delightful. They will tire Carlos.

## Highest-value improvement

Replace the four combat cues with short original recordings. Keep the names.

## Required before approval

- None. Sound is not required to understand the game.

---

## Evidence

Pacing Director

## Verdict

PASS

## Score impact

Pacing: 4/5

## What works

- YAML is a 15-round curve. The team screen labels Descubrimiento → Gran final.
- Round 1 is easy buzzer. Round 3 is body/skill. Finale is 25 points.

## What feels weak

- A presenter can skip straight to the finale. The curve is not enforced.

## Highest-value improvement

Lock the first three rounds as the recommended opening set.

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

- Lucía: can smash Buzz and tap David.
- Carlos: gets ranking, streak, and a reason to care.
- Abuela María: one huge button, short Spanish, no hover.
- Daniel: same buzzer; David is a skill bar.
- Presentador: Abrir / Cerrar / Revelar / Siguiente.

## What feels weak

- Presenter console still has several buttons at once.
- "Buzz" is English on a Spanish night.

## Highest-value improvement

Label the button "¡YA!" or "¡AHORA!" for Abuela María.

## Required before approval

- None for M1. Refresh must keep the same player (tested).

---

## Evidence

Game QA / Red Team

## Verdict

PASS WITH NOTES

## Score impact

Reliability: 4/5

## What works

- Concurrent buzz: unique places, one first, one buzz per team.
- Duplicate tap is idempotent. Presenter URL without token is rejected.
- Join is case-insensitive. Refresh does not clone the player.
- GET reconstructs state.

## Boring test

If we strip the biblical graphics, the first round is still a race, not a questionnaire. Pass.

## What feels weak

- System tests do not yet drive two live browsers through Turbo.
- Rapid tap trusts tap volume; a scripted client could finish instantly.

## Highest-value improvement

A Capybara two-session buzz test once Chrome is wired.

## Required before approval

- None. Do not claim live WebSocket recovery is proven in CI.

---

## Night director synthesis

Would I play another round? Yes — I want to see if we buzz first again, and whether the chest is a crown.

Quality gate: see `docs/GAME_QUALITY.md`.
