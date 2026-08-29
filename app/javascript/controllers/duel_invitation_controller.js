import { Controller } from "@hotwired/stimulus"
import { http } from "platform/http/client"

export default class extends Controller {
  static values = { receiptUrl: String }

  connect() {
    if (!this.hasReceiptUrlValue || !this.receiptUrlValue) return
    this.recordWhenHumanVisible = this.recordWhenHumanVisible.bind(this)
    document.addEventListener("visibilitychange", this.recordWhenHumanVisible)
    this.recordWhenHumanVisible()
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.recordWhenHumanVisible)
    window.clearTimeout(this.timer)
  }

  recordWhenHumanVisible() {
    if (document.visibilityState !== "visible" || this.sent) return
    this.timer = window.setTimeout(() => this.sendReceipt(), 650)
  }

  async sendReceipt() {
    if (this.sent || document.visibilityState !== "visible") return
    this.sent = true
    try {
      await http.json(this.receiptUrlValue, {
        method: "POST",
        keepalive: true
      })
    } catch (_) {
      this.sent = false
    }
  }
}
