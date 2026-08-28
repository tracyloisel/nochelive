import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"

const ART_PREVIEW_MS = 1100
const ENTER_LOCK_MS = 700
const SCORE_MS = 380
const FLY_HOLD_MS = 280
const FLY_MS = 520
const ANSWER_COMMIT_MS = 140
const ADVANCE_COMMIT_MS = 160

export default class extends Controller {
  static targets = [ "score", "crown", "gain" ]
  static values = {
    playUrl: String,
    correct: String,
    nextImage: String,
    sfx: String,
    rewindUrl: String,
    fromScore: Number,
    toScore: Number,
    comboGrew: Boolean,
    comboBroke: Boolean,
    comboShout: String,
    comboSfx: String,
    previewEnd: String
  }

  connect() {
    this.cue()
    this.animateBars()
    this.prefetch()
    this.holdSheet()
    this.delayStreetSheet()
    this.enterOverlay()
    this.payoffScore()
    this.payoffCombo()
    if (this.street()) window.NocheLiveAudio?.playFrom?.(document)
  }

  disconnect() {
    window.clearTimeout(this.artPreviewTimer)
    window.clearTimeout(this.enterTimer)
  }

  pick(event) {
    const button = event.target.closest(".choice-btn")
    if (!button) return
    if (this.element.classList.contains("is-art-preview") || this.element.classList.contains("is-entering") || this.element.classList.contains("is-locked")) {
      event.preventDefault()
      event.stopPropagation()
      return
    }
    this.element.classList.add("is-locked")
    button.classList.add("is-picked")
    haptic("tap")
    this.releaseStreetAsk()
    const key = button.dataset.choiceKey
    const correct = this.correctValue
    if (key && correct) {
      if (key === correct) {
        button.classList.add("is-right")
        haptic("success")
      } else {
        button.classList.add("is-wrong")
        haptic("miss")
        this.element.querySelector(`[data-choice-key="${CSS.escape(correct)}"]`)?.classList.add("is-right")
      }
    }
    if (this.overlay() && !this.reduced()) {
      const form = button.closest("form")
      if (!form) return
      event.preventDefault()
      this.element.classList.add("is-committing")
      window.setTimeout(() => form.requestSubmit(button), ANSWER_COMMIT_MS)
    }
  }

  lock(event) {
    if (this.element.classList.contains("is-locked")) return
    this.element.classList.add("is-locked")
    this.releaseStreetAsk()
    event.detail?.formSubmission?.submitter?.classList.add("is-picked")
  }

  next(event) {
    if (this.overlay()) {
      if (this.reduced() || this.element.classList.contains("is-advancing")) return
      const button = event?.currentTarget
      const form = button?.closest("form")
      if (!form) return
      event.preventDefault()
      this.element.classList.add("is-advancing")
      window.setTimeout(() => form.requestSubmit(button), ADVANCE_COMMIT_MS)
      return
    }
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

    const reduced = this.reduced()
    const street = this.street()
    fills.forEach((fill, index) => {
      const share = `${fill.dataset.share || 0}%`
      if (reduced) {
        fill.style.width = share
        return
      }
      fill.style.width = "0%"
      const duration = street ? 520 : 300
      const delay = street ? index * 70 : 0
      fill.style.transition = `width ${duration}ms cubic-bezier(0.22, 1, 0.36, 1) ${delay}ms`
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

  overlay() {
    return this.street() && this.element.classList.contains("is-overlay")
  }

  releaseStreetAsk() {
    if (!this.street()) return
    window.NocheLiveAudio?.releaseAsk?.()
  }

  holdSheet() {
    if (this.street()) return
    const sheetEl = this.element.closest("[data-controller~='sheet']")
    if (!sheetEl) return
    const sheet = this.application.getControllerForElementAndIdentifier(sheetEl, "sheet")
    sheet?.snapTo("open", false)
  }

  delayStreetSheet() {
    if (!this.street() || this.overlay()) return
    if (this.element.classList.contains("is-settled")) return
    const sheet = this.element.querySelector(".play-sheet")
    if (!sheet) return
    sheet.classList.remove("is-arriving")
    const delay = this.reduced() ? 0 : 220
    window.setTimeout(() => {
      sheet.classList.add("is-arriving")
      window.setTimeout(() => sheet.classList.remove("is-arriving"), 420)
    }, delay)
  }

  enterOverlay() {
    if (!this.overlay() || this.element.classList.contains("is-settled")) return
    if (this.element.classList.contains("is-ceremony")) return
    if (!this.element.classList.contains("is-art-preview")) return
    if (this.reduced()) {
      this.releaseAskCountdown()
      this.element.classList.remove("is-art-preview")
      return
    }
    const previewEnd = this.hasPreviewEndValue ? Date.parse(this.previewEndValue) : NaN
    const delay = Number.isFinite(previewEnd) ? Math.max(0, previewEnd - Date.now()) : ART_PREVIEW_MS
    this.artPreviewTimer = window.setTimeout(() => this.revealArt(), delay)
  }

  revealArt() {
    if (!this.element.classList.contains("is-art-preview")) return
    window.clearTimeout(this.artPreviewTimer)
    this.element.classList.remove("is-art-preview")
    this.releaseAskCountdown()
    this.element.classList.add("is-entering")
    this.enterTimer = window.setTimeout(() => this.element.classList.remove("is-entering"), ENTER_LOCK_MS)
  }

  releaseAskCountdown() {
    const timer = this.element.querySelector("[data-controller~='countdown']")
    if (!timer) return
    const countdown = this.application.getControllerForElementAndIdentifier(timer, "countdown")
    countdown?.releaseAsk()
  }

  payoffScore() {
    if (!this.overlay() || !this.hasScoreTarget) return
    if (this.element.classList.contains("is-ceremony") && !this.ceremonyPayoffArmed) {
      this.ceremonyPayoffArmed = true
      if (this.reduced()) {
        this.payoffScore()
        return
      }
      window.setTimeout(() => this.payoffScore(), 900)
      return
    }
    const from = Number(this.fromScoreValue)
    const to = Number(this.toScoreValue)
    if (!Number.isFinite(from) || !Number.isFinite(to) || from === to) {
      this.scoreTarget.textContent = String(to || from || 0)
      return
    }
    this.scoreTarget.textContent = String(from)
    if (this.reduced() || !this.hasGainTarget) {
      this.landScore(from, to)
      if (this.hasGainTarget) this.gainTarget.classList.add("is-gone")
      return
    }
    window.setTimeout(() => this.flyGain(from, to), FLY_HOLD_MS)
  }

  flyGain(from, to) {
    const gain = this.gainTarget
    const destEl = this.hasCrownTarget ? this.crownTarget : this.scoreTarget
    const start = gain.getBoundingClientRect()
    const dest = destEl.getBoundingClientRect()
    gain.classList.add("is-gone")
    const flyer = gain.cloneNode(true)
    flyer.removeAttribute("data-quiz-target")
    flyer.classList.add("quiz-score-fly")
    flyer.classList.remove("is-gone")
    flyer.setAttribute("aria-hidden", "true")
    this.element.appendChild(flyer)
    flyer.style.left = `${start.left}px`
    flyer.style.top = `${start.top}px`
    void flyer.offsetWidth
    this.sparkTrail(start, dest)
    requestAnimationFrame(() => {
      const dx = dest.left + dest.width / 2 - (start.left + start.width / 2)
      const dy = dest.top + dest.height / 2 - (start.top + start.height / 2)
      flyer.style.transform = `translate(${dx}px, ${dy}px) scale(0.55)`
      flyer.style.opacity = "0.2"
    })
    window.setTimeout(() => {
      flyer.remove()
      this.landScore(from, to)
    }, FLY_MS)
  }

  sparkTrail(start, dest) {
    const midX = (start.left + dest.left) / 2
    const midY = Math.min(start.top, dest.top) - 36
    ;[ 0.2, 0.4, 0.6, 0.8 ].forEach((t, index) => {
      const spark = document.createElement("span")
      spark.className = "quiz-score-spark"
      spark.setAttribute("aria-hidden", "true")
      const x = (1 - t) * (1 - t) * start.left + 2 * (1 - t) * t * midX + t * t * dest.left
      const y = (1 - t) * (1 - t) * start.top + 2 * (1 - t) * t * midY + t * t * dest.top
      spark.style.left = `${x}px`
      spark.style.top = `${y}px`
      spark.style.animationDelay = `${index * 45}ms`
      this.element.appendChild(spark)
      window.setTimeout(() => spark.remove(), FLY_MS + 80)
    })
  }

  landScore(from, to) {
    this.hasCrownTarget && this.crownTarget.classList.add("is-land")
    this.tweenScore(from, to)
  }

  tweenScore(from, to) {
    if (!this.hasScoreTarget) return
    if (this.reduced()) {
      this.scoreTarget.textContent = String(to)
      return
    }
    const start = performance.now()
    const step = (now) => {
      const t = Math.min(1, (now - start) / SCORE_MS)
      const eased = 1 - Math.pow(1 - t, 3)
      this.scoreTarget.textContent = String(Math.round(from + (to - from) * eased))
      if (t < 1) requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  }

  payoffCombo() {
    if (!this.overlay() || this.element.classList.contains("is-ceremony")) return
    const shout = this.hasComboShoutValue ? this.comboShoutValue : ""
    if (shout === "ten") haptic("legend")
    else if (shout === "five" || shout === "three") haptic("blaze")
    else if (shout) haptic("reward")
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
