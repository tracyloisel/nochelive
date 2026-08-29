function numericAnimation(from, to, { duration = 0.5, onUpdate } = {}) {
  let frame = null
  let settled = false
  let resolveFinished
  let rejectFinished
  const finished = new Promise((resolve, reject) => {
    resolveFinished = resolve
    rejectFinished = reject
  })
  const start = performance.now()
  const durationMs = Math.max(0, duration * 1_000)

  const settle = () => {
    if (settled) return
    settled = true
    onUpdate?.(to)
    resolveFinished()
  }

  const tick = (now) => {
    if (settled) return
    const progress = durationMs > 0 ? Math.min(1, (now - start) / durationMs) : 1
    const eased = 1 - Math.pow(1 - progress, 3)
    onUpdate?.(from + ((to - from) * eased))
    if (progress >= 1) settle()
    else frame = requestAnimationFrame(tick)
  }

  frame = requestAnimationFrame(tick)
  return {
    finished,
    cancel() {
      if (frame !== null) cancelAnimationFrame(frame)
      if (settled) return
      settled = true
      rejectFinished(new Error("animation cancelled"))
    }
  }
}

function elementAnimation(elements, keyframes, { duration = 0.5, delay = 0, ease = "ease-out" } = {}) {
  const targets = Array.from(elements || [])
  const animations = targets.map((element, index) => element.animate(keyframes, {
    duration: duration * 1_000,
    delay: typeof delay === "function" ? delay(index) * 1_000 : delay * 1_000,
    easing: Array.isArray(ease) ? `cubic-bezier(${ease.join(",")})` : ease,
    fill: "forwards"
  }))
  return {
    finished: Promise.all(animations.map((animation) => animation.finished)),
    cancel() { animations.forEach((animation) => animation.cancel()) }
  }
}

export const nativeMotionBackend = Object.freeze({
  animate(subject, keyframes, options) {
    if (typeof subject === "number" && typeof keyframes === "number") {
      return numericAnimation(subject, keyframes, options)
    }
    return elementAnimation(subject, keyframes, options)
  },

  stagger(interval) {
    return (index) => index * interval
  }
})
