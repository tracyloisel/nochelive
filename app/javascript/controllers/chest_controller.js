import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open() {
    this.element.classList.add("is-opening")
    const stage = this.application.getControllerForElementAndIdentifier(document.body, "stage")
    stage?.play("chest")
    stage?.flash("shake")
  }
}
