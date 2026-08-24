import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { end: String }
  static targets = ["label"]

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 250)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const remain = Math.max(0, Math.ceil((Date.parse(this.endValue) - Date.now()) / 1000))
    if (this.hasLabelTarget) this.labelTarget.textContent = remain
  }
}
