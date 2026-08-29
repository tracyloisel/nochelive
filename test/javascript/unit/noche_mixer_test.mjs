import assert from "node:assert/strict"
import test from "node:test"

import { FakeAudioBackend } from "../../../app/javascript/platform/audio/fake_backend.js"
import { NocheMixer } from "../../../app/javascript/runtime/audio/noche_mixer.js"

test("mixer unlocks before preloading only probable context cues", async () => {
  const backend = new FakeAudioBackend()
  const mixer = new NocheMixer({
    backend,
    catalog: { round_open: "/round.mp3", correct_gold: "/correct.mp3" },
    context: { cues: [ "round_open", "correct_gold" ], probable: [ "round_open" ], bed: null }
  })

  assert.deepEqual(backend.preload([ "round_open" ]), [])
  await mixer.unlock()
  assert.deepEqual(backend.calls.slice(-2), [[ "unlock" ], [ "preload", [ "round_open" ] ]])
})

test("mixer rejects out-of-context cues and deduplicates retriggers", () => {
  let now = 1000
  const backend = new FakeAudioBackend()
  const mixer = new NocheMixer({
    backend,
    catalog: { correct_gold: "/correct.mp3" },
    context: { cues: [ "correct_gold" ], probable: [], bed: null },
    now: () => now
  })

  assert.equal(mixer.play("wrong_soft"), null)
  assert.notEqual(mixer.play("correct_gold", { token: "answer:1" }), null)
  assert.equal(mixer.play("correct_gold", { token: "answer:1" }), null)
  now += 181
  assert.notEqual(mixer.play("correct_gold", { token: "answer:1" }), null)
})
