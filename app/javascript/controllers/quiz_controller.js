import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    playUrl: String,
    correct: String,
    nextImage: String,
    sfx: String
  }

  connect() {
    this.cue()
    this.animateBars()
    this.prefetch()
    this.holdSheet()
  }

  pick(event) {
    const button = event.target.closest(".choice-btn")
    if (!button) return
    if (this.element.classList.contains("is-locked")) {
      event.preventDefault()
      event.stopPropagation()
      return
    }
    this.element.classList.add("is-locked")
    button.classList.add("is-picked")
    const key = button.dataset.choiceKey
    const correct = this.correctValue
    if (key && correct) {
      if (key === correct) {
        button.classList.add("is-right")
      } else {
        button.classList.add("is-wrong")
        this.element.querySelector(`[data-choice-key="${CSS.escape(correct)}"]`)?.classList.add("is-right")
      }
    }
  }

  lock(event) {
    if (this.element.classList.contains("is-locked")) return
    this.element.classList.add("is-locked")
    event.detail?.formSubmission?.submitter?.classList.add("is-picked")
  }

  next() {
    this.element.classList.add("is-leaving")
  }

  animateBars() {
    const fills = this.element.querySelectorAll(".quiz-fill")
    if (!fills.length) return

    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    fills.forEach((fill) => {
      const share = `${fill.dataset.share || 0}%`
      if (reduced) {
        fill.style.width = share
        return
      }
      fill.style.width = "0%"
      fill.style.transition = "width 300ms cubic-bezier(0.22, 1, 0.36, 1)"
      requestAnimationFrame(() => {
        requestAnimationFrame(() => { fill.style.width = share })
      })
    })
  }

  prefetch() {
    if (this.playUrlValue) {
      fetch(this.playUrlValue, { headers: { Accept: "text/html" }, credentials: "same-origin" }).catch(() => {})
    }
    if (this.hasNextImageValue && this.nextImageValue) {
      const img = new Image()
      img.src = this.nextImageValue
    }
  }

  cue() {
    if (!this.sfxValue) return
    const stage = this.application.getControllerForElementAndIdentifier(document.body, "stage")
    stage?.play(this.sfxValue)
  }

  holdSheet() {
    const sheetEl = this.element.closest("[data-controller~='sheet']")
    if (!sheetEl) return
    const sheet = this.application.getControllerForElementAndIdentifier(sheetEl, "sheet")
    sheet?.snapTo("open", false)
  }
}
