import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { motionDirector } from "runtime/motion/runtime"

const DEFAULT_RECIPE = "list-enter"
const RECIPES = new Set([ "list-enter", "result-reveal", "invitation-enter" ])
const OBSERVER_OPTIONS = Object.freeze({
  root: null,
  rootMargin: "0px 0px -8% 0px",
  threshold: 0.12
})

// Page-local, one-shot editorial reveals for #rama_profile.
//
// Mark every narrative section with:
//   data-rama-motion-target="chapter"
//   data-rama-motion-recipe="list-enter|result-reveal|invitation-enter"
// and mark only the text/content wrappers that may move with:
//   data-rama-motion-item
//
// The artwork and the page remain visible by default. That is intentional:
// no controller, IntersectionObserver or Web Animations API means no hidden UI.
export default class extends Controller {
  static targets = [ "chapter" ]

  connect() {
    this.effects = new EffectScope()
    this.active = new Map()
    this.revealed = new WeakSet()
    this.reducedMotion = this.prefersReducedMotion()
    motionDirector.setReducedMotion(this.reducedMotion)

    this.effects.listen(document, "turbo:before-cache", this.beforeCache)

    const pending = this.chapterTargets.filter((chapter) => chapter.dataset.ramaMotionState !== "ready")
    if (pending.length === 0) {
      this.markPageReady()
      return
    }

    if (this.reducedMotion || !this.canObserveAndAnimate(pending)) {
      this.finishAll({ reduced: this.reducedMotion })
      return
    }

    try {
      this.observer = new window.IntersectionObserver(this.onIntersect, OBSERVER_OPTIONS)
      this.effects.own(() => this.observer?.disconnect())
      pending.forEach((chapter) => {
        chapter.dataset.ramaMotionState = "waiting"
        this.observer.observe(chapter)
      })
      this.element.dataset.ramaMotionState = "observing"
    } catch (_error) {
      this.finishAll()
    }
  }

  disconnect() {
    this.observer?.disconnect()
    this.effects?.dispose()
    this.active?.clear()
  }

  onIntersect = (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return
      this.reveal(entry.target)
    })
  }

  beforeCache = () => {
    this.finishAll({ reduced: this.reducedMotion })
    this.effects?.dispose()
  }

  reveal(chapter) {
    if (this.revealed.has(chapter) || chapter.dataset.ramaMotionState === "ready") return

    this.revealed.add(chapter)
    this.observer?.unobserve(chapter)
    const recipe = this.recipeFor(chapter)
    const items = this.itemsFor(chapter)
    chapter.dataset.ramaMotionState = "running"

    if (items.length === 0) {
      this.markChapterReady(chapter)
      return
    }

    const record = { recipe, items, controls: null }
    this.active.set(chapter, record)

    try {
      record.controls = motionDirector.run(recipe, items, {
        onComplete: () => this.markChapterReady(chapter)
      })
      this.effects.animation(record.controls)
    } catch (_error) {
      this.finishChapter(chapter, { reduced: this.reducedMotion })
    }
  }

  finishAll({ reduced = false } = {}) {
    this.observer?.disconnect()
    this.chapterTargets.forEach((chapter) => this.finishChapter(chapter, { reduced }))
    this.markPageReady()
  }

  finishChapter(chapter, { reduced = false } = {}) {
    const record = this.active.get(chapter)
    const recipe = record?.recipe || this.recipeFor(chapter)
    const items = record?.items || this.itemsFor(chapter)

    try {
      motionDirector.finish(recipe, items, { reduced })
    } catch (_error) {
      items.forEach((item) => {
        item.style.opacity = "1"
        item.style.transform = "none"
        item.classList.add("is-visible")
      })
    }

    this.markChapterReady(chapter)
  }

  markChapterReady(chapter) {
    chapter.dataset.ramaMotionState = "ready"
    chapter.classList.add("is-rama-motion-visible")
    this.active.delete(chapter)

    if (this.chapterTargets.every((target) => target.dataset.ramaMotionState === "ready")) {
      this.observer?.disconnect()
      this.markPageReady()
    }
  }

  markPageReady() {
    this.element.dataset.ramaMotionState = "ready"
  }

  itemsFor(chapter) {
    return Array.from(chapter.querySelectorAll("[data-rama-motion-item]"))
  }

  recipeFor(chapter) {
    const recipe = chapter.dataset.ramaMotionRecipe
    return RECIPES.has(recipe) ? recipe : DEFAULT_RECIPE
  }

  canObserveAndAnimate(chapters) {
    if (typeof window.IntersectionObserver !== "function") return false
    return chapters.every((chapter) => this.itemsFor(chapter).every((item) => typeof item.animate === "function"))
  }

  prefersReducedMotion() {
    try {
      return window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true
    } catch (_error) {
      return false
    }
  }
}
