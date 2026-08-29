import { Controller } from "@hotwired/stimulus"
import { http } from "platform/http/client"

export default class extends Controller {
  static values = { url: String, goal: Number, taps: Number }
  static targets = ["bar", "count"]

  tap() {
    if (this.tapsValue >= this.goalValue) return
    this.tapsValue += 1
    this.paint()
    if (navigator.vibrate) navigator.vibrate(12)
    http.request(this.urlValue, {
      method: "POST",
    }, { accept: "text/vnd.turbo-stream.html, text/html" }).catch(() => {})
  }

  paint() {
    const pct = Math.min(100, (this.tapsValue * 100) / this.goalValue)
    if (this.hasBarTarget) this.barTarget.style.width = `${pct}%`
    if (this.hasCountTarget) this.countTarget.textContent = this.tapsValue
  }
}
