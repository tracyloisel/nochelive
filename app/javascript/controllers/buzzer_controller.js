import { Controller } from "@hotwired/stimulus"
import { audioLoader } from "platform/audio/loader"

export default class extends Controller {
  lock(event) {
    this.element.classList.add("is-locked")
    this.element.setAttribute("aria-disabled", "true")
    if (navigator.vibrate) navigator.vibrate(40)
    audioLoader.play("buzzer_hit")
    audioLoader.flash("gold")
  }
}
