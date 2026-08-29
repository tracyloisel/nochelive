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

Turbo Streams distribute server state. A normal GET must reconstruct durable night state. Ephemeral presence is reconstructed from Redis TTL entries and may degrade to offline without writing to PostgreSQL.

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
