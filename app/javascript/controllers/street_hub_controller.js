import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "map" ]
  static values = { currentPack: String }

  connect() {
    this.drawPath = this.drawPath.bind(this)
    this.resizeObserver = new ResizeObserver(this.drawPath)
    if (this.hasMapTarget) this.resizeObserver.observe(this.mapTarget)
    requestAnimationFrame(() => {
      this.drawPath()
      this.scrollToCurrent()
      requestAnimationFrame(this.drawPath)
    })
  }

  scrollToCurrent() {
    const id = this.currentPackValue
    if (!id) return
    const node = this.element.querySelector(`#pack-${id}`)
    if (!node) return
    const pin = () => {
      const map = this.hasMapTarget ? this.mapTarget : null
      if (map?.classList.contains("is-rope")) {
        const mapRect = map.getBoundingClientRect()
        const nodeRect = node.getBoundingClientRect()
        map.scrollTop += (nodeRect.top + nodeRect.height / 2) - (mapRect.top + mapRect.height * 0.42)
      } else {
        node.scrollIntoView({
          behavior: this.reduced() ? "auto" : "smooth",
          block: "nearest",
          inline: "nearest"
        })
      }
    }
    requestAnimationFrame(() => {
      pin()
      requestAnimationFrame(pin)
      if (!this.reduced()) {
        node.classList.add("is-beacon-active")
        this.beaconTimer = window.setTimeout(() => node.classList.remove("is-beacon-active"), 2600)
      }
    })
  }

  drawPath() {
    const map = this.hasMapTarget ? this.mapTarget : null
    if (!map?.classList.contains("is-rope")) return
    const track = map.querySelector(".street-map-track")
    const svg = map.querySelector(".street-map-thread")
    const line = svg?.querySelector("path")
    if (!track || !svg || !line) return

    const thumbs = [ ...track.querySelectorAll(".street-pack-thumb") ]
    const bounds = track.getBoundingClientRect()
    const width = Math.max(track.clientWidth, 1)
    const height = Math.max(track.scrollHeight, track.clientHeight, 1)
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`)

    if (thumbs.length < 2) {
      line.removeAttribute("d")
      return
    }

    const pts = thumbs.map((thumb) => {
      const box = thumb.getBoundingClientRect()
      return {
        x: box.left + box.width / 2 - bounds.left,
        y: box.top + box.height / 2 - bounds.top
      }
    })
    line.setAttribute("d", this.curveThrough(pts))
  }

  curveThrough(pts) {
    let d = `M ${this.fmt(pts[0].x)} ${this.fmt(pts[0].y)}`
    for (let i = 0; i < pts.length - 1; i += 1) {
      const prev = pts[i - 1] || pts[i]
      const a = pts[i]
      const b = pts[i + 1]
      const next = pts[i + 2] || b
      const c1x = a.x + (b.x - prev.x) / 6
      const c1y = a.y + (b.y - prev.y) / 6
      const c2x = b.x - (next.x - a.x) / 6
      const c2y = b.y - (next.y - a.y) / 6
      d += ` C ${this.fmt(c1x)} ${this.fmt(c1y)}, ${this.fmt(c2x)} ${this.fmt(c2y)}, ${this.fmt(b.x)} ${this.fmt(b.y)}`
    }
    return d
  }

  fmt(n) {
    return Math.round(n * 10) / 10
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    window.clearTimeout(this.beaconTimer)
  }
}
