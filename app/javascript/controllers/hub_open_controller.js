import { Controller } from "@hotwired/stimulus"

// Orchestrates the home page opening sequence.
// The preloaded artwork is visible on first paint; only UI layers are staggered.
// Respects prefers-reduced-motion.
export default class extends Controller {
  connect() {
    this.timers = []
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.settle()
      return
    }
    this.after(100, () => this.element.querySelector(".quiz-hud")?.classList.add("is-arriving"))
    this.after(200, () => this.element.querySelector(".hub-hero")?.classList.add("is-arriving"))
    this.element.querySelectorAll(".hub-live, .hub-panel-row > .hub-panel").forEach((panel, index) => {
      this.after(550 + index * 70, () => panel.classList.add("is-arriving"))
    })
    this.after(650, () => this.element.querySelector(".hub-play")?.classList.add("is-cta-arriving"))
    this.after(980, () => this.settle())
  }

  disconnect() {
    this.timers?.forEach(clearTimeout)
  }

  after(delay, callback) {
    this.timers.push(setTimeout(callback, delay))
  }

  settle() {
    this.element.classList.remove("is-opening")
    this.element.classList.add("is-settled")
  }
}
