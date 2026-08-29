import test from "node:test"
import assert from "node:assert/strict"
import { EffectScope } from "../../../app/javascript/platform/lifecycle/effect_scope.js"

test("EffectScope owns listeners, timers, animations and abort controllers", () => {
  const listeners = new Map()
  const target = {
    addEventListener(name, handler) { listeners.set(name, handler) },
    removeEventListener(name) { listeners.delete(name) }
  }
  const cleared = []
  const timers = {
    setTimeout() { return 7 }, clearTimeout(id) { cleared.push(["timeout", id]) },
    setInterval() { return 8 }, clearInterval(id) { cleared.push(["interval", id]) }
  }
  let cancelled = 0
  const scope = new EffectScope({ timers, frames: {} })
  const abortable = scope.abortable()
  scope.listen(target, "change", () => {})
  scope.timeout(() => {}, 10)
  scope.interval(() => {}, 20)
  scope.animation({ cancel() { cancelled += 1 } })

  scope.dispose()
  scope.dispose()

  assert.equal(listeners.size, 0)
  assert.equal(abortable.signal.aborted, true)
  assert.equal(cancelled, 1)
  assert.deepEqual(cleared.sort(), [["interval", 8], ["timeout", 7]])
})
