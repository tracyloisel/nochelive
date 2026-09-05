import assert from "node:assert/strict"
import { after, test } from "node:test"
import { readFile } from "node:fs/promises"

import { EffectScope } from "../../../app/javascript/platform/lifecycle/effect_scope.js"

class ControllerStub {
  constructor(element) {
    this.element = element
  }
}

globalThis.__adaptiveChromeDependencies = { Controller: ControllerStub, EffectScope }

const adaptivePath = new URL("../../../app/javascript/platform/chrome/adaptive_surface_controller.js", import.meta.url)
const dockPath = new URL("../../../app/javascript/controllers/navigation_dock_controller.js", import.meta.url)
const hudPath = new URL("../../../app/javascript/controllers/hud_surface_controller.js", import.meta.url)
const adaptiveSource = await readFile(adaptivePath, "utf8")
const dockSource = await readFile(dockPath, "utf8")
const hudSource = await readFile(hudPath, "utf8")
const testableSource = [
  "const { Controller, EffectScope } = globalThis.__adaptiveChromeDependencies",
  adaptiveSource
    .replace(/^import .*$/gm, "")
    .replace("export default class extends Controller", "class AdaptiveSurfaceController extends Controller"),
  dockSource
    .replace(/^import .*$/gm, "")
    .replace("export default class extends AdaptiveSurfaceController", "class NavigationDockController extends AdaptiveSurfaceController"),
  hudSource
    .replace(/^import .*$/gm, "")
    .replace("export default class extends AdaptiveSurfaceController", "class HudSurfaceController extends AdaptiveSurfaceController"),
  "export { HudSurfaceController, NavigationDockController }"
].join("\n")
const controllerUrl = `data:text/javascript;base64,${Buffer.from(testableSource).toString("base64")}`
const { HudSurfaceController, NavigationDockController } = await import(controllerUrl)

const originalDocument = globalThis.document

after(() => {
  globalThis.document = originalDocument
  delete globalThis.__adaptiveChromeDependencies
})

function surface(theme) {
  return {
    dataset: { chromeSurface: theme },
    closest(selector) {
      assert.equal(selector, "[data-chrome-surface]")
      return this
    }
  }
}

function menu(theme = "celestial-light") {
  return { dataset: { hudTheme: theme } }
}

function themeCompanion(theme = "celestial-light") {
  return { dataset: { hudTheme: theme } }
}

function hudElement(homeMenu, { theme = "celestial-light", top = 20 } = {}) {
  return {
    dataset: { hudTheme: theme },
    getBoundingClientRect() { return { left: 10, top, width: 360, height: 80 } },
    contains() { return false },
    closest(selector) {
      assert.equal(selector, ".home-menu")
      return homeMenu
    }
  }
}

function dockElement({ theme = "celestial-dark", top = 700 } = {}) {
  return {
    dataset: { dockTheme: theme },
    getBoundingClientRect() { return { left: 10, top, width: 360, height: 80 } },
    contains() { return false }
  }
}

test("HUD and dock sample their own geometry and may choose opposite themes", () => {
  const dark = surface("dark")
  const light = surface("light")
  globalThis.document = {
    body: surface("light"),
    documentElement: surface("light"),
    elementsFromPoint(_x, y) { return [ y < 300 ? dark : light ] }
  }

  const homeMenu = menu()
  const header = hudElement(homeMenu)
  const dock = dockElement()
  const hudController = new HudSurfaceController(header)
  const dockController = new NavigationDockController(dock)

  hudController.sampleTheme()
  dockController.sampleTheme()

  assert.equal(header.dataset.hudTheme, "celestial-dark")
  assert.equal(homeMenu.dataset.hudTheme, "celestial-dark")
  assert.equal(dock.dataset.dockTheme, "celestial-light")
})

test("HUD reads the menu fallback and updates every chrome theme node atomically", () => {
  const homeMenu = menu("light")
  const desktopNavigation = themeCompanion()
  globalThis.document = {
    querySelectorAll(selector) {
      assert.equal(selector, "[data-hud-theme-companion]")
      return [ desktopNavigation ]
    }
  }
  const header = hudElement(homeMenu)
  delete header.dataset.hudTheme
  const controller = new HudSurfaceController(header)

  assert.equal(controller.currentTheme(), "celestial-light")
  controller.serverTheme = controller.currentTheme()
  controller.applyTheme("celestial-dark")

  assert.equal(header.dataset.hudTheme, "celestial-dark")
  assert.equal(homeMenu.dataset.hudTheme, "celestial-dark")
  assert.equal(desktopNavigation.dataset.hudTheme, "celestial-dark")

  controller.beforeCache()
  assert.equal(header.dataset.hudTheme, "celestial-light")
  assert.equal(homeMenu.dataset.hudTheme, "celestial-light")
  assert.equal(desktopNavigation.dataset.hudTheme, "celestial-light")
})

test("HUD remains usable when it is not nested in a home menu", () => {
  const header = hudElement(null, { theme: "dark" })
  const controller = new HudSurfaceController(header)

  assert.equal(controller.currentTheme(), "celestial-dark")
  controller.applyTheme("celestial-light")
  assert.equal(header.dataset.hudTheme, "celestial-light")
})
