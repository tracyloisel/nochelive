import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { motionDirector } from "runtime/motion/runtime"

// Animated counter for HUD scores and community stats.
// HUD mode: counts from data-initial-value to data-target-value over 400ms.
// Community mode: counts from 0 to data-target-value over 500ms.
// On Turbo/WebSocket update: vertical slide + icon glow.
export default class extends Controller {
  static targets = ["value", "stat", "community"]
  static values = {
    target: Number,
    initial: Number,
    gain: Number,
    revealOnce: String,
    sessionKey: String
  }

  connect() {
    this.effectScope = new EffectScope()
    this.controls = []
    motionDirector.setReducedMotion(window.matchMedia("(prefers-reduced-motion: reduce)").matches)
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.settle()
      return
    }

    // Community stats mode: animate each stat counter
    if (this.hasCommunityTarget) {
      this.animateCommunityStats()
      return
    }

    // HUD mode: animate single counter
    this.animateValue()
  }

  // Community stats: count each stat from 0 to target
  animateCommunityStats() {
    const stats = this.element.querySelectorAll(".is-counter")
    stats.forEach((el, i) => {
      // Session-based one-time reveal
      const sessionKey = el.dataset.sessionKey
      if (sessionKey && el.dataset.revealOnce === "true") {
        const seen = sessionStorage.getItem(sessionKey)
        if (seen) return
      }

      const target = parseInt(el.dataset.targetValue.replace(/[^\d]/g, ""), 10)
      if (!target) return

      this.effectScope.timeout(() => {
        const controls = motionDirector.count(0, target, {
          duration: 0.5,
          onUpdate: (value) => { el.textContent = this.compactNumber(Math.round(value)) },
          onComplete: () => {
            el.classList.add("is-settled")
            if (sessionKey) sessionStorage.setItem(sessionKey, "1")
          }
        })
        this.controls.push(controls)
      }, i * 80)
    })
  }

  compactNumber(value) {
    const absolute = Math.abs(value)
    const units = [
      [1_000_000_000, "B"],
      [1_000_000, "M"],
      [1_000, "K"]
    ]
    const unit = units.find(([threshold]) => absolute >= threshold)

    if (!unit) return value.toLocaleString()

    const [divisor, suffix] = unit
    const compact = Math.round((value / divisor) * 10) / 10
    return `${compact.toLocaleString(undefined, { maximumFractionDigits: 1 })}${suffix}`
  }

  // HUD mode: animate single value
  animateValue() {
    const from = this.hasInitialValue ? this.initialValue : 0
    const currentText = this.valueTarget?.textContent?.replace(/[^\d]/g, "") || ""
    const to = currentText ? parseInt(currentText, 10) : this.targetValue

    if (!to || from === to) {
      this.settle()
      return
    }

    const controls = motionDirector.count(from, to, {
      duration: 0.4,
      onUpdate: (value) => { this.valueTarget.textContent = Math.round(value).toLocaleString() },
      onComplete: () => this.settle()
    })
    this.controls.push(controls)

    if (this.sessionKeyValue) {
      sessionStorage.setItem(this.sessionKeyValue, "1")
    }
  }

  // Called by Turbo/WebSocket update listener
  onRemoteUpdate() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    this.element.classList.add("is-updating")
    setTimeout(() => {
      this.element.classList.remove("is-updating")
    }, 500)
  }

  settle() {
    this.element.classList.add("is-settled")
  }

  disconnect() {
    this.effectScope?.dispose()
    this.controls?.forEach((controls) => controls.cancel?.())
  }
}
