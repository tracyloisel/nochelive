const DEFAULT_GAINS = Object.freeze({ hit: 0.72, stinger: 0.8, bed: 0.22 })

export class NocheMixer {
  constructor({ backend, catalog, context, gains = DEFAULT_GAINS, now = () => Date.now(), retriggerMs = 180 }) {
    if (!backend) throw new TypeError("audio backend is required")
    this.backend = backend
    this.context = context
    this.gains = { ...DEFAULT_GAINS, ...gains }
    this.now = now
    this.retriggerMs = retriggerMs
    this.lastPlayed = new Map()
    backend.configure({ catalog, cues: context.cues })
  }

  async unlock() {
    await this.backend.unlock()
    this.backend.preload(this.context.probable || [])
    if (this.context.bed) this.backend.startBed(this.context.bed, { gain: this.gains.bed })
  }

  play(name, { kind = "hit", gain = this.gains[kind] ?? 1, token = name } = {}) {
    if (!this.context.cues.includes(name)) return null
    const at = this.now()
    const previous = this.lastPlayed.get(token)
    if (previous != null && at - previous < this.retriggerMs) return null
    this.lastPlayed.set(token, at)
    return this.backend.play(name, { gain })
  }

  bed(name = this.context.bed) {
    if (!name) return this.backend.stopBed()
    if (!this.context.cues.includes(name)) return null
    return this.backend.startBed(name, { gain: this.gains.bed })
  }

  mute(value) { this.backend.setMuted(value) }
  dispose() { this.backend.dispose() }
}
