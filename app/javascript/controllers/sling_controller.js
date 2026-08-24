import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, goal: Number, taps: Number }
  static targets = ["bar", "count"]

  tap() {
    if (this.tapsValue >= this.goalValue) return
    this.tapsValue += 1
    this.paint()
    if (navigator.vibrate) navigator.vibrate(12)
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        Accept: "text/vnd.turbo-stream.html, text/html"
      }
    })
  }

  paint() {
    const pct = Math.min(100, (this.tapsValue * 100) / this.goalValue)
    if (this.hasBarTarget) this.barTarget.style.width = `${pct}%`
    if (this.hasCountTarget) this.countTarget.textContent = this.tapsValue
  }
}
