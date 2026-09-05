import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"

const SURFACE_SELECTOR = "[data-chrome-surface]"
const SAMPLE_POSITIONS = Object.freeze([
  [ 0.16, 0.25 ],
  [ 0.84, 0.25 ],
  [ 0.50, 0.50 ],
  [ 0.16, 0.75 ],
  [ 0.84, 0.75 ]
])
const THEMES = Object.freeze({
  light: "celestial-light",
  "celestial-light": "celestial-light",
  dark: "celestial-dark",
  "celestial-dark": "celestial-dark"
})

export default class extends Controller {
  connect() {
    this.disposeEffects()
    this.effectScope = new EffectScope()
    this.serverTheme = this.currentTheme()
    this.framePending = false

    this.listen(window, "scroll", this.scheduleSample, { passive: true })
    this.listen(window, "resize", this.scheduleSample, { passive: true })
    this.listen(window, "pageshow", this.scheduleSample, { passive: true })
    this.listen(document, "scroll", this.scheduleSample, { capture: true, passive: true })
    this.listen(document, "load", this.scheduleSample, { capture: true, passive: true })
    this.listen(document, "turbo:frame-load", this.scheduleSample)
    this.listen(document, "turbo:render", this.scheduleSample)
    this.listen(document, "turbo:before-cache", this.beforeCache)

    const viewport = window.visualViewport
    this.listen(viewport, "scroll", this.scheduleSample, { passive: true })
    this.listen(viewport, "resize", this.scheduleSample, { passive: true })

    this.scheduleSample()
  }

  disconnect() {
    this.disposeEffects()
  }

  beforeCache = () => {
    this.applyTheme(this.serverTheme)
    this.disposeEffects()
  }

  scheduleSample = () => {
    if (!this.effectScope || this.framePending) return

    this.framePending = true
    this.effectScope.frame(() => {
      this.framePending = false
      this.sampleTheme()
    })
  }

  sampleTheme() {
    const points = this.samplePoints()
    if (points.length === 0 || typeof document.elementsFromPoint !== "function") {
      this.applyTheme(this.fallbackTheme())
      return
    }

    const votes = { "celestial-light": 0, "celestial-dark": 0 }
    points.forEach(([ x, y ]) => {
      const theme = this.themeAtPoint(x, y)
      if (theme) votes[theme] += 1
    })

    let theme = null
    if (votes["celestial-light"] > votes["celestial-dark"]) theme = "celestial-light"
    if (votes["celestial-dark"] > votes["celestial-light"]) theme = "celestial-dark"
    this.applyTheme(theme || this.fallbackTheme())
  }

  samplePoints() {
    let rect
    try {
      rect = this.element.getBoundingClientRect?.()
    } catch (_error) {
      return []
    }

    const left = Number(rect?.left)
    const top = Number(rect?.top)
    const width = Number(rect?.width)
    const height = Number(rect?.height)
    if (![ left, top, width, height ].every(Number.isFinite) || width <= 0 || height <= 0) return []

    return SAMPLE_POSITIONS.map(([ x, y ]) => [ left + (width * x), top + (height * y) ])
  }

  themeAtPoint(x, y) {
    let stack
    try {
      stack = Array.from(document.elementsFromPoint(x, y) || [])
    } catch (_error) {
      return null
    }

    let pageFallback = null
    for (const candidate of stack) {
      if (!candidate || this.belongsToChrome(candidate)) continue

      let marker
      try {
        marker = candidate.closest?.(SURFACE_SELECTOR)
      } catch (_error) {
        marker = null
      }
      if (!marker || this.belongsToChrome(marker)) continue

      const theme = this.themeFor(marker)
      if (!theme) continue

      if (marker === document.body || marker === document.documentElement) {
        pageFallback ||= theme
        continue
      }

      return theme
    }

    return pageFallback
  }

  belongsToChrome(node) {
    if (node === this.element) return true
    try {
      return this.element.contains?.(node) === true
    } catch (_error) {
      return false
    }
  }

  themeFor(marker) {
    let value
    try {
      value = marker.dataset?.chromeSurface ?? marker.getAttribute?.("data-chrome-surface")
    } catch (_error) {
      return null
    }
    return this.normalizeTheme(value)
  }

  currentTheme() {
    let value
    try {
      value = this.readTheme()
    } catch (_error) {
      return null
    }
    return this.normalizeTheme(value)
  }

  fallbackTheme() {
    return this.currentTheme() || this.serverTheme
  }

  normalizeTheme(value) {
    if (typeof value !== "string") return null
    return THEMES[value.trim().toLowerCase()] || null
  }

  applyTheme(theme) {
    if (!theme) return

    try {
      this.writeTheme(theme)
    } catch (_error) {
      // The existing server theme remains usable if the DOM cannot be mutated.
    }
  }

  readTheme() {
    return null
  }

  writeTheme(_theme) {}

  listen(target, name, handler, options) {
    if (typeof target?.addEventListener !== "function" || typeof target?.removeEventListener !== "function") return
    this.effectScope.listen(target, name, handler, options)
  }

  disposeEffects() {
    this.effectScope?.dispose()
    this.effectScope = null
    this.framePending = false
  }
}
