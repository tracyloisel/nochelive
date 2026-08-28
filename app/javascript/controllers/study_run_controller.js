import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"

export default class extends Controller {
  static values = { reveal: Boolean, correct: Boolean }

  connect() {
    requestAnimationFrame(() => this.element.classList.add("is-ready"))
    if (!this.revealValue) return
    this.element.dataset.studyRunRevealValue = "false"

    const url = new URL(window.location.href)
    url.searchParams.delete("reveal")
    window.history.replaceState(window.history.state, "", `${url.pathname}${url.search}${url.hash}`)

    this.feedbackTimer = window.setTimeout(() => {
      haptic(this.correctValue ? "success" : "miss")
      window.NocheLiveAudio?.play?.(this.correctValue ? "study_light" : "study_miss", this.correctValue ? 0.68 : 0.42)
    }, 160)
  }

  disconnect() {
    if (this.feedbackTimer) window.clearTimeout(this.feedbackTimer)
  }

  submitStart(event) {
    const form = event.target
    if (!form?.action?.includes("/suivant")) return
    this.element.classList.add("is-leaving")
    window.NocheLiveAudio?.play?.("study_turn", 0.5)
  }

}
