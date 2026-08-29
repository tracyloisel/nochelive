import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"

export default class extends Controller {
  static targets = ["button", "form"]

  connect() {
    this.effectScope = new EffectScope()
    this.submitting = false
    this.departureTimer = null

    if (typeof this.element.showModal === "function") {
      if (this.element.open) this.element.close()
      this.element.showModal()
    }

    this.effectScope.frame(() => {
      if (this.hasButtonTarget) this.buttonTarget.focus({ preventScroll: true })
    })
  }

  disconnect() {
    this.effectScope?.dispose()
    if (this.departureTimer) window.clearTimeout(this.departureTimer)
  }

  keepOpen(event) {
    event.preventDefault()
  }

  submit(event) {
    if (this.submitting) {
      event.preventDefault()
      return
    }

    event.preventDefault()
    this.submitting = true
    this.element.classList.add("is-departing")
    this.element.setAttribute("aria-busy", "true")
    if (this.hasButtonTarget) this.buttonTarget.disabled = true

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.departureTimer = window.setTimeout(() => {
      HTMLFormElement.prototype.submit.call(this.formTarget)
    }, reducedMotion ? 0 : 420)
  }
}
