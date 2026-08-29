import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"

export default class extends Controller {
  static targets = [ "panel", "button", "heading" ]
  static values = {
    openLabel: String,
    closeLabel: String
  }

  connect() {
    this.effectScope = new EffectScope()
    this.onCache = this.close.bind(this)
    this.effectScope.listen(document, "turbo:before-cache", this.onCache)
    this.sync()
  }

  disconnect() {
    this.close()
    this.effectScope.dispose()
  }

  toggle() {
    if (this.panelTarget.open) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.returnFocusTarget = document.activeElement
    if (!this.panelTarget.open) this.panelTarget.showModal()
    this.sync()
    this.effectScope.frame(() => this.headingTarget.focus({ preventScroll: true }))
  }

  close() {
    if (this.panelTarget.open) {
      this.panelTarget.close()
    } else {
      this.finishClose()
    }
  }

  onClose() {
    this.finishClose()
  }

  finishClose() {
    this.sync()
    const target = this.returnFocusTarget
    this.returnFocusTarget = null
    if (target?.isConnected) target.focus({ preventScroll: true })
  }

  backdropClose(event) {
    if (event.target === this.panelTarget) this.close()
  }

  sync() {
    const open = this.panelTarget.open
    this.buttonTarget.setAttribute("aria-expanded", open ? "true" : "false")
    this.buttonTarget.setAttribute("aria-label", open ? this.closeLabelValue : this.openLabelValue)
  }
}
