export class Clock {
  constructor({ now = () => Date.now(), timers = globalThis } = {}) {
    this.read = now
    this.timers = timers
  }

  now() {
    return this.read()
  }

  timeout(callback, delay) {
    return this.timers.setTimeout(callback, delay)
  }

  clearTimeout(id) {
    this.timers.clearTimeout(id)
  }
}
