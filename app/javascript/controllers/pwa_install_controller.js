import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["action", "banner", "browserHint", "dialog", "guideTemplate", "sheet", "tile"]

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

  openGuide(event) {
    this.markInstallSession()
    this.installTrigger = event?.currentTarget || this.installTrigger
    this.snoozeBanner()
    this.hideBanner()
    this.ensureGuide()
    this.browserHintTargets.forEach((hint) => { hint.hidden = this.isSafari() })
    if (this.hasDialogTarget) {
      this.dialogTarget.showModal()
      this.resetGuidePosition()
    }
  }

  ensureGuide() {
    if (!this.hasGuideTemplateTarget || !this.hasDialogTarget || this.hasSheetTarget) return

    this.dialogTarget.append(this.guideTemplateTarget.content.cloneNode(true))
    this.guideTemplateTarget.remove()
  }

  resetGuidePosition() {
    this.dialogTarget.scrollTop = 0
    window.requestAnimationFrame(() => {
      this.dialogTarget.scrollTop = 0
      if (this.hasSheetTarget) this.sheetTarget.focus({ preventScroll: true })
    })
  }

  dismissBanner() {
    this.snoozeBanner()
    this.hideBanner()
  }

  close() {
    if (this.hasDialogTarget) this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  closed() {
    this.installTrigger?.focus({ preventScroll: true })
    this.installTrigger = null
  }

  showAction() {
    this.actionTargets.forEach((action) => { action.hidden = false })
  }

  hideAction() {
    this.actionTargets.forEach((action) => { action.hidden = true })
  }

  showIosBanner() {
    if (window.location.pathname !== "/" || this.hasTileTarget || this.bannerSnoozed()) return
    this.bannerTargets.forEach((banner) => { banner.hidden = false })
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
}
