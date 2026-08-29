export const RESOURCE_CLASSES = Object.freeze(["critical", "contextual", "interaction", "viewport", "predictive", "idle"])

function strings(value, field) {
  if (!Array.isArray(value) || value.some((entry) => typeof entry !== "string" || !entry)) {
    throw new TypeError(`${field} must contain non-empty strings`)
  }
  return Object.freeze([...new Set(value)])
}

export class ResourceManifest {
  constructor(input = {}) {
    if (typeof input.context !== "string" || !input.context.match(/^[a-z0-9_.-]+$/i)) {
      throw new TypeError("manifest context is invalid")
    }

    this.context = input.context
    this.styles = strings(input.styles || [], "styles")
    this.controllers = strings(input.controllers || [], "controllers")
    this.media = Object.freeze({ ...(input.media || {}) })
    this.audio = Object.freeze({ unlock: false, cues: [], bed: null, ...(input.audio || {}) })
    this.motion = strings(input.motion || [], "motion")
    this.prefetch = Object.freeze({ nextScreen: false, maxBytes: 0, ...(input.prefetch || {}) })
    this.classes = Object.freeze({ ...(input.classes || {}) })

    if (!Array.isArray(this.audio.cues) || this.audio.cues.some((cue) => typeof cue !== "string")) {
      throw new TypeError("audio cues must be strings")
    }
    if (this.prefetch.maxBytes < 0 || this.prefetch.maxBytes > 180_000) {
      throw new RangeError("prefetch maxBytes exceeds the runtime budget")
    }
    Object.values(this.classes).forEach((kind) => {
      if (!RESOURCE_CLASSES.includes(kind)) throw new TypeError(`unknown resource class: ${kind}`)
    })
    Object.freeze(this)
  }

  static fromElement(element) {
    if (!element?.textContent) return new ResourceManifest({ context: "shell", styles: ["shell"] })
    return new ResourceManifest(JSON.parse(element.textContent))
  }
}
