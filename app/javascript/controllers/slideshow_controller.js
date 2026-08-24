import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide"]
  static values = { interval: { type: Number, default: 3500 } }

  connect() {
    if (this.slideTargets.length < 2) return
    this.index = 0
    this.timer = setInterval(() => this.advance(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  advance() {
    this.slideTargets[this.index]?.classList.remove("is-on")
    this.index = (this.index + 1) % this.slideTargets.length
    this.slideTargets[this.index]?.classList.add("is-on")
  }
}
