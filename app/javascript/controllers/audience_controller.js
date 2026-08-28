import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["network"]
  static values = { refreshIn: Number, url: String, online: String, offline: String }

  connect() {
    this.updateNetwork = this.updateNetwork.bind(this)
    window.addEventListener("online", this.updateNetwork)
    window.addEventListener("offline", this.updateNetwork)
    this.updateNetwork()

    if (this.hasRefreshInValue && this.refreshInValue > 0) {
      this.timer = window.setTimeout(() => this.refresh(), this.refreshInValue)
    }
  }

  disconnect() {
    window.removeEventListener("online", this.updateNetwork)
    window.removeEventListener("offline", this.updateNetwork)
    window.clearTimeout(this.timer)
  }

  refresh() {
    if (!navigator.onLine) return
    window.Turbo.visit(this.urlValue || window.location.href, { action: "replace" })
  }

  updateNetwork() {
    const offline = !navigator.onLine
    this.element.classList.toggle("is-offline", offline)
    if (this.hasNetworkTarget) {
      this.networkTarget.textContent = offline ? this.offlineValue : this.onlineValue
    }
  }
}
