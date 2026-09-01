import assert from "node:assert/strict"
import test from "node:test"
import { readFile } from "node:fs/promises"

import { EffectScope } from "../../../app/javascript/platform/lifecycle/effect_scope.js"

class ControllerStub {
  constructor(element) {
    this.element = element
  }
}

let currentDirector
const directorProxy = {
  setReducedMotion(...args) { return currentDirector.setReducedMotion(...args) },
  run(...args) { return currentDirector.run(...args) },
  finish(...args) { return currentDirector.finish(...args) }
}

globalThis.__ramaMotionDependencies = {
  Controller: ControllerStub,
  EffectScope,
  motionDirector: directorProxy
}

const controllerPath = new URL("../../../app/javascript/controllers/rama_motion_controller.js", import.meta.url)
const controllerSource = await readFile(controllerPath, "utf8")
const testableSource = controllerSource
  .replace(/^import .*$/gm, "")
  .replace(
    "const DEFAULT_RECIPE",
    "const { Controller, EffectScope, motionDirector } = globalThis.__ramaMotionDependencies\n\nconst DEFAULT_RECIPE"
  )
const controllerUrl = `data:text/javascript;base64,${Buffer.from(testableSource).toString("base64")}`
const { default: RamaMotionController } = await import(controllerUrl)

function classList() {
  const names = new Set()
  return {
    add(...values) { values.forEach((value) => names.add(value)) },
    contains(value) { return names.has(value) }
  }
}

function item({ animatable = true } = {}) {
  const node = { style: {}, classList: classList() }
  if (animatable) node.animate = () => ({})
  return node
}

function chapter(items, recipe = "list-enter") {
  return {
    dataset: { ramaMotionRecipe: recipe },
    classList: classList(),
    querySelectorAll(selector) {
      assert.equal(selector, "[data-rama-motion-item]")
      return items
    }
  }
}

function eventTarget() {
  const listeners = new Map()
  return {
    listeners,
    addEventListener(name, listener) { listeners.set(name, listener) },
    removeEventListener(name, listener) {
      if (listeners.get(name) === listener) listeners.delete(name)
    },
    dispatch(name) { listeners.get(name)?.({ type: name }) }
  }
}

function director({ throws = false } = {}) {
  const calls = { reduced: [], runs: [], finishes: [], cancellations: 0 }
  return {
    calls,
    setReducedMotion(value) { calls.reduced.push(value) },
    run(recipe, items, options) {
      calls.runs.push({ recipe, items, options })
      if (throws) throw new Error("animation backend unavailable")
      return {
        cancel() { calls.cancellations += 1 },
        finished: new Promise(() => {})
      }
    },
    finish(recipe, items, options = {}) {
      calls.finishes.push({ recipe, items, options })
      items.forEach((node) => {
        node.style.opacity = "1"
        node.style.transform = options.reduced ? "none" : "translateY(0)"
        node.classList.add("is-visible")
      })
    }
  }
}

function environment({ reduced = false, observer = true, runtime = director() } = {}) {
  const observers = []
  class IntersectionObserverStub {
    constructor(callback, options) {
      this.callback = callback
      this.options = options
      this.observed = new Set()
      this.unobserved = new Set()
      this.disconnected = false
      observers.push(this)
    }

    observe(target) { this.observed.add(target) }
    unobserve(target) {
      this.observed.delete(target)
      this.unobserved.add(target)
    }
    disconnect() {
      this.disconnected = true
      this.observed.clear()
    }
    enter(target) { this.callback([{ target, isIntersecting: true }]) }
  }

  const documentTarget = eventTarget()
  globalThis.document = documentTarget
  globalThis.window = {
    matchMedia: () => ({ matches: reduced }),
    IntersectionObserver: observer ? IntersectionObserverStub : undefined
  }
  currentDirector = runtime
  return { documentTarget, observers, runtime }
}

function controllerFor(chapters) {
  const root = { dataset: {} }
  const controller = new RamaMotionController(root)
  controller.chapterTargets = chapters
  return { controller, root }
}

test("one observer reveals each chapter once with its named shared recipe", () => {
  const env = environment()
  const first = chapter([ item(), item() ], "result-reveal")
  const second = chapter([ item() ])
  const { controller, root } = controllerFor([ first, second ])

  controller.connect()

  assert.equal(env.observers.length, 1)
  assert.deepEqual(env.observers[0].options, {
    root: null,
    rootMargin: "0px 0px -8% 0px",
    threshold: 0.12
  })
  assert.equal(env.observers[0].observed.size, 2)
  assert.equal(root.dataset.ramaMotionState, "observing")

  env.observers[0].enter(first)
  env.observers[0].enter(first)

  assert.equal(env.runtime.calls.runs.length, 1)
  assert.equal(env.runtime.calls.runs[0].recipe, "result-reveal")
  assert.equal(env.runtime.calls.runs[0].items.length, 2)
  assert.equal(first.dataset.ramaMotionState, "running")
  assert.equal(env.observers[0].unobserved.has(first), true)

  env.runtime.calls.runs[0].options.onComplete()
  assert.equal(first.dataset.ramaMotionState, "ready")
  assert.equal(first.classList.contains("is-rama-motion-visible"), true)
  assert.equal(root.dataset.ramaMotionState, "observing")

  env.observers[0].enter(second)
  env.runtime.calls.runs[1].options.onComplete()

  assert.equal(second.dataset.ramaMotionState, "ready")
  assert.equal(root.dataset.ramaMotionState, "ready")
  assert.equal(env.observers[0].disconnected, true)

  controller.disconnect()
})

test("reduced motion exposes the final state immediately without an observer", () => {
  const env = environment({ reduced: true })
  const animatedItem = item()
  const story = chapter([ animatedItem ], "result-reveal")
  const { controller, root } = controllerFor([ story ])

  controller.connect()

  assert.equal(env.observers.length, 0)
  assert.equal(env.runtime.calls.runs.length, 0)
  assert.equal(env.runtime.calls.finishes.length, 1)
  assert.equal(env.runtime.calls.finishes[0].options.reduced, true)
  assert.equal(animatedItem.style.transform, "none")
  assert.equal(story.dataset.ramaMotionState, "ready")
  assert.equal(root.dataset.ramaMotionState, "ready")

  controller.disconnect()
})

test("missing browser animation APIs fail open with every chapter readable", () => {
  const env = environment({ observer: false })
  const animatedItem = item({ animatable: false })
  const story = chapter([ animatedItem ], "unknown-recipe")
  const { controller, root } = controllerFor([ story ])

  controller.connect()

  assert.equal(env.runtime.calls.runs.length, 0)
  assert.equal(env.runtime.calls.finishes[0].recipe, "list-enter")
  assert.equal(animatedItem.style.opacity, "1")
  assert.equal(story.dataset.ramaMotionState, "ready")
  assert.equal(root.dataset.ramaMotionState, "ready")

  controller.disconnect()
})

test("Turbo cache finalizes waiting and running chapters and owns cleanup", () => {
  const env = environment()
  const first = chapter([ item() ])
  const second = chapter([ item() ], "invitation-enter")
  const { controller, root } = controllerFor([ first, second ])

  controller.connect()
  env.observers[0].enter(first)
  env.documentTarget.dispatch("turbo:before-cache")

  assert.equal(first.dataset.ramaMotionState, "ready")
  assert.equal(second.dataset.ramaMotionState, "ready")
  assert.equal(root.dataset.ramaMotionState, "ready")
  assert.equal(env.observers[0].disconnected, true)
  assert.equal(env.runtime.calls.cancellations, 1)
  assert.equal(env.documentTarget.listeners.has("turbo:before-cache"), false)

  controller.disconnect()
})

test("a runtime animation failure also settles to readable content", () => {
  const runtime = director({ throws: true })
  const env = environment({ runtime })
  const animatedItem = item()
  const story = chapter([ animatedItem ], "result-reveal")
  const { controller } = controllerFor([ story ])

  controller.connect()
  env.observers[0].enter(story)

  assert.equal(env.runtime.calls.runs.length, 1)
  assert.equal(env.runtime.calls.finishes.length, 1)
  assert.equal(animatedItem.style.opacity, "1")
  assert.equal(story.dataset.ramaMotionState, "ready")

  controller.disconnect()
})
