import { Controller } from "@hotwired/stimulus"

// Controls XP bar fill animation on the HUD.
// Animates from data-initial-value to data-current-value over 500ms.
// Only animates if the values differ.
export default class extends Controller {
  static targets = ["bar"]
  static values = {
    current: Number,
    initial: Number
  }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.element.classList.add("is-settled")
      return
    }

    if (!this.hasBarTarget) return

    const from = this.hasInitialValue ? this.initialValue : 0
    const to = this.currentValue

    if (from === to) {
      this.element.classList.add("is-settled")
      return
    }

    const bar = this.barTarget
    bar.style.setProperty("--xp-from", `${from}%`)
    bar.style.setProperty("--xp-to", `${to}%`)
    bar.style.animation = "xp-fill 500ms var(--ease-out) both"
    bar.addEventListener("animationend", () => {
      bar.style.animation = ""
      this.element.classList.add("is-settled")
    }, { once: true })
  }
}