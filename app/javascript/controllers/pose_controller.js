import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, goal: Number }
  static targets = ["button", "count"]

  hold() {
    if (this.holding) return
    this.holding = true
    this.started = Date.now()
    this.element.classList.add("is-holding")
    if (navigator.vibrate) navigator.vibrate(20)
    this.tick = setInterval(() => this.paint(), 100)
  }

  release() {
    if (!this.holding) return
    this.holding = false
    clearInterval(this.tick)
    this.element.classList.remove("is-holding")
    const held = Date.now() - this.started
    this.paint(held)
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "Content-Type": "application/x-www-form-urlencoded",
        Accept: "text/html"
      },
      body: `held_ms=${held}`
    })
  }

  paint(held = Date.now() - this.started) {
    if (!this.hasCountTarget) return
    this.countTarget.textContent = Math.min(8, Math.floor(held / 1000))
  }
}
