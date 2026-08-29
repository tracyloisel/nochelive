import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"

export default class extends Controller {
  static targets = [ "container", "current" ]

  connect() {
    this.effectScope = new EffectScope()
    this.effectScope.frame(() => this.effectScope.frame(() => this.center()))
  }

  disconnect() {
    this.effectScope?.dispose()
  }

  center(event) {
    event?.preventDefault()
    if (!this.hasContainerTarget || !this.hasCurrentTarget) return

    const container = this.containerTarget
    const current = this.currentTarget
    const centered = current.offsetTop - ((container.clientHeight - current.offsetHeight) / 2)
    const maximum = container.scrollHeight - container.clientHeight
    container.scrollTop = Math.max(0, Math.min(centered, maximum))
  }
}
