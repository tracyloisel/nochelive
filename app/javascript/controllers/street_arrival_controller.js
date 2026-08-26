import { Controller } from "@hotwired/stimulus"

const DELAY = 1400

export default class extends Controller {
  connect() {
    this.armed = true
    this.element.classList.add("is-armed")
    if (this.reduced()) {
      this.ready()
      return
    }
    this.timer = window.setTimeout(() => this.ready(), DELAY)
  }

  skip(event) {
    if (this.element.classList.contains("is-ready")) return
    if (event.target.closest(".street-wizard-panel")) return
    event.preventDefault()
    this.ready()
  }

  ready() {
    if (this.element.classList.contains("is-ready")) return
    window.clearTimeout(this.timer)
    this.element.classList.add("is-ready")
    const audio = window.NocheLiveAudio
    if (audio?.unlocked && !audio.muted) audio.play?.("round_open")
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  disconnect() {
    window.clearTimeout(this.timer)
  }
}
