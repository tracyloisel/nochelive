import test from "node:test"
import assert from "node:assert/strict"
import { LoadingDirector } from "../../../app/javascript/runtime/loading/director.js"
import { FakeClock } from "../fakes/fake_clock.mjs"

test("LoadingDirector avoids flashes and exposes deterministic slow states", () => {
  const clock = new FakeClock()
  const states = []
  const director = new LoadingDirector({ clock, render: (state) => states.push(state) })
  const first = director.start()
  clock.tick(149)
  assert.equal(director.state, "pending")
  director.resolve(first)
  assert.equal(director.state, "idle")

  director.start()
  clock.tick(150)
  assert.equal(director.state, "visible")
  clock.tick(1_050)
  assert.equal(director.state, "slow")
  clock.tick(2_800)
  assert.equal(director.state, "failed")
  assert.deepEqual(states.slice(-4), ["pending", "visible", "slow", "failed"])
})

test("LoadingDirector ignores stale completions and handles offline", () => {
  const clock = new FakeClock()
  const director = new LoadingDirector({ clock })
  const stale = director.start()
  const current = director.start()
  assert.equal(director.resolve(stale), false)
  assert.equal(director.state, "pending")
  assert.equal(director.resolve(current), true)
  director.offline()
  assert.equal(director.state, "offline")
  director.online()
  assert.equal(director.state, "idle")
})
