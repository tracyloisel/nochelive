import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { loadStylesheet, releaseStylesheet } from "platform/loading/stylesheet_loader"
import { Clock } from "platform/time/clock"
import { ReaderLoadingDirector } from "runtime/loading/reader_loading_director"

// The launcher owns only the Turbo Frame lifecycle. The substantial reader
// controller enters the DOM with the frame response and is therefore loaded on
// interaction by Stimulus' lazy controller loader.
export default class extends Controller {
  static targets = ["frame", "loading"]
  static values = { stylesheet: String }

  connect() {
    this.effectScope = new EffectScope()
    this.loadingDirector = new ReaderLoadingDirector({
      clock: new Clock(),
      render: (state) => this.renderLoading(state)
    })
    this.effectScope.listen(this.frameTarget, "turbo:frame-load", () => this.loaded())
    this.effectScope.listen(this.frameTarget, "turbo:frame-missing", (event) => this.missing(event))
    this.effectScope.listen(window, "keydown", (event) => this.keydown(event))
  }

  disconnect() {
    this.effectScope?.dispose()
    this.loadingDirector?.dispose()
    releaseStylesheet(this.stylesheetResource)
    this.unlock()
  }

  prepare(event) {
    this.pendingReadingLink = event?.currentTarget?.closest("[data-scripture-reading-link]")
    this.pendingUrl = event?.currentTarget?.href || this.pendingReadingLink?.href || this.pendingUrl
    this.cancelled = false
    this.setLoadingChapter(this.chapterTitleFor(this.pendingReadingLink || event?.currentTarget))
    this.ensureStylesheet()
    this.loadingSequence = this.loadingDirector.start()
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
    this.loadingDirector.resolve(this.loadingSequence)
    if (this.cancelled) {
      this.frameTarget.replaceChildren()
      return this.unlock()
    }
    if (!this.frameTarget.querySelector(".scripture-veil")) return this.unlock()

    this.lock()
    this.markPendingReadingOpened()
  }

  missing(event) {
    event.preventDefault()
    this.loadingDirector.fail(this.loadingSequence)
  }

  retry(event) {
    event?.preventDefault()
    this.cancelled = false
    this.ensureStylesheet()
    this.loadingSequence = this.loadingDirector.start()

    if (typeof this.frameTarget.reload === "function" && this.frameTarget.src) {
      this.frameTarget.reload()
    } else if (this.pendingUrl) {
      this.frameTarget.setAttribute("src", this.pendingUrl)
    } else {
      this.loadingDirector.fail(this.loadingSequence)
    }
  }

  cancel(event) {
    event?.preventDefault()
    this.cancelled = true
    this.pendingReadingLink = null
    this.loadingDirector.resolve(this.loadingSequence)
    this.unlock()
  }

  keydown(event) {
    if (event.key !== "Escape") return
    if (this.hasLoadingTarget && !this.loadingTarget.hidden && !this.frameTarget.querySelector(".scripture-veil")) {
      event.preventDefault()
      this.cancel(event)
      return
    }
    if (!this.frameTarget.querySelector(".scripture-veil")) return
    // The contextual reader owns dialogs and selection cleanup once mounted.
    this.frameTarget.querySelector("[data-scripture-close]")?.click()
  }

  renderLoading(state) {
    if (!this.hasLoadingTarget) return

    const visible = ["visible", "slow", "waiting", "failed"].includes(state)
    this.loadingTarget.hidden = !visible
    this.loadingTarget.dataset.state = state
    this.loadingTarget.setAttribute("aria-hidden", visible ? "false" : "true")
    this.loadingTarget.setAttribute("aria-busy", state === "failed" ? "false" : "true")
    if (visible) this.lock()

    if (state === "failed") {
      window.requestAnimationFrame(() => this.loadingTarget.querySelector("[data-reader-loading-retry]")?.focus({ preventScroll: true }))
    }
  }

  chapterTitleFor(link) {
    const suppliedTitle = link?.dataset?.scriptureChapterTitle?.trim()
    if (suppliedTitle) return suppliedTitle

    try {
      const citation = new URL(link?.href, window.location.origin).searchParams.get("cite")?.trim()
      return citation?.replace(/\s*[:;,]\s*\d+(?:\s*[–-]\s*\d+)?\s*$/, "") || null
    } catch (_error) {
      return null
    }
  }

  setLoadingChapter(title) {
    if (!this.hasLoadingTarget) return

    const chapter = title?.trim() || this.loadingTarget.dataset.readerLoadingChapterFallback
    if (!chapter) return

    this.loadingTarget.dataset.readerLoadingChapter = chapter
    this.loadingTarget.querySelectorAll("[data-reader-loading-chapter]").forEach((target) => {
      target.textContent = chapter
    })
    this.loadingTarget.querySelectorAll("[data-reader-loading-template]").forEach((target) => {
      target.textContent = target.dataset.readerLoadingTemplate.replace("__CHAPTER__", chapter)
    })
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
