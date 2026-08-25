import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open() {
    this.element.classList.add("is-opening")
    window.NocheLiveAudio?.play?.("chest")
    window.NocheLiveAudio?.flash?.("shake")
  }
}
