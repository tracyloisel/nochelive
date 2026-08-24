import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.remove = this.remove.bind(this)
    this.element.addEventListener("animationend", this.remove)
    this.timer = setTimeout(this.remove, 2200)
    this.cue()
  }

  cue() {
    const name = this.element.dataset.sfx
    if (!name) return
    const stage = this.application.getControllerForElementAndIdentifier(document.body, "stage")
    stage?.play(name)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.element.removeEventListener("animationend", this.remove)
  }

  remove() {
    this.element.remove()
  }
}
