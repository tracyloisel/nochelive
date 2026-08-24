import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["beat"]
  static values = { url: String }

  connect() {
    this.index = 0
    this.token = document.querySelector("meta[name='csrf-token']")?.content
    this.show()
  }

  advance(event) {
    event.preventDefault()
    if (event.currentTarget.closest("[hidden]")) return
    this.index += 1
    if (this.index >= this.beatTargets.length) {
      this.submit()
      return
    }
    this.show()
  }

  show() {
    this.beatTargets.forEach((beat, index) => {
      const on = index === this.index
      beat.hidden = !on
      beat.classList.toggle("is-arriving", on)
    })
  }

  submit() {
    const body = this.beatTargets.map((beat) => beat.dataset.pathKeyParam).join(",")
    const form = document.createElement("form")
    form.method = "post"
    form.action = this.urlValue
    form.innerHTML = `<input type="hidden" name="authenticity_token" value="${this.token}">` +
      `<input type="hidden" name="body" value="${body}">`
    document.body.append(form)
    form.requestSubmit()
  }
}
