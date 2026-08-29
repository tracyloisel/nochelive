import { Controller } from "@hotwired/stimulus"
import { audioLoader } from "platform/audio/loader"

export default class extends Controller {
  open() {
    this.element.classList.add("is-opening")
    audioLoader.play("chest")
    audioLoader.flash("shake")
  }
}
