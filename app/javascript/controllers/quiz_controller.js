import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    playUrl: String,
    correct: String,
    nextImage: String,
    sfx: String,
    rewindUrl: String
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
    if (this.street()) return
    this.element.classList.add("is-leaving")
  }

  advance() {
    if (!this.street()) return
    const button = this.element.querySelector(".quiz-next")
    if (!button) return
    this.next()
    button.click()
  }

  rewind() {
    if (!this.street()) return
    if (!this.hasRewindUrlValue || !this.rewindUrlValue) return
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.rewindUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token || "",
        Accept: "text/vnd.turbo-stream.html"
      },
      credentials: "same-origin"
    }).then((res) => res.text()).then((html) => {
      if (html && window.Turbo) window.Turbo.renderStreamMessage(html)
    }).catch(() => {})
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
    if (this.street()) return
    if (!this.sfxValue) return
    if (window.NocheLiveAudio?.play) {
      window.NocheLiveAudio.play(this.sfxValue)
      return
    }
    const stage = this.application.getControllerForElementAndIdentifier(document.body, "stage")
    stage?.play(this.sfxValue)
  }

  street() {
    return this.element.id === "street_quiz" || !!this.element.closest("#street_quiz")
  }

  holdSheet() {
    if (this.street()) return
    const sheetEl = this.element.closest("[data-controller~='sheet']")
    if (!sheetEl) return
    const sheet = this.application.getControllerForElementAndIdentifier(sheetEl, "sheet")
    sheet?.snapTo("open", false)
  }
}
