import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.hide = this.hide.bind(this)
    this.element.addEventListener("animationend", this.hide)
    document.addEventListener("turbo:before-cache", this.hide)
  }

  disconnect() {
    this.element.removeEventListener("animationend", this.hide)
    document.removeEventListener("turbo:before-cache", this.hide)
  }

  hide(event) {
    if (event.type === "animationend" && event.target !== this.element) return
    this.element.hidden = true
  }
}
