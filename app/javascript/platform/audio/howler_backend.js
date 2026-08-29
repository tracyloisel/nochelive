import "howler-core"

export class HowlerBackend {
  constructor({ HowlClass = globalThis.Howl, howler = globalThis.Howler, now = () => Date.now() } = {}) {
    if (!HowlClass || !howler) throw new Error("Howler Core is unavailable")
    this.HowlClass = HowlClass
    this.howler = howler
    this.now = now
    this.catalog = {}
    this.sounds = new Map()
    this.unlocked = false
    this.muted = false
    this.currentBed = null
  }

  configure({ catalog = {}, cues = [] } = {}) {
    this.catalog = { ...catalog }
    this.allowed = new Set(cues)
  }

  async unlock() {
    const context = this.howler.ctx
    if (context && (context.state === "suspended" || context.state === "interrupted")) {
      await context.resume()
    }
    this.unlocked = true
    return true
  }

  preload(names = []) {
    if (!this.unlocked) return []
    return names.filter((name) => this.allowed?.has(name)).map((name) => this.sound(name).load())
  }

  play(name, { gain = 1, loop = false, html5 = false } = {}) {
    if (this.muted || !this.allowed?.has(name)) return null
    const sound = this.sound(name, { loop, html5 })
    sound.volume(Math.min(1, Math.max(0, Number(gain) || 0)))
    return sound.play()
  }

  startBed(name, { gain = 0.2, fadeMs = 300 } = {}) {
    if (this.currentBed?.name === name) return this.currentBed.id
    this.stopBed({ fadeMs })
    const sound = this.sound(name, { loop: true, html5: true })
    sound.volume(0)
    const id = this.muted ? null : sound.play()
    if (id != null) sound.fade(0, gain, fadeMs, id)
    this.currentBed = { name, sound, id, gain }
    return id
  }

  stopBed({ fadeMs = 300 } = {}) {
    const bed = this.currentBed
    this.currentBed = null
    if (!bed || bed.id == null) return
    const from = bed.sound.volume(bed.id)
    bed.sound.fade(from, 0, fadeMs, bed.id)
    bed.sound.once("fade", () => bed.sound.stop(bed.id), bed.id)
  }

  setMuted(value) {
    this.muted = value === true
    this.howler.mute(this.muted)
  }

  dispose() {
    this.stopBed({ fadeMs: 0 })
    this.sounds.forEach((sound) => sound.unload())
    this.sounds.clear()
  }

  sound(name, { loop = false, html5 = false } = {}) {
    if (!this.allowed?.has(name)) throw new Error(`audio cue outside context: ${name}`)
    if (this.sounds.has(name)) return this.sounds.get(name)
    const src = this.catalog[name]
    if (!src) throw new Error(`unknown audio cue: ${name}`)
    const sound = new this.HowlClass({ src: [ src ], preload: false, loop, html5 })
    this.sounds.set(name, sound)
    return sound
  }
}
