# Current state

Inspected 30 August 2026 after the automatic Noche Live cutover.

## Working

- Persistent ward teams created by the admin MCP and snapshotted into each Noche.
- Scheduled registration, T−30 lobby, T0 Live and automatic T+60 close.
- Ordered lists of existing quiz packs played through the normal `/jugar` engine.
- Late registration and team selection from the canonical `/s/:code` Watch URL.
- Realtime semantic challenge tiles, team score sums and per-question completion.
- Normal final score screen with next-quiz and return-to-Watch actions.
- Responsive Watch, registration and team selection surfaces.

## Removed

The hosted round engine, presenter console, public companion, manual phase
commands, buzz/action models, custom posters and historical compatibility paths
are not part of the application anymore.

## Remaining release gate

Run an in-person multi-device playtest and production-load observation; neither
requires restoring legacy concepts.
