# 058 — Rama liga from the chapel card

Reviewed: 2026-08-26
Slice: Public `/ramas/:code` consults **this** ward’s street liga. Marble tile (top 3 or honest empty) → `/ramas/:code/liga`. Not a live night.
Tests: `bin/rails test` — 695 runs, 7707 assertions, 0 failures. Slice: ward profile, street liga, hub league strip, locale files.
Gate: leftover hall + street liga — `.cursor/skills/noche-ui/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr

## Four seats

N/A. Chapel card and street ranking. Live night seats unchanged.

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage |
| Equipo en sala | Unchanged Buzz |
| Jugador en casa | Unchanged remote A/B |
| Espectador | Unchanged *Solo ver* |

## Tension

N/A.

## Finale

Unchanged.

## Languages

noche-i18n: **PASS**
- es: *Liga de la rama* / *Nadie ha jugado todavía en esta rama.* / *Volver a la rama* — tú street, not CMS *ver clasificación* as the only door
- pt-BR: *Liga da ala* / *nesta ala* / *Voltar à ala* — not ramo
- fr: *Ligue de la paroisse* / *dans cette paroisse* / *Retour à la paroisse* — not *branche*
- en: *Ward league* / *Nobody in this ward has played yet.* / *Back to the ward* — not *ward unit* or *see full standings* as the only hit

## Verdict

PASS

## What works

- Fiche stays a marble hall (no ivory sheet). **One** gold CTA (Entrar or Abrir la noche). Liga is a hub-language tile: ink title, gold hairline as metal, crown scores as metal, faces when someone has played.
- Honest empty: podium mark + *nadie ha jugado todavía en esta rama*, still tappable. Stats line is nights · players.
- Nested `/ramas/:code/liga` is that chapel’s board (kicker = ward name, not a second stacked headline). Search stays on the nested URL. Visit ≠ join: no *you* row, no duel inbox. Back is *Volver a la rama*.
- Hub `/liga` and the hub strip still use `current_ward`. `empty_ok` is only on the chapel card.

## What feels weak

- No mockup PNG for the rama card liga — the tile copies hub LIGA on the hall leftover.
- A quiet chapel with 0 players still grows a tile before *Entrar en una rama*. Honest, a little tall.

## Required before approval

- None.

## Evidence

UI: ink words, gold metal (arch, medal, crown, podium mark). No gold type on cream. Copy: rama / ala / paroisse / ward.

## Night director

Would I tap the liga on a chapel card and know whose house I’m reading? Yes. Friday four-seat is unchanged.
