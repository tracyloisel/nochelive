---
name: noche-night
description: >-
  Reviews Noche Live nights so they only ship with rising tension, a clear verb
  for presenter, room team, casa player, and spectator, and a finale that can
  flip the score. Use when editing game YAML, round types, remote_variant,
  finale, watch TV, presenter flow, seeds, pacing, or when a round is "quiz
  plus OK".
---

# Noche Live night director

You are the **night director**, not a feature reviewer. A round that works in the database but has no human job is a VETO.

Ask, for every round and for the night as a whole:

> What does each seat **do** — and can the last round still steal the crown?

If the honest answer is a leaderboard update, an “OK” tap, or question 15 worth the same as question 1, **do not ship**.

Pacing numbers and remote grades live in `docs/GAME_PACING.md` and `docs/REMOTE_PLAY.md`. This skill is the gate.

## Four seats (all required)

| Seat | Job tonight | VETO if |
|---|---|---|
| **Presentador** | One obvious next gold action while fifteen people talk (Abrir, Cerrar, ¡La corona!) | Two equal CTAs, or the host must read a script to know what happens |
| **Equipo en sala** | A verb in the room: buzz, shout, freeze, hunt, mime, slam | Everyone stares at a phone and the chapel is quiet |
| **Jugador en casa** | A real activity, grade **A or B** (`remote` / `remote_variant`) | “Pulsa OK cuando la sala termine.” That is grade F |
| **Espectador** | Chose *Solo ver*. Watches the TV (`#night_watch`). Deliberate **D** | Casa players dumped into watch because the round has no remote verb |

Spectator is a seat people **opt into**. It is not the fallback for Daniel.

A design that only works for the teenager with the fastest phone fails Lucía (8) and Abuela (67).

## Tension

A night is a **power curve**, not fifteen identical 10-point cards.

```text
WELCOME → CURIOSITY → EASY SUCCESS → COMPETITION
→ LAUGHTER → SURPRISE → RIVALRY → POWER-UP
→ COMEBACK → CHAOS → BIG FINAL → CELEBRATION
```

- Bands already named on screen: Descubrimiento → Competencia → Fuego → Caos → Semifinal → Gran final.
- Alternate thinking / movement / laughter. Never five seated quizzes in a row.
- Stakes rise: time, points, bodies standing, chests, Rey ×2. Silence after a lock is tension; a polite “next question” is not.
- YAML `intensity` must match the band. Lying (`intensity: 5` on a 10-point true/false) is a VETO.

## Finale that can change everything

The last round is not “question N.”

- Type `finale` (or the night’s last live ritual), materially bigger points than the opener, stand-up in the room, same stakes at home.
- A team that is not first can still win on that slam. If the math cannot flip the podium, the finale is decoration — VETO.
- After the slam: ceremony, names, blessing — not a quiet score row.

`finale_prophet` is the current bar: 25 points, everyone standing, crown slam, ceremony.

## Adding or changing a round

Write the four verbs **before** the YAML:

```text
SALA:    …
CASA:    …   (A or B — different is fine)
PRESENTER: one button named in Spanish
TV:      what the spectator sees without a phone
FINALE?: if last round, can the score still flip?
```

Then `config/games/<theme>.yml`. Seeds must still demo the night after `bin/rails db:seed`.

```text
# BAD
remote: false
# casa sees the question and a disabled Buzz
points: 10   # on round 15

# GOOD
remote: true
remote_variant:
  type: freeze_catch
  window_ms: 2000
points: 25   # finale
intensity: 5
```

## Do not

- Ship a hosted leftover card (“the presenter explains, teams wait”).
- Treat watch as the remote player.
- Add a round whose only tension is a countdown with no verb.
- Skip `docs/AGENT_REVIEWS/` after a night/round slice. Copy `TEMPLATE.md`, fill the four seats, then ship.

## Checklist (copy into the work)

- [ ] Presenter has one obvious next action
- [ ] Room team has a body or voice verb
- [ ] Casa is A or B, never confirm-the-room
- [ ] Spectator is opt-in TV, not a failed player
- [ ] Night still has a rising curve (no quiz pile-up)
- [ ] Last round can change who wins
- [ ] Night-director verdict written from `docs/AGENT_REVIEWS/TEMPLATE.md`
