import { Controller } from "@hotwired/stimulus"

// Renders the visitor's civil date without guessing their time zone on the
// server. Used only by the honest, no-programme fallback in Today's story.
export default class extends Controller {
  connect() {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, "0")
    const day = String(now.getDate()).padStart(2, "0")
    const locale = document.documentElement.lang || "es"

    this.element.dateTime = `${year}-${month}-${day}`
    this.element.textContent = new Intl.DateTimeFormat(locale, { dateStyle: "long" }).format(now)
    this.element.hidden = false
  }
}
