import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"

// Keeps the current pack visible in the compact horizontal carousel.
export default class extends Controller {
  static targets = ["path", "node"]

  connect() {
    this.effectScope = new EffectScope()
    this.effectScope.frame(() => {
      const current = this.element.querySelector(".hub-progress-node.is-focus")
      if (!current || !this.hasPathTarget) return

      const left = current.offsetLeft - (this.pathTarget.clientWidth - current.clientWidth) / 2
      this.pathTarget.scrollTo({ left: Math.max(0, left), behavior: "auto" })
      this.syncEdges()
    })
  }

  disconnect() {
    this.effectScope?.dispose()
  }

  syncEdges() {
    if (!this.hasPathTarget) return

    const { scrollLeft, scrollWidth, clientWidth } = this.pathTarget
    this.element.classList.toggle("is-at-start", scrollLeft <= 2)
    this.element.classList.toggle("is-at-end", scrollLeft + clientWidth >= scrollWidth - 2)
  }
}
