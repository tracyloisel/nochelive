import { Controller } from "@hotwired/stimulus"

const SPRITES = {
  lettuce: "/media/burger/lettuce.jpg",
  nugget: "/media/burger/nugget.jpg",
  fry: "/media/burger/fry.jpg"
}

export default class extends Controller {
  static targets = ["rain"]
  static values = {
    kind: String,
    count: { type: Number, default: 8 },
    burst: { type: Boolean, default: false }
  }

  connect() {
    this.fill()
    if (this.burstValue) this.burst()
  }

  fill() {
    if (!this.hasRainTarget) return
    this.rainTarget.replaceChildren()
    const src = SPRITES[this.kindValue] || SPRITES.fry
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    const total = reduced ? 3 : this.countValue
    for (let i = 0; i < total; i += 1) {
      const img = document.createElement("img")
      img.src = src
      img.alt = ""
      img.className = reduced ? "garnish-bit is-still" : "garnish-bit"
      img.style.left = `${Math.random() * 92}%`
      img.style.top = reduced ? `${12 + Math.random() * 50}%` : "-12%"
      img.style.animationDelay = `${Math.random() * 1.4}s`
      img.style.animationDuration = `${1.2 + Math.random() * 1.2}s`
      img.style.setProperty("--drift", `${(Math.random() * 48) - 24}%`)
      this.rainTarget.appendChild(img)
    }
  }

  burst() {
    if (!this.hasRainTarget) return
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    for (let i = 0; i < 8; i += 1) {
      const img = document.createElement("img")
      img.src = SPRITES.lettuce
      img.alt = ""
      img.className = "garnish-bit is-burst"
      img.style.left = `${18 + Math.random() * 64}%`
      img.style.animationDuration = `${0.8 + Math.random() * 0.6}s`
      this.rainTarget.appendChild(img)
    }
  }
}
