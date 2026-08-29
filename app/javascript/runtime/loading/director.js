const DEFAULT_THRESHOLDS = Object.freeze({ visible: 150, slow: 1_200, failed: 4_000 })

export class LoadingDirector {
  constructor({ clock, render = () => {}, thresholds = DEFAULT_THRESHOLDS } = {}) {
    this.clock = clock
    this.render = render
    this.thresholds = { ...DEFAULT_THRESHOLDS, ...thresholds }
    this.state = "idle"
    this.sequence = 0
    this.timers = []
    this.render(this.state)
  }

  start() {
    this.clearTimers()
    const sequence = ++this.sequence
    this.transition("pending")
    this.schedule(sequence, "visible", this.thresholds.visible)
    this.schedule(sequence, "slow", this.thresholds.slow)
    this.schedule(sequence, "failed", this.thresholds.failed)
    return sequence
  }

  resolve(sequence = this.sequence) {
    if (sequence !== this.sequence) return false
    this.clearTimers()
    this.transition("resolved")
    this.transition("idle")
    return true
  }

  fail(sequence = this.sequence) {
    if (sequence !== this.sequence) return false
    this.clearTimers()
    this.transition("failed")
    return true
  }

  offline() {
    this.clearTimers()
    ++this.sequence
    this.transition("offline")
  }

  online() {
    if (this.state === "offline" || this.state === "failed") this.transition("idle")
  }

  dispose() {
    this.clearTimers()
    ++this.sequence
    this.transition("idle")
  }

  schedule(sequence, state, delay) {
    const id = this.clock.timeout(() => {
      if (sequence === this.sequence) this.transition(state)
    }, delay)
    this.timers.push(id)
  }

  clearTimers() {
    this.timers.forEach((id) => this.clock.clearTimeout(id))
    this.timers = []
  }

  transition(state) {
    if (this.state === state) return
    this.state = state
    this.render(state)
  }
}
