import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { loadStylesheet, releaseStylesheet } from "platform/loading/stylesheet_loader"

// The launcher owns only the Turbo Frame lifecycle. The substantial reader
// controller enters the DOM with the frame response and is therefore loaded on
// interaction by Stimulus' lazy controller loader.
export default class extends Controller {
  static targets = ["frame", "loading"]
  static values = { stylesheet: String }

  connect() {
    this.effectScope = new EffectScope()
    this.effectScope.listen(this.frameTarget, "turbo:frame-load", () => this.loaded())
    this.effectScope.listen(this.frameTarget, "turbo:frame-missing", (event) => this.missing(event))
    this.effectScope.listen(window, "keydown", (event) => this.keydown(event))
  }

  disconnect() {
    this.effectScope?.dispose()
    releaseStylesheet(this.stylesheetResource)
    this.unlock()
  }

  prepare(event) {
    this.pendingReadingLink = event?.currentTarget?.closest("[data-scripture-reading-link]")
    this.ensureStylesheet()
    this.lock()
    if (this.hasLoadingTarget) this.loadingTarget.hidden = false
  }

  async ensureStylesheet() {
    if (!this.hasStylesheetValue || this.stylesheetResource) return this.stylesheetResource
    try {
      this.stylesheetResource = await loadStylesheet(this.stylesheetValue, "scripture")
      return this.stylesheetResource
    } catch (_error) {
      return null
    }
  }

  loaded() {
    if (this.hasLoadingTarget) this.loadingTarget.hidden = true
    if (!this.frameTarget.querySelector(".scripture-veil")) return this.unlock()

    this.lock()
    this.markPendingReadingOpened()
  }

  missing(event) {
    event.preventDefault()
    if (this.hasLoadingTarget) this.loadingTarget.hidden = true
    this.unlock()
  }

  keydown(event) {
    if (event.key !== "Escape" || !this.frameTarget.querySelector(".scripture-veil")) return
    // The contextual reader owns dialogs and selection cleanup once mounted.
    this.frameTarget.querySelector("[data-scripture-close]")?.click()
  }

  markPendingReadingOpened() {
    const link = this.pendingReadingLink
    this.pendingReadingLink = null
    if (!link || link.classList.contains("is-opened")) return

    link.classList.add("is-opened")
    const state = link.querySelector(".study-reading-state")
    if (state) state.textContent = `✓ ${link.dataset.scriptureOpenedLabel}`

    const progress = document.querySelector("[data-scripture-progress]")
    if (!progress) return
    const opened = Number(progress.dataset.openedCount || 0) + 1
    const total = Number(progress.dataset.totalCount || 0)
    progress.dataset.openedCount = opened
    progress.textContent = progress.dataset.labelTemplate
      .replace("__OPENED__", opened)
      .replace("__TOTAL__", total)
  }

  lock() {
    document.documentElement.classList.add("is-scripture-open")
  }

  unlock() {
    document.documentElement.classList.remove("is-scripture-open")
  }
}
