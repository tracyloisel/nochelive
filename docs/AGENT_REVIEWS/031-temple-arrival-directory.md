# 031 — Temple arrival + worldwide rama directory

Reviewed: 2026-08-26
Slice: first visit on `/` is a marble-hall arrival then live search (country → estaca → rama). Listed mosaic from the public Meetinghouse Locator. Night seats unchanged.
Tests: `bin/rails test`
Gate: `.cursor/skills/noche-night/SKILL.md` — street, not a Friday night
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage. |
| Equipo en sala | Unchanged Buzz. |
| Jugador en casa | Unchanged remote A/B. Street first visit: **tú** — find the rama, then play. |
| Espectador | Unchanged *Solo ver*. |

## Tension

N/A (street welcome, not a live round). First beat is welcome, not a CMS directory.

## Finale

Unchanged. Street pack ceremony still uses `marble-hall-victory.jpg`; arrival uses `marble-hall.jpg`.

## Languages

noche-i18n: **PASS**
- es: *¿De qué rama eres?* / *Búscala y entra a jugar con los tuyos.* — invitation, not *guardar tu progreso*.
- pt-BR: *Qual é a sua ala?* / *Encontre a sua e jogue com a família.* — *ala*, not ramo.
- fr: *Ta paroisse t’attend* / *Trouve-la et viens jouer avec les tiens.* — tu for one phone, no SMS slang, thin space on *Où est ta paroisse ?*.
- en: *Where’s home?* / *Find yours and come play with family.* — ward/meetinghouse, not *ward unit*.

## Verdict

PASS WITH NOTES — hall ≠ victory, one cream caption, tap-to-skip, no country dump on empty, import never in CI, empty league stays honest.

## What works

- Arrival: full-column hall, 1.4s then ivory `hall-sheet`, skip on tap or `prefers-reduced-motion`. `round_open` only if Web Audio is already unlocked.
- Picker: featured Benidorm with a star (not a gold CTA), live `#ward_q`, *O por país* then estaca.
- `Wards::ParseLocator` + `Wards::SyncDirectory` + `noche:import_wards`. Self-serve Create stays unlisted. RAMA merged, code/token/name kept.
- ADR-015 amends 013/014 for the listed import only.

## What feels weak

- Locator names longer than 120 characters are truncated.
- Country browse uses locator `country_name` when an i18n key is missing (not 150 × 4 locale rows).
- Host claim of imported presenter tokens is later.

## Required before approval

- None for this slice. World dump is not the join path (see 034).

## Night director

Would Abuela and Lucía find Benidorm without a keyboard? Yes — star first. Can a family outside Spain join a listed rama after import? Yes. Do we dump 150 countries under the field? No.
