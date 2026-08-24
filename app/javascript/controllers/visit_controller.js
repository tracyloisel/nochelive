import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    if (!this.urlValue) return
    if (window.Turbo?.visit) window.Turbo.visit(this.urlValue)
    else window.location = this.urlValue
  }
}
