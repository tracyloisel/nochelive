import test from "node:test"
import assert from "node:assert/strict"
import { countdownProjection, nextSecondDelay } from "../../../app/javascript/runtime/motion/countdown_projection.js"

test("countdown projects discrete seconds and ask zones from absolute time", () => {
  const normal = countdownProjection({ endAt: 10_000, now: 5_500, durationSeconds: 10, ask: true })
  assert.equal(normal.seconds, 5)
  assert.equal(normal.warn, false)
  const warn = countdownProjection({ endAt: 10_000, now: 6_500, durationSeconds: 10, ask: true })
  assert.equal(warn.seconds, 4)
  assert.equal(warn.warn, true)
  const hot = countdownProjection({ endAt: 10_000, now: 8_500, durationSeconds: 10, ask: true })
  assert.equal(hot.seconds, 2)
  assert.equal(hot.hot, true)
  assert.equal(nextSecondDelay(3_492), 500)
})

test("countdown duration is stable regardless of display refresh rate", () => {
  for (const hz of [60, 90, 120]) {
    const frame = 1_000 / hz
    const halfway = countdownProjection({ endAt: 10_000, now: frame * Math.round(5_000 / frame), durationSeconds: 10, ask: true })
    assert.ok(Math.abs(halfway.ratio - 0.5) < 0.002, `${hz} Hz drifted`)
  }
})
