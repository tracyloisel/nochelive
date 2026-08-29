import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { libraryMotionDirector as motionDirector } from "runtime/motion/library_runtime"

export default class extends Controller {
  static targets = ["reveal"]
  static values = { sequence: String }

  connect() {
    this.effectScope = new EffectScope()
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    motionDirector.setReducedMotion(this.reduced)
    this.element.dataset.motionState = "entering"
    this.element.classList.add("has-motion")
    const recipe = this.recipeFor(this.sequenceValue)
    this.recipe = recipe
    this.controls = motionDirector.run(recipe, this.revealTargets, { onComplete: () => this.finish() })
    this.effectScope.animation(this.controls)
  }

  recipeFor(sequence) {
    if (sequence === "campus") return "list-enter"
    if (sequence === "invitation") return "invitation-enter"
    return "ceremony-enter"
  }

  disconnect() {
    this.effectScope?.dispose()
    this.element.classList.remove("has-motion")
  }

  skip() {
    this.finish()
  }

  finish() {
    this.controls?.cancel?.()
    motionDirector.finish(this.recipe, this.revealTargets, { reduced: this.reduced })
    this.element.classList.remove("has-motion")
    this.element.classList.add("is-ready")
    this.element.dataset.motionState = "ready"
  }
}
