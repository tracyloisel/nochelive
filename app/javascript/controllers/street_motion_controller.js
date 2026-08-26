import { Controller } from "@hotwired/stimulus"

const DURATIONS = {
  packComplete: 2600,
  packUnlock: 2100,
  duelReveal: 1200,
  answerCorrect: 400
}

const PACK_UNLOCK = {
  rope: 400,
  lock: 200,
  land: 400,
  stars: 700,
  pulse: 1200
}

export default class extends Controller {
  static values = { sequence: String }

  connect() {
    if (!this.sequenceValue) return
    this.run(this.sequenceValue)
  }

  run(name) {
    if (this.reduced()) {
      this.instantComplete(name)
      return
    }
    this.element.classList.add("is-sequence-running")
    const duration = DURATIONS[name] || 0
    if (name === "packComplete") this.packComplete()
    if (name === "packUnlock") this.packUnlock()
    if (name === "duelReveal") this.element.classList.add("is-duel-reveal")
    if (duration > 0) {
      this.skipTimer = window.setTimeout(() => this.finishSequence(), duration)
      window.setTimeout(() => this.element.classList.add("is-skip-ready"), 1000)
      this.element.addEventListener("click", this.skip, { once: true })
      this.element.addEventListener("keydown", this.skipKey, { once: true })
    }
  }

  skip = (event) => {
    if (!this.element.classList.contains("is-skip-ready")) return
    if (event.target.closest("a, button, input, select, textarea, summary")) return
    this.finishSequence(true)
  }

  skipKey = (event) => {
    if (event.key !== "Escape" && event.key !== " ") return
    event.preventDefault()
    this.finishSequence(true)
  }

  finishSequence(skipped = false) {
    window.clearTimeout(this.skipTimer)
    this.phaseTimers?.forEach((timer) => window.clearTimeout(timer))
    this.phaseTimers = []
    this.element.classList.add("is-sequence-done")
    if (skipped) this.instantComplete(this.sequenceValue)
  }

  packComplete() {
    const score = this.element.querySelector(".score-fly")
    const chest = this.element.querySelector(".street-ceremony-chest")
    chest?.classList.add("is-opening")
    window.NocheLiveAudio?.play?.("chest")

    if (score) {
      const final = parseInt(score.dataset.final || score.textContent, 10)
      const start = performance.now()
      const tick = (now) => {
        const t = Math.min(1, (now - start) / 700)
        score.textContent = Math.round(final * t)
        if (t < 1) requestAnimationFrame(tick)
      }
      requestAnimationFrame(tick)
    }

    this.phase(620, () => {
      this.element.classList.add("is-stars-phase")
      this.element.querySelectorAll(".star-pop.is-filled").forEach((star, i) => {
        star.style.animationDelay = `${i * 130}ms`
        star.classList.add("is-popping")
      })
      window.NocheLiveAudio?.play?.("correct_gold")
    })

    this.phase(1050, () => {
      this.element.querySelectorAll(".board-rise").forEach((board, i) => {
        board.style.animationDelay = `${i * 90}ms`
        board.classList.add("is-rising")
      })
    })
  }

  packUnlock() {
    const pack = this.element
    const rope = pack.previousElementSibling?.classList?.contains("street-map-rope") ? pack.previousElementSibling : null
    let t = 0

    if (rope) rope.classList.add("is-unfurling")

    t += PACK_UNLOCK.rope
    this.phase(t, () => {
      pack.classList.add("is-lock-breaking")
      pack.querySelector(".street-pack-lock")?.classList.add("is-breaking")
    })

    t += PACK_UNLOCK.lock
    this.phase(t, () => {
      pack.classList.remove("is-locked", "is-unlocking")
      pack.classList.add("is-current", "is-landing")
      pack.querySelector(".street-pack-lock")?.remove()
      pack.querySelector(".street-pack-play-wrap")?.removeAttribute("hidden")
    })

    t += PACK_UNLOCK.land
    this.phase(t, () => {
      pack.classList.add("is-stars-reveal")
      pack.querySelectorAll(".street-star").forEach((star, i) => {
        star.style.animationDelay = `${i * 120}ms`
      })
      window.NocheLiveAudio?.play?.("chest")
    })

    t += PACK_UNLOCK.stars
    this.phase(t, () => {
      pack.classList.remove("is-landing")
      pack.classList.add("is-pulse-active")
    })
  }

  phase(ms, fn) {
    const timer = window.setTimeout(fn, ms)
    this.phaseTimers = this.phaseTimers || []
    this.phaseTimers.push(timer)
  }

  instantComplete(name) {
    if (name === "packUnlock") {
      const pack = this.element
      const rope = pack.previousElementSibling?.classList?.contains("street-map-rope") ? pack.previousElementSibling : null
      rope?.classList.add("is-unfurled")
      pack.classList.remove("is-locked", "is-unlocking", "is-lock-breaking", "is-landing")
      pack.classList.add("is-current", "is-pulse-active", "is-stars-reveal")
      pack.querySelector(".street-pack-lock")?.remove()
      pack.querySelector(".street-pack-play-wrap")?.removeAttribute("hidden")
      return
    }

    if (name === "packComplete") {
      const score = this.element.querySelector(".score-fly")
      if (score?.dataset.final) score.textContent = score.dataset.final
      this.element.querySelector(".street-ceremony-chest")?.classList.add("is-opening")
      this.element.classList.add("is-stars-phase")
      this.element.querySelectorAll(".star-pop.is-filled").forEach((star) => star.classList.add("is-popping"))
      this.element.querySelectorAll(".board-rise").forEach((board) => board.classList.add("is-rising"))
      return
    }

    if (name === "duelReveal") {
      this.element.classList.add("is-duel-reveal")
      return
    }

    const score = this.element.querySelector(".score-fly")
    if (score?.dataset.final) score.textContent = score.dataset.final
    this.element.querySelectorAll(".star-pop").forEach((node) => node.classList.add("is-filled"))
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  disconnect() {
    window.clearTimeout(this.skipTimer)
    this.phaseTimers?.forEach((timer) => window.clearTimeout(timer))
    this.element.removeEventListener("click", this.skip)
    this.element.removeEventListener("keydown", this.skipKey)
  }
}
