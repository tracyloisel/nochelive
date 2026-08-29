import { Controller } from "@hotwired/stimulus"
import { audioLoader } from "platform/audio/loader"

export default class extends Controller {
  connect() {
    this.hide = this.hide.bind(this)
    this.element.addEventListener("animationend", this.hide)
    document.addEventListener("turbo:before-cache", this.hide)
    this.playSignature()
  }

  disconnect() {
    this.element.removeEventListener("animationend", this.hide)
    document.removeEventListener("turbo:before-cache", this.hide)
  }

  hide(event) {
    if (event.type === "animationend") {
      if (event.target !== this.element) return
      if (![ "banner-bloom", "banner-fade" ].includes(event.animationName)) return
    }
    this.element.hidden = true
  }

  playSignature() {
    if (this.element.hidden || this.element.classList.contains("banner-alert")) return
    if (!audioLoader.unlocked() || audioLoader.muted()) return

    audioLoader.play("notification_glint", 0.54)
  }
}
