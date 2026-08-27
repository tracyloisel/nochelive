import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hero", "still", "play"]

  launch(event) {
    if (this.launching) return

    const link = event.currentTarget.closest("a")
    const form = event.currentTarget.closest("form")
    const destination = link?.href
    if (!destination && !form) return

    event.preventDefault()
    this.launching = true
    this.playTarget?.classList.add("is-launch")

    if (navigator.vibrate) navigator.vibrate(18)
    window.NocheLiveAudio?.play?.("chest")

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
