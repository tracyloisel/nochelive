import assert from "node:assert/strict"
import { after, test } from "node:test"
import { readFile } from "node:fs/promises"

import { EffectScope } from "../../../app/javascript/platform/lifecycle/effect_scope.js"

class ControllerStub {
  constructor(element) {
    this.element = element
  }
}

globalThis.__adaptiveSurfaceDependencies = { Controller: ControllerStub, EffectScope }

const adaptivePath = new URL("../../../app/javascript/platform/chrome/adaptive_surface_controller.js", import.meta.url)
const controllerPath = new URL("../../../app/javascript/controllers/navigation_dock_controller.js", import.meta.url)
const adaptiveSource = await readFile(adaptivePath, "utf8")
const controllerSource = await readFile(controllerPath, "utf8")
const testableSource = adaptiveSource
  .replace(/^import .*$/gm, "")
  .replace(
    "const SURFACE_SELECTOR",
    "const { Controller, EffectScope } = globalThis.__adaptiveSurfaceDependencies\n\nconst SURFACE_SELECTOR"
  )
  .replace("export default class extends Controller", "class AdaptiveSurfaceController extends Controller")
  .concat("\n", controllerSource.replace(/^import .*$/gm, ""))
const controllerUrl = `data:text/javascript;base64,${Buffer.from(testableSource).toString("base64")}`
const { default: NavigationDockController } = await import(controllerUrl)

const originalWindow = globalThis.window
const originalDocument = globalThis.document
const originalRequestAnimationFrame = globalThis.requestAnimationFrame
const originalCancelAnimationFrame = globalThis.cancelAnimationFrame

after(() => {
  globalThis.window = originalWindow
  globalThis.document = originalDocument
  globalThis.requestAnimationFrame = originalRequestAnimationFrame
  globalThis.cancelAnimationFrame = originalCancelAnimationFrame
  delete globalThis.__adaptiveSurfaceDependencies
})

function eventTarget() {
  const listeners = new Map()
  return {
    listeners,
    addEventListener(name, handler) {
      if (!listeners.has(name)) listeners.set(name, new Set())
      listeners.get(name).add(handler)
    },
    removeEventListener(name, handler) {
      listeners.get(name)?.delete(handler)
      if (listeners.get(name)?.size === 0) listeners.delete(name)
    },
    dispatch(name) {
      Array.from(listeners.get(name) || []).forEach((handler) => handler({ type: name, target: this }))
    },
    listenerCount(name) {
      return listeners.get(name)?.size || 0
    }
  }
}

function frameQueue() {
  let nextId = 1
  const callbacks = new Map()
  const cancelled = []
  return {
    callbacks,
    cancelled,
    request(callback) {
      const id = nextId
      nextId += 1
      callbacks.set(id, callback)
      return id
    },
    cancel(id) {
      cancelled.push(id)
      callbacks.delete(id)
    },
    flush() {
      const pending = Array.from(callbacks.entries())
      callbacks.clear()
      pending.forEach(([ id, callback ]) => callback(id * 16))
    }
  }
}

function surface(value, { parent = null } = {}) {
  const node = {
    dataset: { chromeSurface: value },
    parent,
    closest(selector) {
      assert.equal(selector, "[data-chrome-surface]")
      let current = this
      while (current) {
        if (current.dataset?.chromeSurface !== undefined) return current
        current = current.parent
      }
      return null
    }
  }
  return node
}

function childOf(parent) {
  return {
    parent,
    closest(selector) {
      assert.equal(selector, "[data-chrome-surface]")
      let current = this
      while (current) {
        if (current.dataset?.chromeSurface !== undefined) return current
        current = current.parent
      }
      return null
    }
  }
}

function dock({ theme = "celestial-light", rect = { left: 10, top: 700, width: 360, height: 80 } } = {}) {
  const descendants = new Set()
  return {
    dataset: { dockTheme: theme },
    getBoundingClientRect() { return rect },
    contains(node) { return descendants.has(node) },
    addDescendant(node) { descendants.add(node) }
  }
}

function environment({ theme = "celestial-light", stacks = [], rect, withPointApi = true } = {}) {
  const frames = frameQueue()
  const windowTarget = eventTarget()
  const visualViewport = eventTarget()
  const documentTarget = eventTarget()
  const body = surface("light")
  const html = surface("light")
  let calls = 0

  windowTarget.visualViewport = visualViewport
  documentTarget.body = body
  documentTarget.documentElement = html
  if (withPointApi) {
    documentTarget.elementsFromPoint = () => {
      const stack = stacks[calls] || []
      calls += 1
      return stack
    }
  }

  globalThis.window = windowTarget
  globalThis.document = documentTarget
  globalThis.requestAnimationFrame = frames.request.bind(frames)
  globalThis.cancelAnimationFrame = frames.cancel.bind(frames)

  const element = dock({ theme, rect })
  const controller = new NavigationDockController(element)
  return {
    body,
    controller,
    documentTarget,
    element,
    frames,
    html,
    pointCalls: () => calls,
    visualViewport,
    windowTarget
  }
}

test("five samples select light and dark majorities, including celestial aliases", () => {
  const light = surface("light")
  const dark = surface("celestial-dark")
  const env = environment({
    theme: "celestial-dark",
    stacks: [ [ light ], [ light ], [ dark ], [ light ], [ dark ] ]
  })

  env.controller.connect()
  env.frames.flush()

  assert.equal(env.pointCalls(), 5)
  assert.equal(env.element.dataset.dockTheme, "celestial-light")

  const nextDark = surface("dark")
  const nextLight = surface("celestial-light")
  const nextStacks = [ [ nextDark ], [ nextLight ], [ nextDark ], [ nextDark ], [ nextLight ] ]
  env.documentTarget.elementsFromPoint = () => nextStacks.shift()
  env.windowTarget.dispatch("scroll")
  env.frames.flush()

  assert.equal(env.element.dataset.dockTheme, "celestial-dark")
  env.controller.disconnect()
})

test("a nested local marker wins over an earlier body fallback in the hit stack", () => {
  const env = environment({ theme: "celestial-dark" })
  env.body.dataset.chromeSurface = "dark"
  const overlay = childOf(env.body)
  const local = surface("light", { parent: env.body })
  const localContent = childOf(local)
  const stack = [ overlay, localContent, local, env.body ]
  env.documentTarget.elementsFromPoint = () => stack

  env.controller.connect()
  env.frames.flush()

  assert.equal(env.element.dataset.dockTheme, "celestial-light")
  env.controller.disconnect()
})

test("dock descendants never vote for the surface behind the dock", () => {
  const env = environment({ theme: "celestial-dark" })
  const dockChild = surface("dark")
  const behind = surface("light")
  env.element.addDescendant(dockChild)
  env.documentTarget.elementsFromPoint = () => [ dockChild, env.element, behind, env.body ]

  env.controller.connect()
  env.frames.flush()

  assert.equal(env.element.dataset.dockTheme, "celestial-light")
  env.controller.disconnect()
})

test("missing markers, point APIs, or usable geometry preserve the current server theme", () => {
  const noApi = environment({ theme: "dark", withPointApi: false })
  noApi.controller.connect()
  noApi.frames.flush()
  assert.equal(noApi.element.dataset.dockTheme, "celestial-dark")

  const noMarkers = environment({ theme: "celestial-light" })
  const unmarked = { closest: () => null }
  noMarkers.documentTarget.elementsFromPoint = () => [ unmarked ]
  noMarkers.controller.connect()
  noMarkers.frames.flush()
  assert.equal(noMarkers.element.dataset.dockTheme, "celestial-light")

  noMarkers.element.dataset.dockTheme = "celestial-dark"
  noMarkers.windowTarget.dispatch("resize")
  noMarkers.frames.flush()
  assert.equal(noMarkers.element.dataset.dockTheme, "celestial-dark")

  const noGeometry = environment({
    theme: "celestial-dark",
    rect: { left: 0, top: 0, width: 0, height: 80 },
    stacks: [ [ surface("light") ] ]
  })
  noGeometry.controller.connect()
  noGeometry.frames.flush()
  assert.equal(noGeometry.pointCalls(), 0)
  assert.equal(noGeometry.element.dataset.dockTheme, "celestial-dark")

  noApi.controller.disconnect()
  noMarkers.controller.disconnect()
  noGeometry.controller.disconnect()
})

test("connect, scroll, and resize work is throttled to one owned frame", () => {
  const light = surface("light")
  const env = environment({ stacks: Array.from({ length: 10 }, () => [ light ]) })

  env.controller.connect()
  env.windowTarget.dispatch("scroll")
  env.windowTarget.dispatch("scroll")
  env.windowTarget.dispatch("resize")

  assert.equal(env.frames.callbacks.size, 1)
  assert.equal(env.pointCalls(), 0)
  env.frames.flush()
  assert.equal(env.pointCalls(), 5)

  env.windowTarget.dispatch("scroll")
  assert.equal(env.frames.callbacks.size, 1)
  env.frames.flush()
  assert.equal(env.pointCalls(), 10)
  env.controller.disconnect()
})

test("visual viewport scroll and resize schedule fresh samples", () => {
  const env = environment({ stacks: Array.from({ length: 15 }, () => [ surface("light") ]) })
  env.controller.connect()

  assert.equal(env.visualViewport.listenerCount("scroll"), 1)
  assert.equal(env.visualViewport.listenerCount("resize"), 1)
  env.frames.flush()

  env.visualViewport.dispatch("scroll")
  env.visualViewport.dispatch("resize")
  assert.equal(env.frames.callbacks.size, 1)
  env.frames.flush()
  assert.equal(env.pointCalls(), 10)

  env.controller.disconnect()
})

test("pageshow resamples after browser scroll restoration", () => {
  const env = environment({ stacks: Array.from({ length: 10 }, () => [ surface("light") ]) })
  env.controller.connect()

  assert.equal(env.windowTarget.listenerCount("pageshow"), 1)
  env.frames.flush()
  env.windowTarget.dispatch("pageshow")
  assert.equal(env.frames.callbacks.size, 1)
  env.frames.flush()
  assert.equal(env.pointCalls(), 10)

  env.controller.disconnect()
  assert.equal(env.windowTarget.listenerCount("pageshow"), 0)
})

test("internal scrolls, image loads, and Turbo frame updates schedule fresh samples", () => {
  const env = environment({ stacks: Array.from({ length: 20 }, () => [ surface("light") ]) })
  env.controller.connect()

  assert.equal(env.documentTarget.listenerCount("scroll"), 1)
  assert.equal(env.documentTarget.listenerCount("load"), 1)
  assert.equal(env.documentTarget.listenerCount("turbo:frame-load"), 1)
  assert.equal(env.documentTarget.listenerCount("turbo:render"), 1)
  env.frames.flush()

  env.documentTarget.dispatch("scroll")
  assert.equal(env.frames.callbacks.size, 1)
  env.frames.flush()
  assert.equal(env.pointCalls(), 10)

  env.documentTarget.dispatch("load")
  env.documentTarget.dispatch("turbo:frame-load")
  env.documentTarget.dispatch("turbo:render")
  assert.equal(env.frames.callbacks.size, 1)
  env.frames.flush()
  assert.equal(env.pointCalls(), 15)

  env.controller.disconnect()
  assert.equal(env.documentTarget.listenerCount("scroll"), 0)
  assert.equal(env.documentTarget.listenerCount("load"), 0)
  assert.equal(env.documentTarget.listenerCount("turbo:frame-load"), 0)
  assert.equal(env.documentTarget.listenerCount("turbo:render"), 0)
})

test("Turbo cache and disconnect remove listeners and cancel pending frames", () => {
  const env = environment({ theme: "celestial-dark", stacks: Array.from({ length: 5 }, () => [ surface("light") ]) })
  env.controller.connect()

  assert.equal(env.frames.callbacks.size, 1)
  assert.equal(env.documentTarget.listenerCount("turbo:before-cache"), 1)
  env.frames.flush()
  assert.equal(env.element.dataset.dockTheme, "celestial-light")
  env.windowTarget.dispatch("scroll")
  assert.equal(env.frames.callbacks.size, 1)
  env.documentTarget.dispatch("turbo:before-cache")

  assert.equal(env.element.dataset.dockTheme, "celestial-dark")
  assert.equal(env.frames.callbacks.size, 0)
  assert.equal(env.documentTarget.listenerCount("turbo:before-cache"), 0)
  assert.equal(env.windowTarget.listenerCount("scroll"), 0)
  assert.equal(env.windowTarget.listenerCount("resize"), 0)
  assert.equal(env.windowTarget.listenerCount("pageshow"), 0)
  assert.equal(env.visualViewport.listenerCount("scroll"), 0)
  assert.equal(env.visualViewport.listenerCount("resize"), 0)

  env.windowTarget.dispatch("scroll")
  assert.equal(env.frames.callbacks.size, 0)
  assert.equal(env.pointCalls(), 5)

  env.controller.disconnect()
  assert.equal(env.frames.callbacks.size, 0)
})
