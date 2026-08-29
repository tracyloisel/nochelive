export class SafeStorage {
  constructor(storage) {
    this.storage = storage
  }

  get(key, fallback = null) {
    try {
      const value = this.storage?.getItem(key)
      return value == null ? fallback : value
    } catch (_) {
      return fallback
    }
  }

  set(key, value) {
    try {
      this.storage?.setItem(key, String(value))
      return true
    } catch (_) {
      return false
    }
  }

  remove(key) {
    try {
      this.storage?.removeItem(key)
      return true
    } catch (_) {
      return false
    }
  }
}
