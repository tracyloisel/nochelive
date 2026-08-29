const MAX_ELEMENTS = 80
const MAX_DURATION_SECONDS = 1.2

const RECIPES = Object.freeze({
  "list-enter": {
    keyframes: { opacity: [ 0, 1 ], transform: [ "translateY(10px)", "translateY(0)" ] },
    duration: 0.42,
    stagger: 0.055,
    final: { opacity: "1", transform: "translateY(0)" }
  },
  "result-reveal": {
    keyframes: { opacity: [ 0, 1 ], transform: [ "translateY(14px) scale(.985)", "translateY(0) scale(1)" ] },
    duration: 0.48,
    stagger: 0.07,
    final: { opacity: "1", transform: "translateY(0) scale(1)" }
  },
  "ceremony-enter": {
    keyframes: { opacity: [ 0, 1 ], transform: [ "translateY(18px) scale(.975)", "translateY(0) scale(1)" ] },
    duration: 0.58,
    stagger: 0.08,
    final: { opacity: "1", transform: "translateY(0) scale(1)" }
  },
  "invitation-enter": {
    keyframes: { opacity: [ 0, 1 ] },
    duration: 0.42,
    stagger: 0,
    final: { opacity: "1", transform: "none" }
  }
})

export class MotionDirector {
  constructor({ backend, reduced = false } = {}) {
    if (!backend) throw new TypeError("motion backend is required")
    this.backend = backend
    this.reduced = reduced
  }

  setReducedMotion(value) {
    this.reduced = value === true
  }

  run(name, elements, { onComplete } = {}) {
    const recipe = RECIPES[name]
    if (!recipe) throw new Error(`unknown motion recipe: ${name}`)
    const targets = Array.from(elements || []).slice(0, MAX_ELEMENTS)
    if (this.reduced || targets.length === 0) {
      this.finish(name, targets, { reduced: this.reduced })
      onComplete?.()
      return { cancel() {}, finished: Promise.resolve() }
    }

    const duration = Math.min(recipe.duration, MAX_DURATION_SECONDS)
    const delay = recipe.stagger > 0 ? this.backend.stagger(recipe.stagger) : 0
    const controls = this.backend.animate(targets, recipe.keyframes, {
      duration,
      delay,
      ease: [ 0.22, 1, 0.36, 1 ]
    })
    controls.finished.then(() => {
      this.finish(name, targets)
      onComplete?.()
    }).catch(() => {})
    return controls
  }

  count(from, to, { duration = 0.5, onUpdate, onComplete } = {}) {
    if (this.reduced) {
      onUpdate?.(to)
      onComplete?.()
      return { cancel() {}, finished: Promise.resolve() }
    }
    const controls = this.backend.animate(from, to, {
      duration: Math.min(duration, MAX_DURATION_SECONDS),
      ease: [ 0.22, 1, 0.36, 1 ],
      onUpdate
    })
    controls.finished.then(() => {
      onUpdate?.(to)
      onComplete?.()
    }).catch(() => {})
    return controls
  }

  finish(name, elements, { reduced = false } = {}) {
    const recipe = RECIPES[name]
    if (!recipe) return
    Array.from(elements || []).forEach((element) => {
      const final = reduced && recipe.final.transform ? { ...recipe.final, transform: "none" } : recipe.final
      Object.assign(element.style, final)
      element.classList?.add("is-visible")
    })
  }

  recipe(name) {
    return RECIPES[name]
  }
}
