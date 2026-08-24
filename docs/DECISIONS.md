# Decisions

## ADR-001 — Empty repo is a product fact

Decision:
Score the shipped product as absent. Do not pretend YAML in a brief is a game.

Why:
The game-quality loop must review what a family can play tonight.

Consequences:
M0 review scores 0/75. The first build must be a playable night, not a model inventory.

## ADR-002 — First slice is the buzz moment, not join-only

Decision:
M1 includes create/join/teams AND the first authoritative buzz + score payoff.

Why:
Join-by-code is software. The first gold lock-in is the game. Shipping join without payoff would fail the player-first test.

Rejected:
Building every model and every round type first.

## ADR-003 — Session-local progression only (v1)

Decision:
XP, ranks, streaks, and chests live on the night. No user accounts required.

Why:
A Noche de Hogar is a single evening. Accounts would slow Abuela María and Lucía.

Superseded by ADR-012 for persistent fichas. Night XP / Rey / coffre remain session-local.

## ADR-012 — Rama fichas, not passwords

Decision:
A `Ward` (rama) owns `Person` fichas and `WardTeam` season records. A night still has its own `Player` / `Team` / XP. Returning players pick a ficha with a chosen avatar. Homonyms (Carmen, Pilar) use apellido when needed. The memorable year is `favorite_year` — « ¿Cuál es tu año favorito? Puedes usar el año en que naciste. » It is not a date of birth, PIN, or age. Guests may play « Solo esta noche » with no ficha. Season XP is applied once at `Nights::Finish` using 4× night rank thresholds.

Why:
Several ramas will play. First names do not identify anyone in Spain. Church Account SSO is not available to third parties. Email/password would block children.

Rejected:
Unique given names. 4-digit PIN. Storing `birth_year` / inferring age. Merging night XP into the live buzz bar. FamilySearch/Church OAuth.

## ADR-007 — Pose hold is server-clamped, not camera-based

Decision:
Remote statue sends `held_ms`. The server clamps and awards once at 8 seconds. The room puts the phone down.

Why:
A family night needs a body verb at home without requiring a camera pipeline.

Rejected:
"Press OK when the room is finished."

## ADR-005 — `Buzz` inflection and `night` routes

Decision:
Irregular inflection `buzz` / `buzzes`. Player routes use `/s/:session_code` named `night_*` so they do not collide with the Rack `session`.

Why:
Rails otherwise looks for `buzzs` / `Buzze`. `as: :session` hid path helpers from controllers.

## ADR-006 — Single PostgreSQL on Render

Decision:
Production uses one `DATABASE_URL`. Solid Cable tables live on primary. Cache and jobs stay in-process.

Why:
A family night does not need three extra databases for the MVP.

## ADR-009 — Meetinghouse rooms, never a temple

Decision:
Challenge media (OpenRouter stills/clips) depicts an LDS meetinghouse. Seated rounds use the chapel pews. Movement rounds use the cultural hall. Temple interiors are forbidden.

Why:
A Noche de Hogar with foam balls and a harp hunt happens in the cultural hall. Generating a temple would be inaccurate and disrespectful.

Rejected:
Photoreal close-ups of young children, Catholic chapel dressing, readable UI in the frame.

## ADR-008 — The ending is a ceremony

Decision:
When a night is `finished`, play / watch / presenter all render the same stand-up ceremony. Leftover round controls and score adjusters hide.

Why:
A leaderboard refresh is software. Standing up and reading a name is the game.

Rejected:
Leaving the presenter on “Abrir” for the next unused round after Cerrar noche.

## ADR-004 — Synthesized SFX, original SVG

Decision:
Sound uses named Web Audio cues. Art uses original SVG marks. No hotlinked or copyrighted assets.

Why:
Family-safe, deployable, muteable, and ours.

## ADR-010 — Use cases live in `app/services`

Decision:
Every player or presenter action is a service object (`Buzzes::Accept.call`, `Answers::Submit.call`). Controllers are HTTP only. ActiveRecord models persist; they do not orchestrate transactions, scoring, or broadcasts.

Why:
Fat models and controller orchestration are not Rails simplicity. A service per use case is the maintainable default. "Prefer fewer abstractions" does not authorize skipping this layer.

Rejected:
POROs in `app/models` (`ScoreApplier`, `NightBroadcaster`). `Model.accept!` / `submit!` / `tap!` class methods that lock, write related rows, score, and broadcast. God objects (`GameEngine`).

## ADR-011 — Tests, fixtures, seeds, 90% coverage

Decision:
Minitest under `test/`. YAML fixtures for every ActiveRecord model. `db/seeds.rb` creates a playable DEMO night. SimpleCov fails the full suite and CI below 90% line coverage of `app/`.

Why:
A new app with logic only in controllers/models and no fixtures/seeds/coverage bar cannot be maintained. Specs ship in the same change as the behavior.

Rejected:
FactoryBot instead of fixtures. RSpec alongside Minitest. Lowering the coverage threshold. Empty `db/seeds.rb`.
