export class PrefetchPolicy {
  constructor({ networkPolicy, maxBytes = 180_000, maxActive = 1 } = {}) {
    this.networkPolicy = networkPolicy
    this.maxBytes = maxBytes
    this.maxActive = maxActive
    this.active = new Map()
  }

  decide({ key, bytes = 0, criticalReady, commandInFlight, visible, cached, inFlight } = {}) {
    if (!key) return { allowed: false, reason: "missing-key" }
    if (!criticalReady) return { allowed: false, reason: "critical-pending" }
    if (commandInFlight) return { allowed: false, reason: "command-in-flight" }
    if (!visible) return { allowed: false, reason: "background" }
    if (cached) return { allowed: false, reason: "cached" }
    if (inFlight || this.active.has(key)) return { allowed: false, reason: "in-flight" }
    if (this.active.size >= this.maxActive) return { allowed: false, reason: "active-limit" }
    if (bytes <= 0 || bytes > this.maxBytes) return { allowed: false, reason: "byte-budget" }
    if (this.networkPolicy?.constrained()) return { allowed: false, reason: "network-constrained" }
    return { allowed: true, reason: "allowed" }
  }

  begin(key) {
    if (this.active.has(key)) return this.active.get(key)
    const controller = new AbortController()
    this.active.set(key, controller)
    return controller
  }

  finish(key) {
    this.active.delete(key)
  }

  cancelAll(reason = "prefetch-cancelled") {
    this.active.forEach((controller) => controller.abort(reason))
    this.active.clear()
  }
}
