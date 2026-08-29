import assert from "node:assert/strict"
import test from "node:test"

import { MotionDirector } from "../../../app/javascript/runtime/motion/motion_director.js"

function element() {
  const classes = new Set()
  return { style: {}, classList: { add: (name) => classes.add(name), contains: (name) => classes.has(name) } }
}

test("MotionDirector runs a bounded named recipe and owns its final state", async () => {
  const calls = []
  const controls = { cancel() {}, finished: Promise.resolve() }
  const backend = {
    stagger: (value) => value,
    animate: (elements, keyframes, options) => { calls.push({ elements, keyframes, options }); return controls }
  }
  const director = new MotionDirector({ backend })
  const elements = Array.from({ length: 100 }, element)

  director.run("list-enter", elements)
  await controls.finished
  assert.equal(calls[0].elements.length, 80)
  assert.ok(calls[0].options.duration <= 1.2)
  assert.equal(elements[0].style.opacity, "1")
  assert.equal(elements[0].classList.contains("is-visible"), true)
})

test("reduced motion applies the same final state without starting an animation", async () => {
  let animations = 0
  const director = new MotionDirector({
    reduced: true,
    backend: { stagger: () => 0, animate: () => { animations += 1 } }
  })
  const target = element()

  await director.run("ceremony-enter", [ target ]).finished
  assert.equal(animations, 0)
  assert.equal(target.style.transform, "none")
})

test("invitation entry never transforms the container that owns fixed actions", async () => {
  let keyframes
  const director = new MotionDirector({
    backend: {
      stagger: () => 0,
      animate: (_elements, frames) => {
        keyframes = frames
        return { cancel() {}, finished: Promise.resolve() }
      }
    }
  })
  const target = element()

  await director.run("invitation-enter", [ target ]).finished
  assert.equal(keyframes.transform, undefined)
  assert.equal(target.style.transform, "none")
})

test("numeric projection uses the shared backend and settles exactly", async () => {
  const values = []
  const backend = {
    stagger: () => 0,
    animate: (_from, _to, options) => {
      options.onUpdate(4.2)
      return { cancel() {}, finished: Promise.resolve() }
    }
  }
  const director = new MotionDirector({ backend })
  await director.count(0, 5, { onUpdate: (value) => values.push(value) }).finished
  assert.deepEqual(values, [ 4.2, 5 ])
})
