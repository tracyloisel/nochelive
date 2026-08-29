import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"
import { audioLoader } from "platform/audio/loader"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { motionDirector } from "runtime/motion/runtime"
import { streetCueGain, streetQuizTimeline } from "runtime/street/quiz_timeline"

const PACK_UNLOCK = Object.freeze({
  reveal: 220,
  done: 900
})

const SCORE_COUNT_MS = 420
const PARTICLE_COUNT = 16

export default class extends Controller {
  static values = { sequence: String }

  connect() {
    this.effects = new EffectScope()
    motionDirector.setReducedMotion(this.reduced())
    if (this.sequenceValue) this.run(this.sequenceValue)
  }

  run(name) {
    if (this.reduced()) {
      if (name === "packComplete") this.playCeremonyFanfare()
      this.instantComplete(name)
      return
    }

    this.element.classList.add("is-sequence-running")
    if (name === "packComplete") this.packComplete()
    if (name === "packUnlock") this.packUnlock()

    const duration = name === "packComplete"
      ? streetQuizTimeline().ceremony.done
      : (name === "packUnlock" ? PACK_UNLOCK.done : 0)
    if (duration < 1) return

    this.effects.timeout(() => this.finishSequence(), duration)
    this.effects.timeout(() => this.element.classList.add("is-skip-ready"), 900)
    this.effects.listen(this.element, "click", this.skip)
    this.effects.listen(this.element, "keydown", this.skipKey)
  }

  skip = (event) => {
    if (!this.element.classList.contains("is-skip-ready") || this.element.classList.contains("is-sequence-done")) return
    if (event.target.closest("a, button, input, select, textarea, summary")) return
    this.finishSequence()
  }

  skipKey = (event) => {
    if (this.element.classList.contains("is-sequence-done")) return
    if (event.key !== "Escape" && event.key !== " ") return
    event.preventDefault()
    this.finishSequence()
  }

  finishSequence() {
    this.effects.dispose()
    this.element.classList.add("is-sequence-done")
    this.instantComplete(this.sequenceValue)
  }

  packComplete() {
    const timeline = streetQuizTimeline().ceremony
    this.phase(timeline.fanfare, () => this.playCeremonyFanfare())
    this.phase(timeline.reward, () => this.revealCeremonyReward())
    this.phase(timeline.chest, () => this.element.classList.add("is-chest-phase"))
    this.phase(timeline.chestOpen, () => this.openCeremonyChest())
    this.phase(timeline.content, () => this.element.classList.add("is-content-phase"))
  }

  playCeremonyFanfare() {
    if (!audioLoader.unlocked()) return
    const cue = this.element.dataset.stageSfxValue || "street_royal_fanfare"
    audioLoader.play(cue, streetCueGain(cue))
  }

  revealCeremonyReward() {
    this.element.classList.add("is-reward-phase")
    haptic("reward")
  }

  revealCeremonyTotal() {
    const score = this.element.querySelector(".score-fly")
    if (!score) return
    const from = Number(score.dataset.from || score.textContent || 0)
    const to = Number(score.dataset.final || from)
    this.animateScore(score, from, to)
  }

  animateScore(score, from, to) {
    if (from === to) {
      score.textContent = String(to)
      return
    }

    score.classList.add("is-boosting")
    const controls = motionDirector.count(from, to, {
      duration: SCORE_COUNT_MS / 1000,
      onUpdate: (value) => { score.textContent = String(Math.round(value)) },
      onComplete: () => score.classList.remove("is-boosting")
    })
    this.effects.animation(controls)
  }

  openCeremonyChest({ replay = false } = {}) {
    const chest = this.element.querySelector(".street-ceremony-chest")
    if (!chest) return

    chest.classList.remove("is-opening")
    void chest.offsetWidth
    chest.classList.add("is-opening")
    chest.addEventListener("animationend", () => chest.classList.remove("is-opening"), { once: true })
    this.element.classList.add("is-bonus-landed")
    audioLoader.play("chest", 0.62)
    haptic(replay ? "tap" : "success")
    if (replay) {
      const score = this.element.querySelector(".score-fly")
      if (score) {
        score.classList.remove("is-boosting")
        void score.offsetWidth
        score.classList.add("is-boosting")
        score.addEventListener("animationend", () => score.classList.remove("is-boosting"), { once: true })
      }
    } else {
      this.revealCeremonyTotal()
    }
    this.burstParticles()
  }

  replayChest(event) {
    event.preventDefault()
    this.openCeremonyChest({ replay: true })
  }

  burstParticles() {
    const host = this.element.querySelector(".street-ceremony-chest-wrap")
    if (!host) return
    const rect = host.getBoundingClientRect()
    for (let index = 0; index < PARTICLE_COUNT; index += 1) {
      const speck = document.createElement("span")
      speck.className = `street-ceremony-spark is-${index % 3 === 0 ? "crown" : "light"}`
      speck.setAttribute("aria-hidden", "true")
      if (index % 3 === 0) speck.textContent = "♛"
      const dx = Math.round((Math.random() - 0.5) * 142)
      const dy = -54 - Math.round(Math.random() * 104)
      speck.style.left = `${rect.width / 2 + (Math.random() - 0.5) * 24}px`
      speck.style.bottom = "42%"
      speck.style.setProperty("--spark-x", `${dx}px`)
      speck.style.setProperty("--spark-y", `${dy}px`)
      speck.style.animationDelay = `${index * 28}ms`
      host.appendChild(speck)
      speck.addEventListener("animationend", () => speck.remove(), { once: true })
    }
  }

  packUnlock() {
    const pack = this.element
    this.phase(PACK_UNLOCK.reveal, () => {
      pack.classList.remove("is-locked", "is-unlocking")
      pack.classList.add("is-current")
      pack.querySelector(".mapa-node-lock")?.remove()
      audioLoader.play("chest", 0.62)
      haptic("reward")
    })
  }

  phase(delay, callback) {
    this.effects.timeout(callback, delay)
  }

  instantComplete(name) {
    if (name === "packUnlock") {
      const pack = this.element
      pack.classList.remove("is-locked", "is-unlocking")
      pack.classList.add("is-current")
      pack.querySelector(".mapa-node-lock")?.remove()
      return
    }

    if (name !== "packComplete") return
    const score = this.element.querySelector(".score-fly")
    if (score?.dataset.final) score.textContent = score.dataset.final
    score?.classList.remove("is-boosting")
    this.element.querySelector(".street-ceremony-chest")?.classList.add("is-opening")
    this.element.classList.add("is-reward-phase", "is-chest-phase", "is-bonus-landed", "is-content-phase", "is-sequence-done")
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  disconnect() {
    this.effects?.dispose()
  }
}
