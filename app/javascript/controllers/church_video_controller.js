import { Controller } from "@hotwired/stimulus"

const CONSENT_KEY = "noche_youtube_consent"
const VIDEO_ID = /^[A-Za-z0-9_-]{11}$/

export default class extends Controller {
  static targets = [ "dialog", "consent", "player", "title" ]
  static values = {
    locale: { type: String, default: "en" },
    playerTitle: { type: String, default: "Video" }
  }

  connect() {
    this.videoId = null
    this.videoTitle = null
    this.lastTrigger = null
  }

  disconnect() {
    this.resetPlayer()
  }

  open(event) {
    const id = event.currentTarget.dataset.videoId || ""
    if (!VIDEO_ID.test(id)) return

    this.videoId = id
    this.videoTitle = event.currentTarget.dataset.videoTitle || this.playerTitleValue
    this.lastTrigger = event.currentTarget
    this.titleTarget.textContent = this.videoTitle
    this.showDialog()

    if (this.hasConsent()) this.mountPlayer()
    else this.showConsent()
  }

  accept() {
    try {
      window.localStorage.setItem(CONSENT_KEY, "v1")
    } catch (_error) {
      // Private browsing may reject storage; the current explicit choice still counts.
    }
    this.mountPlayer()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
    else this.onClose()
  }

  onClose() {
    this.resetPlayer()
    this.showConsent()
    this.lastTrigger?.focus({ preventScroll: true })
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  showDialog() {
    if (this.dialogTarget.open) return
    if (this.dialogTarget.showModal) this.dialogTarget.showModal()
    else this.dialogTarget.setAttribute("open", "")
  }

  showConsent() {
    this.consentTarget.hidden = false
    this.playerTarget.hidden = true
  }

  mountPlayer() {
    if (!VIDEO_ID.test(this.videoId || "")) return

    this.resetPlayer()
    this.consentTarget.hidden = true
    this.playerTarget.hidden = false

    const iframe = document.createElement("iframe")
    const params = new URLSearchParams({
      hl: this.localeValue,
      playsinline: "1",
      rel: "0",
      origin: window.location.origin
    })
    iframe.src = `https://www.youtube-nocookie.com/embed/${this.videoId}?${params}`
    iframe.title = `${this.playerTitleValue}: ${this.videoTitle}`
    iframe.allow = "accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    iframe.allowFullscreen = true
    iframe.loading = "lazy"
    iframe.referrerPolicy = "strict-origin-when-cross-origin"
    this.playerTarget.appendChild(iframe)
  }

  resetPlayer() {
    if (this.hasPlayerTarget) this.playerTarget.replaceChildren()
  }

  hasConsent() {
    try {
      return window.localStorage.getItem(CONSENT_KEY) === "v1"
    } catch (_error) {
      return false
    }
  }
}
