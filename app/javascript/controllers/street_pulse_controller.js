import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    src: String,
    interval: { type: Number, default: 5000 }
  }

  connect() {
    this.refresh = this.refresh.bind(this)
    this.onVis = this.onVis.bind(this)
    this.timer = setInterval(this.refresh, this.intervalValue)
    document.addEventListener("visibilitychange", this.onVis)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.onVis)
  }

  onVis() {
    if (!document.hidden) this.refresh()
  }

  refresh() {
    if (document.hidden) return
    const frame = this.element
    if (!frame.hasAttribute("src") && this.srcValue) {
      frame.setAttribute("src", this.srcValue)
      return
    }
    if (typeof frame.reload === "function") frame.reload()
  }
}
