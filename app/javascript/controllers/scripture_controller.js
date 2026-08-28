import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "frame", "loading" ]

  connect() {
    this.onFrameLoad = this.onFrameLoad.bind(this)
    this.onKey = this.onKey.bind(this)
    this.onMissing = this.onMissing.bind(this)
    if (this.hasFrameTarget) {
      this.frameTarget.addEventListener("turbo:frame-load", this.onFrameLoad)
      this.frameTarget.addEventListener("turbo:frame-missing", this.onMissing)
    }
    window.addEventListener("keydown", this.onKey)
    if (this.open()) this.afterOpen()
  }

  disconnect() {
    this.frameTarget?.removeEventListener("turbo:frame-load", this.onFrameLoad)
    this.frameTarget?.removeEventListener("turbo:frame-missing", this.onMissing)
    window.removeEventListener("keydown", this.onKey)
    this.unlock()
  }

  prepare(event) {
    this.dismissed = false
    this.pendingReadingLink = event?.currentTarget?.closest("[data-scripture-reading-link]")
    this.lock()
    if (this.hasLoadingTarget) this.loadingTarget.hidden = false
  }

  close(event) {
    event?.preventDefault()
    this.dismissed = true
    this.hideLoading()
    this.unlock()
    if (this.hasFrameTarget && this.frameTarget.querySelector(".scripture-veil")) {
      this.frameTarget.replaceChildren()
      window.NocheLiveAudio?.playFrom?.(document)
      return
    }
    if (window.history.length > 1) history.back()
    else window.location.href = "/"
  }

  onFrameLoad() {
    this.hideLoading()
    if (this.dismissed) {
      this.frameTarget?.replaceChildren()
      this.unlock()
      window.NocheLiveAudio?.playFrom?.(document)
      return
    }
    if (this.open()) {
      this.afterOpen()
      this.markPendingReadingOpened()
    }
    else this.unlock()
  }

  onMissing(event) {
    event.preventDefault()
    this.hideLoading()
    this.unlock()
  }

  onKey(event) {
    if (event.key !== "Escape") return
    if (!this.open() && this.loadingHidden()) return
    event.preventDefault()
    this.close(event)
  }

  afterOpen() {
    this.lock()
    document.querySelector("[data-scripture-close]")?.focus({ preventScroll: true })
    const focus = document.querySelector("[data-scripture-focus]")
    if (focus) {
      focus.scrollIntoView({ block: "center", behavior: this.reduced() ? "auto" : "smooth" })
    }
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

  open() {
    return !!document.querySelector(".scripture-veil:not(.is-loading)")
  }

  loadingHidden() {
    return !this.hasLoadingTarget || this.loadingTarget.hidden
  }

  hideLoading() {
    if (this.hasLoadingTarget) this.loadingTarget.hidden = true
  }

  lock() {
    document.documentElement.classList.add("is-scripture-open")
  }

  unlock() {
    document.documentElement.classList.remove("is-scripture-open")
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
