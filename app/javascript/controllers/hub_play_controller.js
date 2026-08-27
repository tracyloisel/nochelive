import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  launch(event) {
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    const muted = window.localStorage?.getItem("noche_sfx_muted") === "1"
    const hit = event.currentTarget.closest(".hub-play") || event.currentTarget
    hit.classList.add("is-launch")
    if (!muted && navigator.vibrate) navigator.vibrate(18)
    window.NocheLiveAudio?.play?.("chest")
    if (reduced) return
    if (event.type === "submit") {
      event.preventDefault()
      const form = event.currentTarget
      window.setTimeout(() => form.submit(), 180)
    } else if (hit.tagName === "A") {
      event.preventDefault()
      const href = hit.getAttribute("href")
      window.setTimeout(() => { window.location = href }, 180)
    }
  }
}
