import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"

const DURATIONS = {
  packComplete: 3800,
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

const SCORE_COUNT_MS = 260
const SCORE_REVEAL_MS = 900
const FIRE_STEP_MS = 300
const CHEST_AFTER_FIRE_MS = 540
const PARTICLE_COUNT = 10

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

  finishSequence() {
    window.clearTimeout(this.skipTimer)
    this.phaseTimers?.forEach((timer) => window.clearTimeout(timer))
    this.phaseTimers = []
    this.element.classList.add("is-sequence-done")
    this.instantComplete(this.sequenceValue)
  }

  packComplete() {
    haptic("legend")
    const fireCount = this.fireCount()
    this.phase(SCORE_REVEAL_MS, () => this.revealFireBonus())
    this.phase(SCORE_REVEAL_MS + (fireCount * FIRE_STEP_MS) + CHEST_AFTER_FIRE_MS, () => this.openChest())
  }

  fireCount() {
    const score = this.element.querySelector(".score-fly")
    return Number(score?.dataset.fireCount || 0)
  }

  revealFireBonus() {
    const score = this.element.querySelector(".score-fly")
    if (!score) return
    const from = Number(score.dataset.from || score.textContent || 0)
    const to = Number(score.dataset.final || from)
    const fireCount = this.fireCount()
    if (fireCount < 1 || from === to) {
      score.textContent = String(to)
      return
    }

    for (let index = 1; index <= fireCount; index += 1) {
      this.phase((index - 1) * FIRE_STEP_MS, () => {
        const fire = this.element.querySelector(`[data-fire-index="${index}"]`)
        fire?.classList.add("is-flying")
        this.element.classList.add("is-fire-phase")
        window.NocheLiveAudio?.play?.("fire_whoosh", 0.58)
        haptic("tap")
        const target = from + Math.round(((to - from) * index) / fireCount)
        this.animateScore(score, Number(score.textContent || from), target)
      })
    }
  }

  animateScore(score, from, to) {
    const start = performance.now()
    const step = (now) => {
      const t = Math.min(1, (now - start) / SCORE_COUNT_MS)
      const eased = 1 - Math.pow(1 - t, 3)
      score.textContent = String(Math.round(from + (to - from) * eased))
      score.classList.toggle("is-boosting", t < 1)
      if (t < 1) requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  }

  openChest() {
    const chest = this.element.querySelector(".street-ceremony-chest")
    chest?.classList.add("is-opening")
    this.element.classList.add("is-stars-phase")
    window.NocheLiveAudio?.play?.("chest")
    this.burstParticles()
  }

  burstParticles() {
    const host = this.element.querySelector(".street-ceremony-chest-wrap") || this.element
    const rect = host.getBoundingClientRect()
    for (let i = 0; i < PARTICLE_COUNT; i += 1) {
      const speck = document.createElement("span")
      speck.className = "street-ceremony-spark"
      speck.setAttribute("aria-hidden", "true")
      const dx = Math.round((Math.random() - 0.5) * 88)
      const dy = -40 - Math.round(Math.random() * 70)
      speck.style.left = `${rect.width / 2 + (Math.random() - 0.5) * 24}px`
      speck.style.bottom = "42%"
      speck.style.setProperty("--spark-x", `${dx}px`)
      speck.style.setProperty("--spark-y", `${dy}px`)
      speck.style.animationDelay = `${i * 28}ms`
      host.appendChild(speck)
      window.setTimeout(() => speck.remove(), 1100)
    }
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
    })

    t += PACK_UNLOCK.land
    this.phase(t, () => {
      pack.classList.add("is-stars-reveal")
      pack.querySelectorAll(".street-star").forEach((star, i) => {
        star.style.animationDelay = `${i * 120}ms`
      })
      window.NocheLiveAudio?.play?.("chest", 0.62)
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
      return
    }

    if (name === "packComplete") {
      const score = this.element.querySelector(".score-fly")
      if (score?.dataset.final) score.textContent = score.dataset.final
      this.element.querySelectorAll(".street-ceremony-fire.is-earned").forEach((fire) => fire.classList.add("is-flying"))
      this.element.querySelector(".street-ceremony-chest")?.classList.add("is-opening")
      this.element.classList.add("is-fire-phase", "is-stars-phase", "is-sequence-done")
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
