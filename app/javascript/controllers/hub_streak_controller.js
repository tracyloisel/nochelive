import { Controller } from "@hotwired/stimulus"

// Handles streak flame animations.
// is-grew: flame scale pop with orange glow.
// is-break: brief red flash.
// is-shout: enhanced celebration.
// Otherwise static.
export default class extends Controller {
  static targets = ["streak", "num"]
  static values = { tier: String }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.settle()
      return
    }

    this.streakTargets.forEach((streak) => {
      if (!streak.matches(".is-grew, .is-break, .is-shout")) return
      streak.addEventListener("animationend", () => {
        streak.classList.remove("is-grew", "is-break", "is-shout")
      }, { once: true })
    })
  }

  settle() {
    this.streakTargets.forEach((streak) => streak.classList.remove("is-grew", "is-break", "is-shout"))
  }
}
