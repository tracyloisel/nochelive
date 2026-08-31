import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "hours", "minutes", "seconds" ]
  static values = { end: String, url: String }

  connect() {
    if (!this.hasHoursTarget || !this.hasMinutesTarget || !this.hasSecondsTarget || !this.hasEndValue) return
    this.endAt = Date.parse(this.endValue)
    this.tick()
  }

  disconnect() { clearTimeout(this.timer) }

  tick() {
    const left = Math.max(0, this.endAt - Date.now())
    const total = Math.ceil(left / 1000)
    this.hoursTarget.textContent = String(Math.floor(total / 3600)).padStart(2, "0")
    this.minutesTarget.textContent = String(Math.floor((total % 3600) / 60)).padStart(2, "0")
    this.secondsTarget.textContent = String(total % 60).padStart(2, "0")
    if (left <= 0) {
      window.location.replace(this.urlValue)
      return
    }
    this.timer = setTimeout(() => this.tick(), Math.min(1000, left))
  }
}
