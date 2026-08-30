import assert from "node:assert/strict"
import test from "node:test"
import { ReaderLoadingDirector } from "../../../app/javascript/runtime/loading/reader_loading_director.js"
import { FakeClock } from "../fakes/fake_clock.mjs"

test("ReaderLoadingDirector keeps fast chapter requests invisible and exposes calm wait states", () => {
  const clock = new FakeClock()
  const states = []
  const director = new ReaderLoadingDirector({ clock, render: (state) => states.push(state) })
  const fast = director.start()

  clock.tick(149)
  assert.equal(director.state, "pending")
  director.resolve(fast)
  assert.equal(director.state, "idle")

  director.start()
  clock.tick(150)
  assert.equal(director.state, "visible")
  clock.tick(1_050)
  assert.equal(director.state, "slow")
  clock.tick(2_800)
  assert.equal(director.state, "waiting")
  assert.deepEqual(states.slice(-4), ["pending", "visible", "slow", "waiting"])
})

test("ReaderLoadingDirector keeps explicit failure separate from a long request", () => {
  const clock = new FakeClock()
  const director = new ReaderLoadingDirector({ clock })
  const stale = director.start()
  const current = director.start()

  assert.equal(director.fail(stale), false)
  assert.equal(director.state, "pending")
  assert.equal(director.fail(current), true)
  assert.equal(director.state, "failed")

  director.start()
  assert.equal(director.state, "pending")
  director.dispose()
  assert.equal(director.state, "idle")
})
