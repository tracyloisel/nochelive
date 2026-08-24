# Architecture

Target stack:

```text
Rails 8.1 + Hotwire + Turbo Streams + Stimulus
Action Cable / Solid Cable
PostgreSQL authoritative
YAML game definitions in config/games/
Render web service + managed PostgreSQL
```

## Layers (required)

```text
app/controllers  HTTP: auth, params, one service.call, respond
app/services     Use cases: transactions, locks, scoring, broadcasts
app/models       Persistence: associations, validations, scopes, predicates
```

- One service class per use case, named as a verb, Zeitwerk path `app/services/buzzes/accept.rb` → `Buzzes::Accept`.
- Public API is `.call(**kwargs)`.
- Controllers and ActiveRecord models must not orchestrate use cases.
- POROs such as scoring or broadcasting do **not** live in `app/models`.
- When touching a use case still on a model/controller, extract it into a service in the same change.

## Tests, fixtures, seeds, coverage (required)

```text
test/                 Minitest — every class/action has tests
test/fixtures/*.yml   YAML fixtures for every ActiveRecord model
db/seeds.rb           Idempotent playable DEMO night
SimpleCov             Full suite must stay ≥ 90% line coverage of app/
```

- A slice without tests is not done.
- A new model without a fixture file is not done.
- Do not add RSpec. Do not add FactoryBot as a substitute for fixtures.
- `bin/rails test` (full) and CI fail under 90%. Do not lower the threshold.

## Authority

The browser never decides:

- who buzzed first
- whether a round is open
- scores
- correct answers
- current round
- winners

Turbo Streams distribute server state. A normal GET must reconstruct the current night.

## Domain (intended)

```text
Ward → People, WardTeams, GameSessions
GameSession → Teams, Players, RoundRuns, ScoreEvents
Person → PersonDevices, Players
WardTeam → Teams (night clones)
Player → TeamMembership → Team
RoundRun → Buzzes, Answers
```

Round phases: `pending → intro → open → locked → answering → revealed → completed`

Session states: `lobby → playing → paused → finished`

## Broadcast scopes

```text
game_session
game_session:presenter
game_session:spectators
game_session:team:<id>
```

Private team answers never go to other teams.

## First slice contract

SLICE: First Buzz Night

DONE WHEN:

- presenter creates a session and keeps a secret console
- players join by code, name, and team
- spectators watch without acting
- presenter opens a buzzer round
- phones update without navigation
- one tap locks a team buzz
- PostgreSQL allocates unique positions
- first place is an event (visual + sound + rank)
- presenter can mark correct/incorrect and scores move
- refresh/rejoin does not clone the player
- remote players use the same buzzer (Grade A)
