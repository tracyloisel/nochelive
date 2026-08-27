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
    if (target === "live_pulses" || target === "night_presence" || target === "quiz_board" || target === "night_play") return
    if (target === "street_quiz") {
      event.detail.render = this.wrapStreet(event.detail.render)
      return
    }
    event.detail.render = this.wrap(event.detail.render)
  }

  onFrame(event) {
    // The community pulse refreshes every five seconds. A document-level view
    // transition for that background update makes unrelated hub chrome blink.
    if (event.target.id === "scripture_reader" || event.target.id === "street_pulse") return
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

  wrapStreet(original) {
    return async (...args) => {
      const run = () => {
        original(...args)
        window.NocheLiveAudio?.playFrom?.(document)
      }
      if (!document.startViewTransition || this.reduced()) return run()

      try {
        const transition = document.startViewTransition(run)
        await transition.finished
      } catch (_error) {
        await run()
      }
    }
  }

  markArrive() {
    if (this.reduced()) return
    document.querySelectorAll(".play-card, .watch, .console, .gate, .reveal, .lock, .claim-modal").forEach((el) => {
      el.classList.remove("is-arriving")
      void el.offsetWidth
      el.classList.add("is-arriving")
    })
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
