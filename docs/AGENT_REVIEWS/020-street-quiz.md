# M20 — Home street quiz

Reviewed: 2026-08-25
Slice: street catalog on `/` (17 packs × 10), paper nights on `/noches`, named SFX on `#street_quiz`
Tests: `bin/rails test` — see parent run
Gate: `.cursor/skills/noche-night/SKILL.md` (street ≠ Friday)
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Four seats

The Friday night is unchanged. This slice is the **street**: one visitor, tú, no presentador / sala / casa / TV seats.

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage. Street has no host. |
| Equipo en sala | Unchanged body/voice once inside a night. Street is not the chapel. |
| Jugador en casa | Unchanged remote A/B once inside a night. |
| Espectador | Unchanged *Solo ver* on the TV. Street mute is Sonido, not a dumped casa seat. |
| **Street (tú)** | Choose a grade, read the quiet scripture, tap **Siguiente**. Pack 10 can still beat the street average. |

## Tension

Street curve is timer + points + still + SFX, not Descubrimiento → Gran final. Q1–3 untimed 5 pts; Q4–6 20s 8 pts; Q7–9 15s; Q10 25 pts `round_start`. Intensity non-decreasing in YAML only.

## Finale

Friday `finale_prophet` untouched. Street slam is pack Q10, then an honest hero (or *Eres el primero* if n < 2). No ceremony skin.

## Languages

Copy read in **es**, **pt-BR**, **en**, **fr**; `quiz.*` + `home.nights` + `quizzes.*` packs.

noche-i18n: PASS WITH NOTES
- es: *Siguiente*, *Así respondió la gente*, *Eres el primero*, *Leer en las Escrituras*
- pt-BR: *Próxima*, *Você é o primeiro* (not tu calque)
- fr: *Suivant*, *Tu es le premier* (street tú)
- en: *Next*, *You're the first*

## Verdict

PASS WITH NOTES

## What works

- YAML and engine are separate from `GameSession` / `Rounds::Forward`.
- One SFX trigger on `#street_quiz`. Mute visible. `/noches` paper.
- Scripture quiet-link after the tap, Study URLs for bible / BoM / D&A / Pearl / JS-H.

## What feels weak

- Ten seated QCM, zero laugh / body: assumed for the street.
- OpenRouter credits ran out after 21 Flux stills; the other 149 are unique graded crops of those 21 so tests have JPGs. Re-run `ruby script/generate_quiz_media.rb --all` when credits return (existing Flux files are skipped).

## Required before approval

- None for the engine. Re-generate stills when the image wallet is funded.

## Evidence (optional)

Street seat, not a fourth night hat.

## Night director

Would I play another pack? Yes, as a trailer on the way to Friday. Quality: street ≠ night.
