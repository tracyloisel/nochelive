# Architecture

Target stack:

```text
Rails 8.1 + Hotwire + Turbo Streams + Stimulus
Action Cable + Redis/Valkey pub/sub
PostgreSQL authoritative for durable domain state
Redis/Valkey for cache, presence, and ephemeral coordination
Solid Queue for durable background work
GCS + CDN for immutable assets and media
YAML game definitions in config/games/
Render web + worker + managed PostgreSQL + managed Key Value
```

The non-negotiable latency, query, realtime, and delivery boundaries are defined in [PERFORMANCE_ARCHITECTURE.md](PERFORMANCE_ARCHITECTURE.md).

The browser runtime, audio, motion, Stimulus, and migration boundaries are defined in
[FRONTEND_RUNTIME_ARCHITECTURE_PLAN.md](FRONTEND_RUNTIME_ARCHITECTURE_PLAN.md). The
implemented state, measured deltas and still-external release gates are recorded in
[FRONTEND_RUNTIME_EXECUTION_REPORT.md](FRONTEND_RUNTIME_EXECUTION_REPORT.md).

## Layers (required)

```text
app/controllers  HTTP: auth, params, one service.call, respond
app/services     Use cases: transactions, locks, scoring, broadcasts
app/models       Persistence: associations, validations, scopes, predicates
```

- One service class per use case, named as a verb, Zeitwerk path `app/services/nights/start.rb` → `Nights::Start`.
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

The browser never decides the Noche phase, quiz correctness, points, streaks,
team ranking, question completion or event deduplication. These values are
derived from PostgreSQL and the timestamps stored on `GameSession`.

Turbo Streams distribute projections and semantic event tiles. A normal GET on
`/s/:code` reconstructs the same Watch state without depending on Redis or on a
present browser. Redis/Valkey transports realtime updates but is not the source
of truth.

## Domain (intended)

```text
Ward → People, WardTeams, GameSessions
GameSession → Teams, Players, QuizRuns, LiveEvents
Person → PersonDevices, Players
WardTeam → Teams (immutable night snapshot)
Player → TeamMembership → Team
QuizRun → QuizAnswers
```

The ordered `quiz_pack_ids` sequence can contain any existing quiz pack. Noche
does not copy quiz content or own a parallel game engine: Live `QuizRun`s use the
normal `/jugar` engine with `game_session_id`, `player_id`, `team_id` and
`live_sequence_position` as context.

Session phases are time-derived:
`scheduled → lobby (T−30 min) → playing (T0) → finished (T+60 min)`.
There is no paused phase and no manual phase command.

## Campus des Écritures — défis asynchrones

Le moteur social sépare trois autorités qui ne doivent plus être confondues :

```text
DuelInvitation  passage social et accusés honnêtes
StreetDuel      relation active entre exactement deux personnes
QuizRun         performance universelle, indépendante de tout défi
```

- Une invitation `open` n'est pas un duel actif.
- Le claim verrouillé crée ou retrouve l'unique duel actif d'une paire non ordonnée.
- Aucun `pack_id` n'appartient à l'invitation ou au duel ; chaque personne choisit
  librement son parcours.
- Le premier `QuizRun` terminé et ouvert après l'acceptation alimente tous les duels
  actifs éligibles de la personne.
- Le fan-out verrouille chaque duel, écrit le score brut une seule fois et résout le
  résultat lorsque les deux côtés sont présents.
- Une revanche est une nouvelle invitation liée au duel résolu ; elle ne rejoue ni
  n'impose le pack précédent.
- Les jalons `share_handoff`, `human_opened`, `delivered`, `seen` et `claimed` sont
  monotones et ne sont jamais déduits les uns des autres.

Le cutover retire volontairement `quiz_runs.street_duel_id`, `street_duels.pack_id`,
le token brut du duel et les anciennes colonnes de mise/paroisse qui n'ont plus de
lecteur. Le contrat de non-régression vit dans
`test/performance/architecture_contract_test.rb` : aucun service, style, clé i18n ou
association du moteur mono-duel ne peut être réintroduit silencieusement.

## Broadcast scopes

`GameSession#locale_stream(locale)` isolates localized Live projections. One
answer can create several semantic events in a single transaction, but queues a
single broadcast job. The job computes one projection, then renders it for all
locales. No raw answer choice or private player payload is broadcast.

## Noche Live contract

- Admin/MCP creates persistent `WardTeam`s outside a Noche.
- Admin/MCP schedules one Noche with a ward, start date and ordered quiz list.
- `Nights::ScheduleLifecycle` queues lobby, start and close reconciliation.
- Before T−30, `/s/:code` accepts registrations and lists players/readings.
- During lobby and Live, a player chooses one snapshotted team; the choice locks
  after the first Live quiz run.
- During T0…T+60, `/s/:code` is Watch and late registration remains available.
- Team score is the raw sum of members' Live `QuizRun#score` values.
- The normal score screen links to the next quiz or back to Watch.
- T+60 expires open runs and closes the Noche idempotently.
