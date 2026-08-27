import { Controller } from "@hotwired/stimulus"

// Controls friends online green dot animation.
// On connect: dots appear with scale + fade.
// On Turbo frame update: row highlight for new connections.
export default class extends Controller {
  static targets = ["row"]

  connect() {
    this.timers = []
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.settle()
      return
    }

    this.animateDots()
    this.observeTurboUpdates()
  }

  animateDots() {
    this.element.querySelectorAll(".hub-online-presence").forEach((dot, i) => {
      this.timers.push(setTimeout(() => dot.classList.add("is-appearing"), i * 80))
      const handler = () => {
        dot.classList.remove("is-appearing")
        dot.removeEventListener("animationend", handler)
      }
      dot.addEventListener("animationend", handler, { once: true })
    })
  }

  observeTurboUpdates() {
    // Listen for Turbo frame updates to detect new online friends
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === "childList") {
          // New row added or existing row updated
          this.onNewOnline()
        }
      })
    })

    const list = this.element.querySelector(".hub-online-list")
    if (list) {
      this.observer = observer
      observer.observe(list, { childList: true })
    }
  }

  disconnect() {
    this.timers?.forEach(clearTimeout)
    this.observer?.disconnect()
  }

  onNewOnline() {
    // Highlight the most recently added/updated row
    const rows = this.element.querySelectorAll(".hub-online-row")
    if (!rows.length) return

    const lastRow = rows[rows.length - 1]
    lastRow.classList.add("is-highlight")
    setTimeout(() => lastRow.classList.remove("is-highlight"), 600)
  }

  settle() {
    this.element.classList.add("is-settled")
  }
}
