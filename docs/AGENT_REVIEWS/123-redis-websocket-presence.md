# M123 — Redis/WebSocket realtime presence

Reviewed: 2026-08-29
Slice: live presence from socket subscription to every seat and hub counter
Tests: targeted Rails suites — 141 runs, 1,246 assertions, 0 failures; realtime system test — 1 run, 5 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: N/A — existing HUD markup and visual states preserved
Art: N/A — existing Celestial Light/Dark composition preserved
Hub theme: N/A — no theme or artwork change
Copy: N/A — no player-facing copy moved

## Feeling

Belonging and confidence: players should feel the room is alive now, while the host trusts the roster without waiting for a refresh.

## 1 — Game experience

The four seats now react to join/leave events over the existing WebSocket. A 20-second socket heartbeat renews a 45-second Redis TTL without HTTP or SQL. Multiple tabs and the same person moving between street and night are deduplicated. Disconnects update the live HUD; TTL is the mobile-network safety net. There is no 15-second page/frame reload and no database-backed cable poll every 100 ms.

## 2 — UI design

The visible HUD is unchanged, so the 2-second verbs and Celestial states remain intact. The improvement is temporal: LIVE counters and presence faces receive event-driven Turbo replacements instead of visibly aging between polls. Hidden tabs stop their heartbeat and recover on visibility or socket reconnection.

## 3 — Art direction

No new chrome or artwork. The technology disappears behind the existing stage, hub and presence compositions.

## Theme engine

N/A. The same hub and semantic theme remain.

## Four seats

| Seat | Verb tonight |
|---|---|
| Host | Read the room immediately and advance with confidence. |
| Chapel (controller) | Join, answer and remain visibly present without refreshing. |
| Remote | Stay visibly connected to the same room through mobile network changes. |
| TV / Twitch | Reflect roster changes without polling or leaving the spectacle. |

## Tension

No band or score curve changes. Removing stale presence and refresh waits protects the existing tension between host actions.

## Finale

No scoring or finale change.

## Languages

No new copy. Global pulse broadcasts remain locale-specific for es, pt-BR, en and fr.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 10 |
| Progression | 9 |
| Social | 10 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Presence is ephemeral Redis state, never a recurring PostgreSQL write.
- Action Cable uses Redis pub/sub instead of Solid Cable's 100 ms database poll.
- Signed per-scope tokens survive Turbo navigation without exposing session secrets.
- The heartbeat hot path is covered by an explicit zero-SQL assertion.

## What feels weak

- The Redis/Valkey service must be provisioned before this configuration can boot in production.

## Required before approval

- None in application code. Provision `nochelive-realtime` with the Blueprint before production boot.

## Evidence

The realtime system test receives the global live-count Turbo replacement without manually reloading its frame.

## Night director

Yes. Joins and disconnects no longer interrupt the room's rhythm or make the presenter doubt the screen.
