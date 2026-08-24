# M14 — Two-browser live buzz

Reviewed: 2026-08-24
Slice: Capybara system test, two phones + presenter through the first slam
Tests: `bundle exec rails test`

---

## Agent

Technical Reliability

## Verdict

PASS

## Score impact

Reliability: 4/5 (held)

## What works

- Chrome drives a real presenter who opens the night, then Lucía and Daniel slam the same visible Buzz.
- First and second place appear on the two phones. The TV names who buzzed first.
- Without Chrome the test skips. CI stays green.

## What feels weak

- Watch is a fresh visit, not a live Cable paint. Recovery after a dropped socket is still unproven.
- Four browsers make the file slow (~17s).

## Required before approval

- None.

---

## Game Director

The first buzz is now something two browsers did, not only two `open_session` POSTs. Do not raise Reliability for a test. Playtest is still the hole.
