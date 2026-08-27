import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "container", "current" ]

  connect() {
    this.frame = requestAnimationFrame(() => {
      this.frame = requestAnimationFrame(() => this.center())
    })
  }

  disconnect() {
    if (this.frame) cancelAnimationFrame(this.frame)
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
