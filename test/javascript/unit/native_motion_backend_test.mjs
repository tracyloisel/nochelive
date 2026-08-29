import assert from "node:assert/strict"
import test from "node:test"

const frames = new Map()
let frameId = 0
globalThis.requestAnimationFrame = (callback) => {
  frameId += 1
  frames.set(frameId, callback)
  return frameId
}
globalThis.cancelAnimationFrame = (id) => frames.delete(id)

const { nativeMotionBackend } = await import("../../../app/javascript/platform/motion/native_backend.js")

test("native numeric motion settles exactly without loading the Motion package", async () => {
  const values = []
  const controls = nativeMotionBackend.animate(0, 12, {
    duration: 0.1,
    onUpdate: (value) => values.push(value)
  })
  const callback = frames.values().next().value
  callback(performance.now() + 200)
  await controls.finished

  assert.equal(values.at(-1), 12)
})

test("native numeric motion cancellation rejects completion and owns its frame", async () => {
  const controls = nativeMotionBackend.animate(0, 12, { duration: 1 })
  controls.cancel()

  await assert.rejects(controls.finished, /cancelled/)
})
