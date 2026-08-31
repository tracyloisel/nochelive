import { Controller } from "@hotwired/stimulus"
import { loadStylesheet, releaseStylesheet } from "platform/loading/stylesheet_loader"
import {
  hideInstallOffer,
  InstallOfferMemory,
  isIosDevice,
  isSafariBrowser,
  isStandaloneMode,
  revealInstallOffer,
  revealIosInstallBanner,
  setInstallState,
  validInstallPrompt
} from "features/pwa/install_offer"

export default class extends Controller {
  static targets = ["action", "banner", "browserHint", "dialog", "dismiss", "guideTemplate", "sheet", "status", "tile"]
  static values = { stylesheet: String }

  connect() {
    this.installMemory = new InstallOfferMemory()
    this.deferredPrompt = validInstallPrompt(window.NocheInstallPrompt)
    this.beforeInstallPrompt = (event) => this.receiveInstallPrompt(event)
    this.installed = () => this.confirmInstalled()
    window.addEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    window.addEventListener("appinstalled", this.installed)
    this.syncInstallOffer()
    if ("serviceWorker" in navigator) navigator.serviceWorker.register("/service-worker.js", { scope: "/" }).catch(() => {})
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    window.removeEventListener("appinstalled", this.installed)
    releaseStylesheet(this.stylesheetResource)
  }

  receiveInstallPrompt(event) {
    event.preventDefault()
    if (this.isStandalone() || this.installMemory.installSnoozed() || !validInstallPrompt(event)) return

    this.deferredPrompt = event
    window.NocheInstallPrompt = event
    this.showAction()
  }

  confirmInstalled() {
    this.clearDeferredPrompt()
    this.installMemory.markInstalled()
    this.hideInstallUi()
  }

  syncInstallOffer() {
    if (this.shouldHideInstallOffer()) return this.hideInstallUi()
    if (this.deferredPrompt) return this.showAction()
    if (!this.canOpenIosGuide()) return this.hideInstallUi()

    this.showAction()
    this.showIosBanner()
  }

  async install(event) {
    if (this.shouldHideInstallOffer()) return this.hideInstallUi()

    this.installMemory.markOfferSeen()
    this.installTrigger = event?.currentTarget
    if (!this.deferredPrompt) return this.canOpenIosGuide() ? this.openGuide(event) : this.hideInstallUi()

    setInstallState(this, "installing")
    try {
      await this.deferredPrompt.prompt()
      const choice = await this.deferredPrompt.userChoice
      this.clearDeferredPrompt()
      if (choice?.outcome === "accepted") {
        // `appinstalled`, never `userChoice`, confirms a completed installation.
        if (this.installMemory.knownInstalled() || this.isStandalone()) return this.hideInstallUi()

        setInstallState(this, "awaiting_confirmation")
        return
      }
      this.installMemory.recordRejection()
    } catch (_) {
      this.clearDeferredPrompt()
      this.installMemory.recordRejection()
    }
    this.hideInstallUi()
  }

  async openGuide(event) {
    if (!this.canOpenIosGuide()) return this.hideInstallUi()

    this.installMemory.markOfferSeen()
    this.installTrigger = event?.currentTarget || this.installTrigger
    this.installMemory.snoozeBanner()
    this.bannerTargets.forEach((banner) => { banner.hidden = true })
    await this.ensureStylesheet()
    const guide = await import("features/pwa/install_guide")
    guide.mountInstallGuide(this)
    this.browserHintTargets.forEach((hint) => { hint.hidden = this.isSafari() })
    if (!this.hasDialogTarget) return

    this.dialogTarget.showModal()
    guide.resetInstallGuide(this)
    this.installMemory.markIosGuideSeen()
  }

  dismissBanner() {
    this.installMemory.snoozeBanner()
    this.bannerTargets.forEach((banner) => { banner.hidden = true })
  }

  dismissTile(event) {
    event?.preventDefault()
    event?.stopPropagation()
    this.installMemory.snoozeInstallUi()
    this.hideInstallUi()
  }

  close() {
    if (this.hasDialogTarget) this.dialogTarget.close()
    this.restoreInstallFocus()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  closed() { this.restoreInstallFocus() }

  restoreInstallFocus() {
    this.installTrigger?.focus({ preventScroll: true })
    this.installTrigger = null
  }

  showAction() { revealInstallOffer(this) }
  showIosBanner() { revealIosInstallBanner(this) }
  hideInstallUi() { hideInstallOffer(this) }

  shouldHideInstallOffer() {
    return this.isStandalone() || this.installMemory.knownInstalled() || this.installMemory.installSnoozed() ||
      (!this.deferredPrompt && this.canOpenIosGuide() && this.installMemory.iosGuideSnoozed())
  }

  canOfferInstall() { return Boolean(this.deferredPrompt) || this.canOpenIosGuide() }
  canOpenIosGuide() { return this.isIos() && !this.isStandalone() }
  isIos() { return isIosDevice(navigator) }
  isSafari() { return isSafariBrowser(navigator) }
  isStandalone() { return isStandaloneMode(window, navigator) }

  clearDeferredPrompt() {
    this.deferredPrompt = null
    window.NocheInstallPrompt = null
  }

  installingStatusLabel() {
    return this.statusTargets[0]?.dataset.pwaInstallInstallingLabel || ""
  }

  async ensureStylesheet() {
    if (!this.hasStylesheetValue || this.stylesheetResource) return this.stylesheetResource
    try {
      this.stylesheetResource = await loadStylesheet(this.stylesheetValue, "pwa")
      return this.stylesheetResource
    } catch (_) {
      return null
    }
  }
}
