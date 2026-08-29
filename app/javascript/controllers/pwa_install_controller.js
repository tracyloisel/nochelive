import { Controller } from "@hotwired/stimulus"
import { loadStylesheet, releaseStylesheet } from "platform/loading/stylesheet_loader"

export default class extends Controller {
  static targets = ["action", "banner", "browserHint", "dialog", "guideTemplate", "sheet", "tile"]
  static values = { stylesheet: String }

  static BANNER_SNOOZE_MS = 14 * 24 * 60 * 60 * 1000

  connect() {
    this.deferredPrompt = window.NocheInstallPrompt || null
    this.beforeInstallPrompt = (event) => {
      event.preventDefault()
      this.deferredPrompt = event
      window.NocheInstallPrompt = event
      this.showAction()
    }
    this.installed = () => {
      this.deferredPrompt = null
      window.NocheInstallPrompt = null
      this.hideInstallUi()
    }

    window.addEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    window.addEventListener("appinstalled", this.installed)

    if (this.isStandalone()) return this.hideInstallUi()
    if (this.deferredPrompt) this.showAction()
    if (this.isIos()) {
      this.showAction()
      this.showIosBanner()
    }

    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/service-worker.js", { scope: "/" })
    }
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    window.removeEventListener("appinstalled", this.installed)
    releaseStylesheet(this.stylesheetResource)
  }

  async install(event) {
    this.markInstallSession()
    this.installTrigger = event?.currentTarget

    if (this.deferredPrompt) {
      await this.deferredPrompt.prompt()
      await this.deferredPrompt.userChoice
      this.deferredPrompt = null
      window.NocheInstallPrompt = null
      this.hideAction()
      return
    }

    this.openGuide(event)
  }

  async openGuide(event) {
    this.markInstallSession()
    this.installTrigger = event?.currentTarget || this.installTrigger
    this.snoozeBanner()
    this.hideBanner()
    await this.ensureStylesheet()
    const guide = await import("features/pwa/install_guide")
    guide.mountInstallGuide(this)
    this.browserHintTargets.forEach((hint) => { hint.hidden = this.isSafari() })
    if (this.hasDialogTarget) {
      this.dialogTarget.showModal()
      guide.resetInstallGuide(this)
    }
  }

  dismissBanner() {
    this.snoozeBanner()
    this.hideBanner()
  }

  close() {
    if (this.hasDialogTarget) this.dialogTarget.close()
    this.restoreInstallFocus()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  closed() {
    this.restoreInstallFocus()
  }

  restoreInstallFocus() {
    this.installTrigger?.focus({ preventScroll: true })
    this.installTrigger = null
  }

  showAction() {
    this.ensureStylesheet().then(() => {
      this.actionTargets.forEach((action) => { action.hidden = false })
    })
  }

  hideAction() {
    this.actionTargets.forEach((action) => { action.hidden = true })
  }

  showIosBanner() {
    if (window.location.pathname !== "/" || this.hasTileTarget || this.bannerSnoozed()) return
    this.ensureStylesheet().then(() => {
      this.bannerTargets.forEach((banner) => { banner.hidden = false })
    })
  }

  hideBanner() {
    this.bannerTargets.forEach((banner) => { banner.hidden = true })
  }

  hideInstallUi() {
    this.hideAction()
    this.hideBanner()
  }

  snoozeBanner() {
    try { localStorage.setItem("noche:pwa-install-snoozed-at", Date.now().toString()) } catch (_) {}
  }

  bannerSnoozed() {
    try {
      const snoozedAt = Number(localStorage.getItem("noche:pwa-install-snoozed-at"))
      return snoozedAt > 0 && Date.now() - snoozedAt < this.constructor.BANNER_SNOOZE_MS
    } catch (_) {
      return false
    }
  }

  isIos() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  }

  isSafari() {
    return /safari/i.test(navigator.userAgent) && !/crios|fxios|edgios|opios/i.test(navigator.userAgent)
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
  }

  markInstallSession() {
    try { sessionStorage.setItem("noche:pwa-install-offered", "1") } catch (_) {}
  }

  async ensureStylesheet() {
    if (!this.hasStylesheetValue || this.stylesheetResource) return this.stylesheetResource
    try {
      this.stylesheetResource = await loadStylesheet(this.stylesheetValue, "pwa")
      return this.stylesheetResource
    } catch (_error) {
      return null
    }
  }
}
