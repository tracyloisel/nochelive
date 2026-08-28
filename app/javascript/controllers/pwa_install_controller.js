import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["action", "dialog"]

  connect() {
    this.deferredPrompt = null
    this.beforeInstallPrompt = (event) => {
      event.preventDefault()
      this.deferredPrompt = event
      this.showAction()
    }
    this.installed = () => this.hideAction()

    window.addEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    window.addEventListener("appinstalled", this.installed)

    if (this.isStandalone()) return this.hideAction()
    if (this.isIos()) this.showAction()

    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/service-worker.js", { scope: "/" })
    }
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    window.removeEventListener("appinstalled", this.installed)
  }

  async install() {
    if (this.deferredPrompt) {
      await this.deferredPrompt.prompt()
      await this.deferredPrompt.userChoice
      this.deferredPrompt = null
      this.hideAction()
      return
    }

    if (this.hasDialogTarget) this.dialogTarget.showModal()
  }

  close() {
    if (this.hasDialogTarget) this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  closed() {
    this.actionTargets.forEach((action) => action.focus({ preventScroll: true }))
  }

  showAction() {
    this.actionTargets.forEach((action) => { action.hidden = false })
  }

  hideAction() {
    this.actionTargets.forEach((action) => { action.hidden = true })
  }

  isIos() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent)
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
  }
}
