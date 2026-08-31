import { Controller } from "@hotwired/stimulus"
import { audioLoader } from "platform/audio/loader"

export default class extends Controller {
  static targets = ["hero"]

  launch(event) {
    if (this.launching) return

    const link = event.currentTarget.closest("a")
    const form = event.currentTarget.closest("form")
    const destination = link?.href
    if (!destination && !form) return

    event.preventDefault()
    this.launching = true
    if (navigator.vibrate) navigator.vibrate(18)
    // The Home opens a place; it does not award a chest for navigation.
    // Keep this as one short transition cue so it survives the 360 ms portal.
    audioLoader.play("celestial_breath", 0.68)

    const navigate = () => destination ? window.location.assign(destination) : HTMLFormElement.prototype.submit.call(form)
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      navigate()
      return
    }

    document.querySelector("#street_world")?.classList.add("is-entering-quiz")
    this.heroTarget?.classList.add("is-portal-opening")
    window.setTimeout(navigate, 360)
  }
}
