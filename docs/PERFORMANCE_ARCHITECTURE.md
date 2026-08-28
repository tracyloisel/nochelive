# Performance architecture

Status: required. Speed is Noche Live's first product feature.

This document is the engineering contract for new code and for every hot path that is touched. Performance is decided during architecture, measured during implementation, and protected by tests after release.

## Technology boundaries

| Need | Technology | Contract |
| --- | --- | --- |
| Durable business state | PostgreSQL | Transactional source of truth; indexed from measured access patterns |
| Ephemeral state | Redis/Valkey | Namespaced keys, bounded cardinality, TTL, no PostgreSQL fallback |
| Live fan-out | Action Cable + Redis, Turbo Streams | Push state changes; reconnect and duplicate delivery are safe |
| Durable asynchronous work | Solid Queue + worker | Idempotent jobs, retries, bounded batches, outside web requests |
| Reconstructible cache | Redis/Valkey | Cache-aside, explicit invalidation owner, TTL and stampede control |
| Static media and compiled assets | GCS + CDN/edge cache | Immutable URLs and long cache lifetime; Puma is not the production origin |

PostgreSQL is authoritative only for durable domain state. Presence, heartbeats, locks with a short lifetime, rate limits, and cached projections do not belong in relational tables.

## Backend hot-path contract

- No SQL query inside a collection loop. Every list and render service has a bounded query count covered by a test.
- Fetch only used data. Prefer `select`, `pluck`, `exists?`, SQL aggregates, and batched writes over loading Active Record object graphs.
- `preload` is for associations consumed after the primary query. `eager_load` or explicit joins are reserved for filtering or ordering in SQL. Speculative eager loading is a defect.
- Every new or changed hot query is reviewed with production-shaped cardinality and `EXPLAIN (ANALYZE, BUFFERS)`. An index must correspond to a real predicate, join, or ordering pattern.
- Request transactions stay short. Network calls, media processing, notifications, and fan-out do not run inside them.
- Cache misses may read PostgreSQL once; concurrent misses must not stampede it. Cache failure degrades predictably and never corrupts durable state.
- All external calls have connect/read timeouts. Noncritical calls are asynchronous or omitted from the render path.

## Realtime contract

- An idle page sends no recurring HTTP request. Visual clocks and animation timers are allowed when they remain local.
- Presence uses one Action Cable subscription per browser context and Redis TTL heartbeats. A heartbeat performs zero SQL.
- The server publishes state changes. Clients do not poll to discover them.
- Disconnects, reconnects, duplicate messages, multiple tabs, and multiple Puma processes are normal operating conditions.
- Redis unavailability means realtime presence is temporarily unavailable. It must not trigger write/read loops in PostgreSQL.

## Frontend and time-to-render contract

- The first response contains the useful screen; noncritical controllers, artwork, sheets, and sounds load lazily.
- HTML delivery is streamable. Middleware must not buffer a full response to perform cosmetic rewriting.
- Initial CSS/JS and above-the-fold media have an explicit per-screen byte budget. New assets ship in modern compressed formats with dimensions and lazy decoding where appropriate.
- Production asset URLs point to GCS/CDN and use long-lived immutable caching. Application workers serve dynamic HTML/API/WebSocket traffic.
- Track p75 LCP ≤ 2.5 s, INP ≤ 200 ms, and CLS ≤ 0.1 on supported mobile devices. Backend endpoints also receive a route-specific p95 latency and SQL-query budget.

## Evidence and release gate

Each hot-path change records:

1. Baseline and after-change latency, SQL count/time, allocations or payload bytes as relevant.
2. The expected cardinality and failure mode.
3. A regression test for the budget or architecture boundary.
4. Production telemetry to verify the result after deployment.

An exception requires measured evidence, an owner, and a removal date. “It was easier with the existing database/request” is not an exception.
