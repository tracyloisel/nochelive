import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trail", "pick"]
  static values = { url: String, needed: Number }

  connect() {
    this.chosen = []
    this.token = document.querySelector("meta[name='csrf-token']")?.content
  }

  pick(event) {
    const button = event.currentTarget
    if (button.disabled) return
    const key = event.params.key
    const label = event.params.label
    if (this.chosen.some((item) => item.key === key)) return

    const tone = Array.from(button.classList).find((name) => /^choice-(gold|fire|navy|deep)$/.test(name))
    this.chosen.push({ key, label, tone })
    button.disabled = true
    this.render()
    if (this.chosen.length >= this.neededValue) this.submit()
  }

  undo() {
    const last = this.chosen.pop()
    if (!last) return
    this.pickTargets.forEach((button) => {
      if (button.dataset.orderKeyParam === last.key) button.disabled = false
    })
    this.render()
  }

  render() {
    if (!this.hasTrailTarget) return
    this.trailTarget.replaceChildren(
      ...this.chosen.map((item, index) => {
        const li = document.createElement("li")
        li.className = `order-chip ${item.tone || ""}`
        const num = document.createElement("span")
        num.className = "step-num"
        num.textContent = String(index + 1)
        const word = document.createElement("span")
        word.className = "word"
        word.textContent = item.label
        li.append(num, word)
        return li
      })
    )
  }

  submit() {
    const body = this.chosen.map((item) => item.key).join(",")
    const form = document.createElement("form")
    form.method = "post"
    form.action = this.urlValue
    form.innerHTML = `<input type="hidden" name="authenticity_token" value="${this.token}">` +
      `<input type="hidden" name="body" value="${body}">`
    document.body.append(form)
    form.requestSubmit()
  }
}
