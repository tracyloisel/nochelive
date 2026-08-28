import { Controller } from "@hotwired/stimulus"

// Enhanced countdown controller with seconds slide and LIVE state transition.
export default class extends Controller {
  static targets = [ "when", "clock", "hours", "minutes", "seconds", "badge", "join" ]
  static values = { startsAt: String, state: String }

  connect() {
    this.tick = this.tick.bind(this)
    this.tick()
    if (this.stateValue !== "playing" && this.stateValue !== "none") {
      this.timer = setInterval(this.tick, 1000)
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    if (!this.hasStartsAtValue || this.stateValue === "playing" || this.stateValue === "none") return
    const start = Date.parse(this.startsAtValue)
    if (Number.isNaN(start)) return
    this.paintWhen(start)

    // Check if state changed to playing
    const delta = start - Date.now()
    if (delta <= 0) {
      this.handleLiveStart()
      return
    }

    // Near-live accent (< 1 hour)
    if (delta < 3600000) {
      this.clockTarget?.classList.add("is-urgent")
    } else {
      this.clockTarget?.classList.remove("is-urgent")
    }

    if (this.hasClockTarget) this.clockTarget.classList.add("is-on")
    const hours = Math.floor(delta / 3_600_000)
    const mins = Math.floor((delta % 3_600_000) / 60_000)
    const secs = Math.floor((delta % 60_000) / 1000)

    // Seconds slide animation
    if (this.hasSecondsTarget) {
      const oldText = this.secondsTarget.textContent
      const newText = String(secs).padStart(2, "0")
      if (oldText !== newText) {
        this.secondsTarget.classList.add("is-digit-slide")
        this.secondsTarget.textContent = newText
        setTimeout(() => this.secondsTarget.classList.remove("is-digit-slide"), 150)
      }
    }

    if (this.hasHoursTarget) this.hoursTarget.textContent = String(hours).padStart(2, "0")
    if (this.hasMinutesTarget) this.minutesTarget.textContent = String(mins).padStart(2, "0")
  }

  handleLiveStart() {
    clearInterval(this.timer)
    this.stateValue = "playing"
    window.NocheLiveAudio?.play?.("round_open", 0.66)
    if (this.hasClockTarget) this.clockTarget.classList.remove("is-on")
    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = this.badgeTarget.dataset.liveLabel
      this.badgeTarget.classList.add("is-live", "is-live-start")
      this.badgeTarget.addEventListener("animationend", () => {
        this.badgeTarget.classList.remove("is-live-start")
        this.badgeTarget.classList.add("is-breathe")
      }, { once: true })
    }
    this.element.classList.add("is-playing", "is-live-start")
    this.element.addEventListener("animationend", () => this.element.classList.remove("is-live-start"), { once: true })
    if (this.hasJoinTarget) this.joinTarget.hidden = false
  }

  paintWhen(start) {
    if (!this.hasWhenTarget) return
    const date = new Date(start)
    const lang = document.documentElement.lang || "es"
    const weekday = new Intl.DateTimeFormat(lang, { weekday: "long" }).format(date)
    const day = weekday.charAt(0).toUpperCase() + weekday.slice(1)
    this.whenTarget.textContent = `${day} ${this.clockLabel(date, lang)}`
    this.whenTarget.hidden = false
    this.whenTarget.classList.remove("is-clock-only")
  }

  clockLabel(date, lang) {
    const hour = date.getHours()
    const min = date.getMinutes()
    if (lang.startsWith("fr") || lang.startsWith("pt")) {
      return min === 0 ? `${hour}h` : `${hour}h${String(min).padStart(2, "0")}`
    }
    if (lang.startsWith("en")) {
      const ampm = hour >= 12 ? "pm" : "am"
      const twelve = ((hour + 11) % 12) + 1
      return min === 0 ? `${twelve}${ampm}` : `${twelve}:${String(min).padStart(2, "0")}${ampm}`
    }
    return `${String(hour).padStart(2, "0")}:${String(min).padStart(2, "0")}`
  }
}
