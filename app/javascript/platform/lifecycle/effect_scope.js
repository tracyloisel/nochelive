export class EffectScope {
  constructor({ timers = globalThis, frames = globalThis } = {}) {
    this.timers = timers
    this.frames = frames
    this.disposers = new Set()
    this.disposed = false
  }

  own(dispose) {
    if (typeof dispose !== "function") throw new TypeError("dispose must be a function")
    if (this.disposed) {
      dispose()
      return () => {}
    }

    this.disposers.add(dispose)
    return () => {
      if (!this.disposers.delete(dispose)) return
      dispose()
    }
  }

  listen(target, name, handler, options) {
    target.addEventListener(name, handler, options)
    return this.own(() => target.removeEventListener(name, handler, options))
  }

  timeout(callback, delay) {
    let release = () => {}
    const id = this.timers.setTimeout(() => {
      release()
      if (!this.disposed) callback()
    }, delay)
    release = this.own(() => this.timers.clearTimeout(id))
    return release
  }

  interval(callback, delay) {
    const id = this.timers.setInterval(() => {
      if (!this.disposed) callback()
    }, delay)
    return this.own(() => this.timers.clearInterval(id))
  }

  frame(callback) {
    const request = this.frames.requestAnimationFrame?.bind(this.frames)
    const cancel = this.frames.cancelAnimationFrame?.bind(this.frames)
    if (!request || !cancel) return this.timeout(() => callback(this.now()), 16)

    let release = () => {}
    const id = request((timestamp) => {
      release()
      if (!this.disposed) callback(timestamp)
    })
    release = this.own(() => cancel(id))
    return release
  }

  animation(controls, { finish = false } = {}) {
    return this.own(() => {
      if (finish && typeof controls?.finish === "function") controls.finish()
      else if (typeof controls?.cancel === "function") controls.cancel()
      else if (typeof controls?.stop === "function") controls.stop()
    })
  }

  abortable(controller = new AbortController()) {
    this.own(() => controller.abort())
    return controller
  }

  now() {
    return this.timers.performance?.now?.() ?? Date.now()
  }

  dispose() {
    if (this.disposed) return
    this.disposed = true
    const disposers = Array.from(this.disposers).reverse()
    this.disposers.clear()
    disposers.forEach((dispose) => {
      try { dispose() } catch (_) {}
    })
  }
}
