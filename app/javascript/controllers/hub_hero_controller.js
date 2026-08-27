import { Controller } from "@hotwired/stimulus"

// Controls the hero card: Ken Burns on artwork, gold particle drift,
// chest metallic sheen, and idle JOUER sheen.
export default class extends Controller {
  static targets = ["still", "chest", "play", "particles"]

  connect() {
    this.timers = []
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.settle()
      return
    }
    this.scheduleChestSheen()
    this.scheduleIdleSheen()
  }

  disconnect() {
    this.timers?.forEach(clearTimeout)
  }

  // Chest metallic sheen every 7–12 seconds (pseudo-random)
  scheduleChestSheen() {
    if (!this.hasChestTarget) return
    const schedule = () => {
      const delay = Math.random() * 5000 + 7000
      this.timers.push(setTimeout(() => {
        this.chestTarget.classList.add("is-sheening")
        const handler = () => {
          this.chestTarget.classList.remove("is-sheening")
          this.chestTarget.removeEventListener("animationend", handler)
          schedule()
        }
        this.chestTarget.addEventListener("animationend", handler)
      }, delay))
    }
    schedule()
  }

  // Idle JOUER sheen after ~4 seconds of inactivity
  scheduleIdleSheen() {
    if (!this.hasPlayTarget) return
    let hasInteracted = false

    const interact = () => { hasInteracted = true }
    this.element.addEventListener("pointerdown", interact, { once: true })
    this.element.addEventListener("focusin", interact, { once: true })

    const trigger = () => {
      if (hasInteracted) return
      this.playTarget.classList.add("is-idle-sheen")
      const handler = () => {
        this.playTarget.classList.remove("is-idle-sheen")
        this.playTarget.removeEventListener("animationend", handler)
      }
      this.playTarget.addEventListener("animationend", handler)

      // Reschedule after a longer idle period
      this.timers.push(setTimeout(trigger, Math.random() * 6000 + 6000))
    }

    this.timers.push(setTimeout(trigger, 4000))
  }

  settle() {
    this.element.classList.add("is-settled")
  }
}
