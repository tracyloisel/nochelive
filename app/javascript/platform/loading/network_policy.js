const SLOW_TYPES = new Set(["slow-2g", "2g"])

export class NetworkPolicy {
  constructor({ connection = globalThis.navigator?.connection, online = () => globalThis.navigator?.onLine !== false } = {}) {
    this.connection = connection
    this.online = online
    this.samples = []
  }

  record(durationMs, ok = true) {
    this.samples.push({ durationMs: Math.max(0, Number(durationMs) || 0), ok: Boolean(ok) })
    if (this.samples.length > 8) this.samples.shift()
  }

  constrained() {
    if (!this.online()) return true
    if (this.connection?.saveData) return true
    if (SLOW_TYPES.has(this.connection?.effectiveType)) return true
    if (this.samples.length < 3) return false

    const recent = this.samples.slice(-3)
    return recent.some((sample) => !sample.ok) || recent.reduce((sum, sample) => sum + sample.durationMs, 0) / recent.length > 1_200
  }
}
