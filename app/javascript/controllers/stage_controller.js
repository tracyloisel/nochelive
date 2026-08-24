import { Controller } from "@hotwired/stimulus"

const CUES = [
  "round_start",
  "buzzer_hit",
  "correct_gold",
  "wrong_soft",
  "royal_fanfare",
  "level_up",
  "chest",
  "dramatic_fire",
  "fire_whoosh"
]

export default class extends Controller {
  static targets = ["mute"]

  connect() {
    this.muted = window.localStorage.getItem("noche_sfx_muted") === "1"
    this.syncMute()
    this.lastSfx = null
    this.buffers = {}
    this.unlock = this.unlock.bind(this)
    document.addEventListener("pointerdown", this.unlock, { once: true })
    this.observe()
    this.playFrom(document)
  }

  disconnect() {
    document.removeEventListener("pointerdown", this.unlock)
  }

  toggleMute() {
    this.muted = !this.muted
    window.localStorage.setItem("noche_sfx_muted", this.muted ? "1" : "0")
    this.syncMute()
    if (!this.muted) this.unlock()
  }

  syncMute() {
    if (!this.hasMuteTarget) return
    this.muteTarget.setAttribute("aria-pressed", this.muted ? "true" : "false")
    this.muteTarget.classList.toggle("is-muted", this.muted)
    const word = this.muteTarget.querySelector(".word")
    if (word) word.textContent = this.muted ? "Sonido off" : "Sonido"
    this.muteTarget.setAttribute("aria-label", this.muted ? "Sonido off" : "Sonido")
  }

  observe() {
    document.addEventListener("turbo:frame-render", () => this.playFrom(document))
    document.addEventListener("turbo:render", () => this.playFrom(document))
    document.addEventListener("turbo:before-stream-render", () => {
      requestAnimationFrame(() => this.playFrom(document))
    })
  }

  playFrom(root) {
    const node = root.querySelector("[data-stage-sfx-value]")
    const sfx = node?.dataset.stageSfxValue
    const fx = node?.dataset.stageFxValue
    if (sfx && sfx !== this.lastSfx) {
      this.lastSfx = sfx
      this.play(sfx)
    }
    if (fx) this.flash(fx)
  }

  async unlock() {
    const ctx = this.ensureContext()
    if (!ctx) return
    if (ctx.state === "suspended") await ctx.resume()
    CUES.forEach((name) => this.load(name))
  }

  ensureContext() {
    if (!window.AudioContext) return null
    this.context = this.context || new AudioContext()
    return this.context
  }

  async load(name) {
    if (this.buffers[name] || !CUES.includes(name)) return
    const ctx = this.ensureContext()
    if (!ctx) return
    try {
      const response = await fetch(`/sfx/${name}.wav`)
      if (!response.ok) return
      this.buffers[name] = await ctx.decodeAudioData(await response.arrayBuffer())
    } catch (_error) {
      this.buffers[name] = null
    }
  }

  async play(name) {
    if (this.muted || !CUES.includes(name)) return
    const ctx = this.ensureContext()
    if (!ctx) return
    try {
      if (ctx.state === "suspended") await ctx.resume()
      await this.load(name)
      const buffer = this.buffers[name]
      if (!buffer) return
      const source = ctx.createBufferSource()
      const gain = ctx.createGain()
      gain.gain.value = 0.85
      source.buffer = buffer
      source.connect(gain)
      gain.connect(ctx.destination)
      source.start()
    } catch (_error) {
      // Autoplay may be blocked; silence is fine.
    }
  }

  flash(name) {
    document.body.classList.remove("is-fx-gold", "is-fx-reveal", "is-fx-shake", "is-fx-level", "is-fx-finale")
    const map = { shake: "is-fx-shake", reveal: "is-fx-reveal", level: "is-fx-level", finale: "is-fx-finale" }
    document.body.classList.add(map[name] || "is-fx-gold")
  }
}
