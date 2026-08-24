import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  lock(event) {
    this.element.classList.add("is-locked")
    this.element.setAttribute("aria-disabled", "true")
    if (navigator.vibrate) navigator.vibrate(40)
    const stage = this.application.getControllerForElementAndIdentifier(document.body, "stage")
    stage?.play("buzzer_hit")
    stage?.flash("gold")
  }
}
