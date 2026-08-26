import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "panel", "button", "openIcon", "closeIcon", "veil" ]
  static values = {
    openLabel: String,
    closeLabel: String
  }

  connect() {
    this.onCache = this.close.bind(this)
    this.onEsc = this.escape.bind(this)
    document.addEventListener("turbo:before-cache", this.onCache)
    this.sync()
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.onCache)
    this.close()
  }

  toggle() {
    if (this.panelTarget.open) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (!this.panelTarget.open) this.panelTarget.show()
    this.element.classList.add("is-open")
    document.addEventListener("keydown", this.onEsc)
    this.sync()
  }

  close() {
    if (this.panelTarget.open) this.panelTarget.close()
    this.element.classList.remove("is-open")
    document.removeEventListener("keydown", this.onEsc)
    this.sync()
  }

  onClose() {
    this.element.classList.remove("is-open")
    document.removeEventListener("keydown", this.onEsc)
    this.sync()
  }

  backdropClose(event) {
    if (event.target === this.panelTarget) this.close()
  }

  escape(event) {
    if (event.key === "Escape") this.close()
  }

  sync() {
    const open = this.panelTarget.open
    this.buttonTarget.setAttribute("aria-expanded", open ? "true" : "false")
    this.buttonTarget.setAttribute("aria-label", open ? this.closeLabelValue : this.openLabelValue)
    this.buttonTarget.classList.toggle("is-open", open)
    if (this.hasOpenIconTarget) this.openIconTarget.toggleAttribute("hidden", open)
    if (this.hasCloseIconTarget) this.closeIconTarget.toggleAttribute("hidden", !open)
    if (this.hasVeilTarget) this.veilTarget.toggleAttribute("hidden", !open)
  }
}
