# Noche Live

A live biblical adventure party game for a *Noche de Hogar*. People in the room and people at home play the same night.

## Stack

Rails 8.1 · Hotwire · Turbo Streams · Stimulus · PostgreSQL · YAML games · Render

## Local

```text
rbenv local 3.3.12
bundle install
bin/rails db:setup
bin/dev
```

`db:setup` loads schema and **seeds**. Demo night:

```text
code: DEMO
Noche Live: /s/DEMO
```

Open `/`, or join on a phone with `DEMO`.

## Tests

```text
bin/rails test
```

Full suite must stay at **≥ 90%** line coverage (`coverage/index.html`). YAML fixtures live in `test/fixtures/`.

## Game memory

See `docs/GAME_VISION.md`, `.cursor/skills/noche-conseil/SKILL.md` (Conseil Noche, PRIORITY), `docs/GAME_QUALITY.md`, and `docs/AGENT_REVIEWS/`.
