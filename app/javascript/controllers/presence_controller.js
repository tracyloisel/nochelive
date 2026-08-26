import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.beat = this.beat.bind(this)
    this.onVis = this.onVis.bind(this)
    this.beat()
    this.timer = setInterval(this.beat, 4000)
    document.addEventListener("visibilitychange", this.onVis)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.onVis)
  }

  onVis() {
    if (!document.hidden) this.beat()
  }

  beat() {
    if (!this.urlValue || document.hidden) return
    const token = document.querySelector("meta[name='csrf-token']")?.content
    if (!token) return
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        Accept: "text/plain",
        "X-Requested-With": "XMLHttpRequest"
      },
      credentials: "same-origin"
    }).catch(() => {})
  }
}
