import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { http } from "platform/http/client"
import { countdownProjection, nextSecondDelay } from "runtime/motion/countdown_projection"

export default class extends Controller {
  static values = { end: String, duration: Number, reloadUrl: String, expireUrl: String, ask: Boolean }
  static targets = ["label", "bar"]

  connect() {
    this.effectScope = new EffectScope()
    this.endAt = Date.parse(this.endValue)
    if (this.askValue && window.matchMedia("(prefers-reduced-motion: reduce)").matches) this.releaseAsk()
    this.animateBar()
    this.tick()
  }

  disconnect() {
    this.barAnimation?.cancel()
    this.effectScope?.dispose()
  }

  releaseAsk() {
    if (!this.askValue || !(this.durationValue > 0) || this.previewReleased) return
    this.previewReleased = true
    const previewRemaining = Math.max(0, this.endAt - Date.now() - (this.durationValue * 1000))
    this.endAt -= previewRemaining
    this.animateBar()
    this.tick()
  }

  tick() {
    this.cancelTick?.()
    const projection = countdownProjection({
      endAt: this.endAt,
      now: Date.now(),
      durationSeconds: this.durationValue,
      ask: this.askValue
    })
    if (projection.seconds !== this.lastSeconds && this.hasLabelTarget) {
      this.labelTarget.textContent = projection.seconds
      this.lastSeconds = projection.seconds
    }
    this.element.classList.toggle("is-warn", projection.warn)
    this.element.classList.toggle("is-low", projection.hot)
    this.element.classList.toggle("is-empty", projection.expired)
    if (!projection.expired) {
      this.cancelTick = this.effectScope.timeout(() => this.tick(), nextSecondDelay(projection.remainMs))
      return
    }
    if (this.hasExpireUrlValue && this.expireUrlValue && !this.expired) {
      this.expired = true
      const request = this.effectScope.abortable()
      http.turboStream(this.expireUrlValue, {
        method: "POST",
        signal: request.signal
      }).catch(() => {})
      return
    }
    if (this.reloadUrlValue && !this.reloaded) {
      this.reloaded = true
      window.location = this.reloadUrlValue
    }
  }

  animateBar() {
    if (!this.hasBarTarget || !(this.durationValue > 0)) return
    const projection = countdownProjection({
      endAt: this.endAt,
      now: Date.now(),
      durationSeconds: this.durationValue,
      ask: this.askValue
    })
    this.barAnimation?.cancel()
    this.barTarget.style.transformOrigin = "left center"
    if (typeof this.barTarget.animate === "function" && projection.remainMs > 0) {
      this.barAnimation = this.barTarget.animate(
        [ { transform: `scaleX(${projection.ratio})` }, { transform: "scaleX(0)" } ],
        { duration: projection.remainMs, easing: "linear", fill: "forwards" }
      )
      return
    }

    this.barTarget.style.transform = `scaleX(${projection.ratio})`
    this.barTarget.style.transition = `transform ${projection.remainMs}ms linear`
    this.effectScope.timeout(() => { this.barTarget.style.transform = "scaleX(0)" }, 0)
  }
}
