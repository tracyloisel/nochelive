export class ResourcePolicy {
  constructor(manifest) {
    this.manifest = manifest
  }

  classFor(key) {
    return this.manifest.classes[key] || null
  }

  allows(key, phase) {
    const resourceClass = this.classFor(key)
    if (!resourceClass) return false
    if (phase === "initial") return resourceClass === "critical" || resourceClass === "contextual"
    if (phase === "interaction") return resourceClass === "interaction"
    if (phase === "viewport") return resourceClass === "viewport"
    if (phase === "predictive") return resourceClass === "predictive"
    if (phase === "idle") return resourceClass === "idle"
    return false
  }
}
