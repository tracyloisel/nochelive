# Decisions

## ADR-001 — One automatic Noche lifecycle

A Noche is scheduled with a ward, a start time and a non-empty ordered list of
existing quiz packs. Its phases are derived from timestamps: registration,
lobby at T−30 minutes, Live at T0 and closed at T+60 minutes. No actor can pause,
open, reveal or advance the shared night.

## ADR-002 — Reuse the normal quiz engine

Live play is a normal `QuizRun` with Noche, player, team and sequence context.
Noche owns no question renderer, answer grader or separate quiz theme. The
current quiz pack supplies its own illustration and artwork manifest.

## ADR-003 — Persistent teams, immutable night snapshots

The admin MCP creates `WardTeam`s outside a Noche. Starting a Noche snapshots
those records into session `Team`s. Players may select one of the snapshots in
lobby or Live, and that choice locks after their first Live run. Team score is
the raw sum of member Live run scores.

## ADR-004 — Canonical URL becomes Watch

`/s/:code` is the only public Noche destination. It shows registration and
readings before lobby, then automatically becomes Watch. Watch remains open to
late registration and displays team ranking, per-question completion and
semantic realtime events. TV QR codes point to this same URL.

## ADR-005 — Realtime is a projection, not game authority

PostgreSQL is authoritative. Answer transactions deduplicate semantic events;
one background job computes a projection and broadcasts localized Turbo Stream
updates. A GET can always reconstruct Watch without prior broadcasts.

## ADR-006 — Admin mutation belongs to the MCP/API

The admin contract creates persistent teams, schedules/edits a future Noche and
closes a Noche early when explicitly requested. There is no presenter token,
console, custom poster, broadcast delay or manual round command.

## ADR-007 — Use cases live in `app/services`

Controllers validate HTTP input and delegate. `Nights::Start`,
`Nights::Configure`, `Nights::Reconcile`, `Nights::Close`,
`Nights::QuizSequence`, `Nights::Events` and `Nights::Broadcast` own their
transactions and orchestration. Active Record models retain associations,
validations, scopes and predicates.

## ADR-008 — Rails testing contract

Minitest, YAML fixtures and idempotent development data remain the project
standard. The full suite enforces its existing SimpleCov floor. Noche changes
must cover lifecycle boundaries, idempotence, late join, team locking, raw score
aggregation, per-question completion and admin authorization.

## ADR-009 — Single PostgreSQL production authority

Production uses the primary PostgreSQL database for domain state and durable
jobs. Redis/Valkey may transport Action Cable updates and ephemeral presence but
never decides a Noche phase, score or winner.
