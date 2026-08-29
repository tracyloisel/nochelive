import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"
import { http } from "platform/http/client"

export default class extends Controller {
  static values = { receiptUrl: String }

  connect() {
    haptic("success")
    this.acknowledge()
  }

  dismiss() {
    haptic("tap")
    this.element.remove()
  }

  async acknowledge() {
    if (!this.hasReceiptUrlValue) return
    try {
      await http.json(this.receiptUrlValue, {
        method: "POST",
        keepalive: true
      })
    } catch (_) {
      // The notice remains actionable even if a receipt cannot be recorded.
    }
  }
}
