import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"
import { audioLoader } from "platform/audio/loader"
import { http } from "platform/http/client"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { motionDirector } from "runtime/motion/runtime"
import { streetCueGain, streetQuizTimeline } from "runtime/street/quiz_timeline"

const ART_PREVIEW_MS = 1100
const SCORE_MS = 380
const FLY_MS = 520
const ANSWER_COMMIT_MS = 24
const ADVANCE_COMMIT_MS = 160
const SWIPE_DISTANCE = 56
const SWIPE_VELOCITY = 0.4
const GESTURE_AVOID = "button, a, input, textarea, select, label, .quiz-sheet, .quiz-hud, .play-timer, .home-menu, .chrome-tools"

export default class extends Controller {
  static targets = [ "score", "crown", "gain", "streakVideo" ]
  static values = {
    playUrl: String,
    correct: String,
    sfx: String,
    rewindUrl: String,
    fromScore: Number,
    toScore: Number,
    comboShout: String,
    streak: Number,
    fireCue: String,
    previewEnd: String
  }

  connect() {
    this.effectScope = new EffectScope()
    motionDirector.setReducedMotion(this.reduced())
    this.cue()
    this.prefetch()
    this.holdSheet()

    if (this.overlay()) {
      this.connectStreetOverlay()
      return
    }

    this.animateBars()
    this.delayStreetSheet()
    this.payoffScore()
    this.payoffCombo()
    if (this.street()) audioLoader.playFrom(document)
  }

  disconnect() {
    this.releaseGesture()
    this.releaseStreakMedia()
    this.effectScope?.dispose()
  }

  refreshStreetResult() {
    this.releaseGesture()
    this.releaseStreakMedia()
    this.effectScope?.dispose()
    this.effectScope = new EffectScope()
    this.runStreetResult()
  }

  connectStreetOverlay() {
    audioLoader.playFrom(document)
    if (this.element.classList.contains("is-ceremony")) return

    if (this.element.classList.contains("is-settled")) {
      this.runStreetResult()
      return
    }

    this.enterOverlay()
    if (!this.element.classList.contains("is-art-preview")) this.runStreetAskCue()
  }

  runStreetResult() {
    const timeline = streetQuizTimeline({ reduced: this.reduced() }).result
    this.effectScope.timeout(() => {
      this.element.classList.add("is-feedback-ready")
      this.playStreetCue()
      this.playStreakMedia()
      this.effectScope.timeout(() => this.playFireCue(), 90)
    }, timeline.feedback)
    this.effectScope.timeout(() => this.animateBars(), timeline.bars)
    this.effectScope.timeout(() => {
      this.element.classList.add("is-reward-ready")
      this.payoffScore()
      this.payoffCombo()
    }, timeline.reward)
    this.effectScope.timeout(() => this.element.classList.add("is-actions-ready"), timeline.actions)
  }

  runStreetAskCue() {
    if (!audioLoader.unlocked()) return
    const delay = streetQuizTimeline({ reduced: this.reduced() }).ask.cue
    this.effectScope.timeout(() => this.playStreetCue(), delay)
  }

  playStreetCue() {
    if (!audioLoader.unlocked() || !this.sfxValue) return
    audioLoader.play(this.sfxValue, streetCueGain(this.sfxValue))
  }

  playFireCue() {
    if (!audioLoader.unlocked() || !this.hasFireCueValue || !this.fireCueValue) return
    audioLoader.play(this.fireCueValue, streetCueGain(this.fireCueValue))
  }

  playStreakMedia() {
    if (this.reduced() || !this.hasStreakVideoTarget || window.matchMedia("(max-width: 480px)").matches) return
    this.streakVideoTargets.forEach((video) => {
      video.currentTime = 0
      video.play().catch(() => {})
    })
  }

  releaseStreakMedia() {
    if (!this.hasStreakVideoTarget) return
    this.streakVideoTargets.forEach((video) => {
      video.pause()
      video.currentTime = 0
    })
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
        haptic(this.streakValue > 0 ? "streakBreak" : "miss")
        this.element.querySelector(`[data-choice-key="${CSS.escape(correct)}"]`)?.classList.add("is-right")
      }
    }
    if (this.overlay() && !this.reduced()) {
      const form = button.closest("form")
      if (!form) return
      event.preventDefault()
      this.element.classList.add("is-committing")
      this.effectScope.timeout(() => form.requestSubmit(button), ANSWER_COMMIT_MS)
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
      if (this.element.classList.contains("is-advancing")) {
        event?.preventDefault()
        return
      }
      if (this.reduced()) return
      const button = event?.currentTarget
      const form = button?.closest("form")
      if (!form) return
      event.preventDefault()
      this.element.classList.add("is-advancing")
      this.effectScope.timeout(() => form.requestSubmit(button), ADVANCE_COMMIT_MS)
      return
    }
    if (this.street()) return
    this.element.classList.add("is-leaving")
  }

  advance() {
    if (!this.street()) return
    const button = this.element.querySelector(".quiz-next")
    if (!button) return
    button.click()
  }

  rewind() {
    if (!this.street()) return
    if (!this.hasRewindUrlValue || !this.rewindUrlValue) return
    http.turboStream(this.rewindUrlValue, { method: "POST" }).catch(() => {})
  }

  startGesture(event) {
    if (!this.overlay() || !this.element.classList.contains("is-settled") || this.element.classList.contains("is-ceremony")) return
    if (event.pointerType === "mouse" && event.button !== 0) return
    if (event.target.closest(GESTURE_AVOID)) return

    this.releaseGesture()
    this.gesture = {
      pointerId: event.pointerId,
      startX: event.clientX,
      lastX: event.clientX,
      lastAt: performance.now(),
      velocityX: 0
    }
    this.gestureReleases = [
      this.effectScope.listen(window, "pointermove", this.moveGesture),
      this.effectScope.listen(window, "pointerup", this.endGesture),
      this.effectScope.listen(window, "pointercancel", this.cancelGesture)
    ]
  }

  moveGesture = (event) => {
    if (!this.gesture || event.pointerId !== this.gesture.pointerId) return
    const now = performance.now()
    const elapsed = Math.max(1, now - this.gesture.lastAt)
    this.gesture.velocityX = (event.clientX - this.gesture.lastX) / elapsed
    this.gesture.lastX = event.clientX
    this.gesture.lastAt = now
  }

  endGesture = (event) => {
    if (!this.gesture || event.pointerId !== this.gesture.pointerId) return
    const dx = event.clientX - this.gesture.startX
    const velocityX = this.gesture.velocityX
    this.releaseGesture()
    if (Math.abs(dx) < SWIPE_DISTANCE && Math.abs(velocityX) < SWIPE_VELOCITY) return
    if (dx > 0 || velocityX > SWIPE_VELOCITY) this.rewind()
    else this.advance()
  }

  cancelGesture = (event) => {
    if (!this.gesture || event.pointerId !== this.gesture.pointerId) return
    this.releaseGesture()
  }

  releaseGesture() {
    this.gestureReleases?.forEach((release) => release())
    this.gestureReleases = null
    this.gesture = null
  }

  animateBars() {
    const fills = this.element.querySelectorAll(".quiz-fill")
    if (!fills.length) return

    const reduced = this.reduced()
    const street = this.street()
    fills.forEach((fill) => {
      const share = Math.max(0, Math.min(1, Number(fill.dataset.share || 0) / 100))
      if (reduced) {
        fill.style.transform = `scaleX(${share})`
        return
      }
      fill.style.transform = "scaleX(0)"
      const duration = street ? 520 : 300
      fill.style.transition = `transform ${duration}ms cubic-bezier(0.22, 1, 0.36, 1)`
      this.effectScope.frame(() => {
        this.effectScope.frame(() => { fill.style.transform = `scaleX(${share})` })
      })
    })
  }

  prefetch() {
    if (this.playUrlValue) {
      this.element.dispatchEvent(new CustomEvent("noche:prefetch", {
        bubbles: true,
        detail: { key: "screen.next", url: this.playUrlValue }
      }))
    }
  }

  cue() {
    if (this.street()) return
    if (!this.sfxValue) return
    audioLoader.play(this.sfxValue)
  }

  street() {
    return this.element.id === "street_quiz" || !!this.element.closest("#street_quiz")
  }

  overlay() {
    return this.street() && this.element.classList.contains("is-overlay")
  }

  releaseStreetAsk() {
    if (!this.street()) return
    const preserveBed = this.element.dataset.stageBedPolicyValue === "continuous"
    audioLoader.releaseAsk({ preserveBed })
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
    this.effectScope.timeout(() => {
      sheet.classList.add("is-arriving")
      this.effectScope.timeout(() => sheet.classList.remove("is-arriving"), 420)
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
    this.effectScope.timeout(() => this.revealArt(), delay)
  }

  revealArt() {
    if (!this.element.classList.contains("is-art-preview")) return
    this.element.classList.remove("is-art-preview")
    this.releaseAskCountdown()
    this.element.classList.add("is-entering")
    const timeline = streetQuizTimeline({ reduced: this.reduced() }).ask
    this.runStreetAskCue()
    this.effectScope.timeout(() => this.element.classList.remove("is-entering"), timeline.unlock)
  }

  releaseAskCountdown() {
    const timer = this.element.querySelector("[data-controller~='countdown']")
    if (!timer) return
    const countdown = this.application.getControllerForElementAndIdentifier(timer, "countdown")
    countdown?.releaseAsk()
  }

  payoffScore() {
    if (!this.overlay() || !this.hasScoreTarget) return
    if (this.element.classList.contains("is-ceremony")) return
    const from = Number(this.fromScoreValue)
    const to = Number(this.toScoreValue)
    if (!Number.isFinite(from) || !Number.isFinite(to) || from === to) {
      this.writeScore(to || from || 0)
      return
    }
    this.writeScore(from)
    if (this.reduced() || !this.hasGainTarget) {
      this.landScore(from, to)
      return
    }
    this.flyGain(from, to)
  }

  flyGain(from, to) {
    const gain = this.gainTarget
    const destEl = this.hasCrownTarget ? this.crownTarget : this.scoreTarget
    const start = gain.getBoundingClientRect()
    const dest = destEl.getBoundingClientRect()
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
    this.effectScope.frame(() => {
      const dx = dest.left + dest.width / 2 - (start.left + start.width / 2)
      const dy = dest.top + dest.height / 2 - (start.top + start.height / 2)
      flyer.style.transform = `translate(${dx}px, ${dy}px) scale(0.55)`
      flyer.style.opacity = "0.2"
    })
    this.effectScope.timeout(() => {
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
      this.effectScope.timeout(() => spark.remove(), FLY_MS + 80)
    })
  }

  landScore(from, to) {
    this.hasCrownTarget && this.crownTarget.classList.add("is-land")
    this.tweenScore(from, to)
  }

  tweenScore(from, to) {
    if (!this.hasScoreTarget) return
    if (this.reduced()) {
      this.writeScore(to)
      return
    }
    const controls = motionDirector.count(from, to, {
      duration: SCORE_MS / 1000,
      onUpdate: (value) => { this.writeScore(Math.round(value)) }
    })
    this.effectScope.animation(controls)
  }

  writeScore(value) {
    this.scoreTargets.forEach((target) => { target.textContent = String(value) })
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
