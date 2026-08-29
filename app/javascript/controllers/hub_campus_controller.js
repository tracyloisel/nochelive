import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { motionDirector } from "runtime/motion/runtime"

export default class extends Controller {
  static targets = ["reveal", "number"]

  connect() {
    this.effectScope = new EffectScope()
    this.hasRevealed = false
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.locale = document.documentElement.lang || undefined
    motionDirector.setReducedMotion(this.reduced)
    this.resetRevealTargets()

    if (this.reduced || !window.IntersectionObserver) {
      this.settle()
      return
    }

    this.element.dataset.motionState = "waiting"
    this.observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting || this.hasRevealed) return

        this.observer.disconnect()
        this.reveal()
      },
      { threshold: 0.28, rootMargin: "0px 0px 10% 0px" }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
    this.effectScope?.dispose()
  }

  reveal() {
    this.hasRevealed = true
    this.element.dataset.motionState = "entering"
    this.numberTargets.forEach((number) => { number.textContent = "0" })

    const controls = motionDirector.run("list-enter", this.revealTargets, {
      onComplete: () => this.settle()
    })
    this.effectScope.animation(controls)

    this.numberTargets.forEach((number, index) => {
      const target = Number(number.dataset.value || 0)
      this.effectScope.timeout(() => this.count(number, target), 90 + (index * 75))
    })
  }

  count(number, target) {
    if (target <= 0) {
      number.textContent = "0"
      return
    }

    const controls = motionDirector.count(0, target, {
      duration: 0.52,
      onUpdate: (value) => { number.textContent = Math.round(value).toLocaleString(this.locale) },
      onComplete: () => { number.textContent = target.toLocaleString(this.locale) }
    })
    this.effectScope.animation(controls)
  }

  settle() {
    this.revealTargets.forEach((target) => {
      target.style.opacity = "1"
      target.style.transform = "none"
      target.classList.add("is-visible")
    })
    this.numberTargets.forEach((number) => {
      number.textContent = Number(number.dataset.value || 0).toLocaleString(this.locale)
    })
    this.element.dataset.motionState = "ready"
  }

  depart() {
    if (this.reduced) return

    this.element.dataset.motionState = "departing"
  }

  resetRevealTargets() {
    this.revealTargets.forEach((target) => {
      target.style.removeProperty("opacity")
      target.style.removeProperty("transform")
    })
  }
}
