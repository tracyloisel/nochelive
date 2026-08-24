import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.onStream = this.onStream.bind(this)
    this.onFrame = this.onFrame.bind(this)
    document.addEventListener("turbo:before-stream-render", this.onStream)
    document.addEventListener("turbo:before-frame-render", this.onFrame)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.onStream)
    document.removeEventListener("turbo:before-frame-render", this.onFrame)
  }

  onStream(event) {
    const target = event.target.getAttribute("target")
    if (target === "live_pulses" || target === "night_presence") return
    event.detail.render = this.wrap(event.detail.render)
  }

  onFrame(event) {
    event.detail.render = this.wrap(event.detail.render)
  }

  wrap(original) {
    return async (...args) => {
      const run = () => original(...args)
      if (!document.startViewTransition || this.reduced()) return run()

      try {
        const transition = document.startViewTransition(run)
        await transition.finished
      } catch (_error) {
        await run()
      }
      this.markArrive()
    }
  }

  markArrive() {
    if (this.reduced()) return
    document.querySelectorAll(".play-card, .watch, .console, .gate, .reveal, .lock, .banner").forEach((el) => {
      el.classList.remove("is-arriving")
      void el.offsetWidth
      el.classList.add("is-arriving")
    })
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
