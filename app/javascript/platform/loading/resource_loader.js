export class ResourceLoader {
  constructor({ importer = (specifier) => import(specifier), fetchImpl = globalThis.fetch?.bind(globalThis) } = {}) {
    this.importer = importer
    this.fetchImpl = fetchImpl
    this.modules = new Map()
    this.requests = new Map()
  }

  module(key, specifier) {
    if (!this.modules.has(key)) {
      const pending = this.importer(specifier).catch((error) => {
        this.modules.delete(key)
        throw error
      })
      this.modules.set(key, pending)
    }
    return this.modules.get(key)
  }

  fetch(key, url, options = {}) {
    if (!this.fetchImpl) return Promise.reject(new TypeError("fetch implementation is required"))
    if (!this.requests.has(key)) {
      const pending = this.fetchImpl(url, options).finally(() => this.requests.delete(key))
      this.requests.set(key, pending)
    }
    return this.requests.get(key)
  }
}
