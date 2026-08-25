import { Controller } from "@hotwired/stimulus"

const FALLBACK_CUES = [
  "round_start",
  "buzzer_hit",
  "correct_gold",
  "wrong_soft",
  "royal_fanfare",
  "level_up",
  "chest",
  "dramatic_fire",
  "fire_whoosh",
  "timer_tension",
  "tick",
  "tick_low",
  "round_open",
  "round_lock",
  "question_change",
  "reveal"
]

const TICK_GAIN = { tick: 0.42, tick_low: 0.58 }

function catalog() {
  return window.NocheSfx || {}
}

function cueNames() {
  const names = Object.keys(catalog())
  return names.length ? names : FALLBACK_CUES
}

export default class extends Controller {
  static targets = ["mute"]

  connect() {
    this.muted = window.localStorage.getItem("noche_sfx_muted") === "1"
    this.syncMute()
    this.lastSfx = null
    this.lastToken = null
    this.buffers = {}
    this.bedName = null
    this.bedSource = null
    this.timerEnd = null
    this.lastRemain = null
    this.unlock = this.unlock.bind(this)
    document.addEventListener("pointerdown", this.unlock, { once: true })
    this.observe()
    this.playFrom(document)
  }

  disconnect() {
    document.removeEventListener("pointerdown", this.unlock)
    this.stopBed()
    if (this.timerFrame) cancelAnimationFrame(this.timerFrame)
  }

  toggleMute() {
    this.muted = !this.muted
    window.localStorage.setItem("noche_sfx_muted", this.muted ? "1" : "0")
    this.syncMute()
    if (this.muted) {
      this.stopBed()
      return
    }
    this.unlock()
    this.playFrom(document)
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

  stageNode(root) {
    return root.querySelector("#night_play, #night_watch, #night_presenter")
      || root.querySelector("[data-stage-sfx-value]")
  }

  playFrom(root) {
    const node = this.stageNode(root)
    const sfx = node?.dataset.stageSfxValue
    const token = node?.dataset.stageSfxTokenValue || sfx
    const fx = node?.dataset.stageFxValue
    const bed = node?.dataset.stageBedValue
    if (sfx && (sfx !== this.lastSfx || token !== this.lastToken)) {
      this.lastSfx = sfx
      this.lastToken = token
      this.play(sfx)
    }
    if (fx) this.flash(fx)
    this.syncBed(bed)
    this.syncTimer(node)
  }

  syncBed(name) {
    if (this.muted || !name) {
      this.stopBed()
      return
    }
    if (this.bedName === name && this.bedSource) return
    this.startBed(name)
  }

  async startBed(name) {
    this.stopBed()
    this.bedName = name
    const ctx = this.ensureContext()
    if (!ctx || this.muted) return
    try {
      if (ctx.state === "suspended") await ctx.resume()
      await this.load(name)
      const buffer = this.buffers[name]
      if (!buffer || this.bedName !== name || this.muted) return
      const source = ctx.createBufferSource()
      const gain = ctx.createGain()
      gain.gain.value = 0.35
      source.buffer = buffer
      source.loop = true
      source.connect(gain)
      gain.connect(ctx.destination)
      source.start()
      this.bedSource = source
    } catch (_error) {
      this.bedSource = null
    }
  }

  stopBed() {
    try { this.bedSource?.stop() } catch (_error) { /* already stopped */ }
    this.bedSource = null
    this.bedName = null
  }

  syncTimer(node) {
    const raw = node?.dataset.stageTimerEndValue
    const nextEnd = raw ? Date.parse(raw) : null
    if (nextEnd === this.timerEnd) {
      if (this.timerEnd && !this.timerFrame) this.timerTick()
      return
    }
    this.timerEnd = nextEnd
    this.lastRemain = null
    if (this.timerFrame) cancelAnimationFrame(this.timerFrame)
    this.timerFrame = null
    if (this.timerEnd) this.timerTick()
  }

  timerTick() {
    if (!this.timerEnd) return
    const remainMs = Math.max(0, this.timerEnd - Date.now())
    const remain = Math.ceil(remainMs / 1000)
    if (this.lastRemain !== null && remain < this.lastRemain && remain >= 0) {
      const low = remain <= 5
      this.play(low ? "tick_low" : "tick", TICK_GAIN[low ? "tick_low" : "tick"])
    }
    this.lastRemain = remain
    if (remainMs > 0) {
      this.timerFrame = requestAnimationFrame(() => this.timerTick())
      return
    }
    this.timerFrame = null
    this.stopBed()
  }

  async unlock() {
    const ctx = this.ensureContext()
    if (!ctx) return
    if (ctx.state === "suspended") await ctx.resume()
    cueNames().forEach((name) => this.load(name))
  }

  ensureContext() {
    if (!window.AudioContext) return null
    this.context = this.context || new AudioContext()
    return this.context
  }

  async load(name) {
    if (this.buffers[name] || !cueNames().includes(name)) return
    const ctx = this.ensureContext()
    if (!ctx) return
    const path = catalog()[name] || `/sfx/${name}.mp3`
    try {
      const response = await fetch(path)
      if (!response.ok) return
      this.buffers[name] = await ctx.decodeAudioData(await response.arrayBuffer())
    } catch (_error) {
      this.buffers[name] = null
    }
  }

  async play(name, gainValue = 0.85) {
    if (this.muted || !cueNames().includes(name)) return
    const ctx = this.ensureContext()
    if (!ctx) return
    try {
      if (ctx.state === "suspended") await ctx.resume()
      await this.load(name)
      const buffer = this.buffers[name]
      if (!buffer) return
      const source = ctx.createBufferSource()
      const gain = ctx.createGain()
      gain.gain.value = gainValue
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
