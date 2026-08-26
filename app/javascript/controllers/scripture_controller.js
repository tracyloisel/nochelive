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

  prepare() {
    this.dismissed = false
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
      return
    }
    if (this.open()) this.afterOpen()
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
