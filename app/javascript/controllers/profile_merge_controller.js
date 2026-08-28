import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button", "overlay" ]

  connect() {
    this.hide = this.hide.bind(this)
    document.addEventListener("turbo:before-cache", this.hide)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.hide)
  }

  start() {
    this.element.setAttribute("aria-busy", "true")
    this.buttonTarget.disabled = true
    this.overlayTarget.hidden = false
  }

  finish(event) {
    if (!event.detail.success) this.hide()
  }

  hide() {
    this.element.removeAttribute("aria-busy")
    if (this.hasButtonTarget) this.buttonTarget.disabled = false
    if (this.hasOverlayTarget) this.overlayTarget.hidden = true
  }
}
