import { Controller } from "@hotwired/stimulus"

const AVOID = "button, a, input, textarea, select, label, .buzz, .choice-btn, .quiz-bar, .quiz-next, .btn, .story-sheet, .play-sheet, .desk-sheet, .play-sheet-body, .play-sheet-grip, .claim-veil, .claim-modal, .scripture-veil, .scripture-sheet"
const STREET_AVOID = "button, a, input, textarea, select, label, .buzz, .choice-btn, .quiz-bar, .quiz-next, .btn, .play-sheet, .play-sheet-body, .play-sheet-grip, .street-shot-actions, .street-score, .play-timer, .home-menu, .chrome-tools, .mute, .lang-switch, .claim-veil, .claim-modal, .profile-gate, .scripture-veil, .scripture-sheet, .quiz-hud, .quiz-sheet, .quiz-scripture, .quiz-dock, .quiz-hud-streak"

export default class extends Controller {
  static targets = [ "page", "sheet", "tick", "liveChip", "score", "scoreBtn" ]
  static values = {
    exitUrl: String,
    street: { type: Boolean, default: false },
    index: { type: Number, default: 0 },
    liveIndex: { type: Number, default: 0 }
  }

  connect() {
    this.dragging = false
    this.exiting = false
    this.scoreOpen = false
    this.paintScore()
    this.onMove = this.onMove.bind(this)
    this.onUp = this.onUp.bind(this)
    this.onKey = this.onKey.bind(this)
    window.addEventListener("keydown", this.onKey)
    this.show(this.indexValue, false)
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKey)
    this.unbind()
  }

  start(event) {
    if (this.exiting) return
    if (event.pointerType === "mouse" && event.button !== 0) return
    if (event.target.closest(this.streetMode() ? STREET_AVOID : AVOID)) return

    this.dragging = true
    this.moved = false
    this.axis = null
    this.startX = event.clientX
    this.startY = event.clientY
    this.lastX = event.clientX
    this.lastY = event.clientY
    this.lastAt = performance.now()
    this.vx = 0
    this.vy = 0
    this.element.classList.add("is-pulling")
    event.target.setPointerCapture?.(event.pointerId)
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onUp)
  }

  onMove(event) {
    if (!this.dragging) return
    const dx = event.clientX - this.startX
    const dy = event.clientY - this.startY
    if (!this.axis && (Math.abs(dx) > 8 || Math.abs(dy) > 8)) {
      this.axis = Math.abs(dx) > Math.abs(dy) ? "x" : "y"
      this.moved = true
    }
    const now = performance.now()
    const dt = Math.max(1, now - this.lastAt)
    this.vx = (event.clientX - this.lastX) / dt
    this.vy = (event.clientY - this.lastY) / dt
    this.lastX = event.clientX
    this.lastY = event.clientY
    this.lastAt = now

    if (this.axis === "y" && dy > 0 && !this.streetMode()) {
      const p = Math.min(1, dy / (window.innerHeight * 0.45))
      this.element.style.setProperty("--story-pull", `${dy * 0.92}px`)
      this.element.style.setProperty("--story-scale", String(1 - p * 0.08))
    } else if (this.axis === "x") {
      this.element.style.setProperty("--story-nudge", `${dx * 0.35}px`)
    }
  }

  onUp(event) {
    if (!this.dragging) return
    this.dragging = false
    this.element.classList.remove("is-pulling")
    this.unbind()
    const x = event.clientX ?? this.lastX
    const y = event.clientY ?? this.lastY
    const dx = x - this.startX
    const dy = y - this.startY

    if (!this.moved) {
      if (!this.streetMode() || event.target.closest(".play-shot")) this.tap(this.startX)
      this.clearPull()
      return
    }

    if (this.axis === "y") {
      if (this.streetMode()) {
        this.clearPull()
        return
      }
      if (dy > 88 || this.vy > 0.5) {
        this.exit()
        return
      }
      if (dy < -56 || this.vy < -0.5) this.openSheet()
    } else if (this.axis === "x") {
      if (dx < -56 || this.vx < -0.4) this.next()
      else if (dx > 56 || this.vx > 0.4) this.prev()
    }
    this.clearPull()
  }

  tap(x) {
    const rect = this.element.getBoundingClientRect()
    const t = (x - rect.left) / Math.max(1, rect.width)
    if (t < 0.28) this.prev()
    else this.next()
  }

  prev() {
    if (this.streetMode()) {
      this.streetQuiz()?.rewind()
      return
    }
    if (this.indexValue <= 0) return
    this.show(this.indexValue - 1, true)
  }

  next() {
    if (this.streetMode()) {
      this.streetQuiz()?.advance()
      return
    }
    if (this.pageTargets.length === 0) return
    if (this.indexValue >= this.pageTargets.length - 1) {
      this.openSheet()
      return
    }
    this.show(this.indexValue + 1, true)
  }

  streetMode() {
    return this.streetValue || this.element.id === "street_quiz"
  }

  streetQuiz() {
    return this.application.getControllerForElementAndIdentifier(this.element, "quiz")
  }

  jump(event) {
    const index = Number(event.currentTarget.dataset.storyIndex)
    if (Number.isFinite(index)) this.show(index, true)
  }

  live() {
    this.show(this.liveIndexValue, true)
  }

  toggleScore(event) {
    event.preventDefault()
    event.stopPropagation()
    this.scoreOpen = !this.scoreOpen
    this.paintScore()
  }

  paintScore() {
    if (this.hasScoreTarget) this.scoreTarget.hidden = !this.scoreOpen
    if (this.hasScoreBtnTarget) this.scoreBtnTarget.setAttribute("aria-expanded", this.scoreOpen ? "true" : "false")
    this.element.classList.toggle("is-score", this.scoreOpen)
  }

  show(index, animate) {
    const max = this.pageTargets.length - 1
    if (max < 0) {
      this.paintAway(false)
      return
    }

    const next = Math.min(max, Math.max(0, index))
    this.indexValue = next
    this.element.classList.toggle("is-paging", animate && !this.reduced())
    this.pageTargets.forEach((page, i) => {
      const on = i === next
      page.classList.toggle("is-on", on)
      page.hidden = !on
    })
    this.tickTargets.forEach((tick, i) => {
      const on = i === next
      tick.closest("li")?.classList.toggle("is-now", on)
      tick.setAttribute("aria-current", on ? "step" : "false")
    })
    this.paintAway(next !== this.liveIndexValue)
    if (animate) window.setTimeout(() => this.element.classList.remove("is-paging"), 420)
  }

  paintAway(away) {
    this.element.classList.toggle("is-away", away)
    if (this.hasLiveChipTarget) {
      this.liveChipTarget.setAttribute("aria-current", away ? "false" : "true")
    }
  }

  openSheet() {
    if (!this.hasSheetTarget) return
    const sheet = this.application.getControllerForElementAndIdentifier(this.sheetTarget, "sheet")
    if (!sheet) return
    const next = sheet.snapValue === "open" ? "open" : (sheet.snapValue === "mid" ? "open" : "mid")
    sheet.snapTo(next, true)
  }

  exit(event) {
    event?.preventDefault()
    if (this.exiting) return
    const url = this.exitUrlValue
    if (!url) return
    this.exiting = true
    this.clearPull()
    if (this.reduced()) {
      this.visit(url)
      return
    }
    this.element.classList.add("is-leaving")
    window.setTimeout(() => this.visit(url), 280)
  }

  visit(url) {
    if (window.Turbo?.visit) window.Turbo.visit(url)
    else window.location.href = url
  }

  onKey(event) {
    if (event.defaultPrevented) return
    const typing = event.target.closest("input, textarea, select")
    if (typing) return
    if (event.key === "Escape") {
      if (this.scoreOpen) {
        event.preventDefault()
        this.scoreOpen = false
        this.paintScore()
        return
      }
      if (!this.streetMode()) this.exit(event)
    }
    if (event.key === "ArrowLeft") this.prev()
    if (event.key === "ArrowRight") this.next()
    if (event.key === "ArrowUp" && !this.streetMode()) this.openSheet()
  }

  clearPull() {
    this.element.style.removeProperty("--story-pull")
    this.element.style.removeProperty("--story-scale")
    this.element.style.removeProperty("--story-nudge")
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  unbind() {
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
  }
}
