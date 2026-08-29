export class FakeCache {
  constructor(keys = []) {
    this.keys = new Set(keys)
  }

  has(key) {
    return this.keys.has(key)
  }
}
