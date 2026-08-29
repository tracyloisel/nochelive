import assert from "node:assert/strict"
import test from "node:test"

import { streetCueGain, streetDuelRaceTimeline, streetQuizTimeline } from "../../../app/javascript/runtime/street/quiz_timeline.js"

test("Street result reveals truth, feedback, reward, then actions in one bounded sequence", () => {
  const result = streetQuizTimeline().result

  assert.ok(result.feedback < result.bars)
  assert.ok(result.bars < result.reward)
  assert.ok(result.reward + 900 < result.actions)
})

test("Street ceremony separates its single fanfare from reward, chest, and content", () => {
  const ceremony = streetQuizTimeline().ceremony

  assert.ok(ceremony.fanfare < ceremony.reward)
  assert.ok(ceremony.reward < ceremony.chest)
  assert.ok(ceremony.chest < ceremony.chestOpen)
  assert.ok(ceremony.chestOpen < ceremony.content)
  assert.ok(ceremony.content < ceremony.done)
})

test("reduced motion reaches every final phase without decorative delay", () => {
  const reduced = streetQuizTimeline({ reduced: true })

  Object.values(reduced).forEach((sequence) => {
    assert.deepEqual([ ...new Set(Object.values(sequence)) ], [ 0 ])
  })
})

test("the friendly race reads once, gives live events more room, then compacts", () => {
  const intro = streetDuelRaceTimeline()
  const event = streetDuelRaceTimeline({ event: true })

  assert.ok(intro.reveal < intro.compact)
  assert.ok(event.reveal < event.compact)
  assert.ok(event.compact > intro.compact)
  assert.deepEqual(streetDuelRaceTimeline({ reduced: true }), { reveal: 0, compact: 0 })
})

test("the miss cue is intentionally quieter than the success cue", () => {
  assert.ok(streetCueGain("street_wrong_soft") < streetCueGain("correct_gold"))
  assert.ok(streetCueGain("fire_whoosh") < streetCueGain("correct_gold"))
  assert.ok(streetCueGain("street_royal_fanfare") < 0.5)
})
