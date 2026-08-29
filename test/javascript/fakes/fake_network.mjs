export class FakeNetworkPolicy {
  constructor(constrained = false) {
    this.value = constrained
  }

  constrained() {
    return this.value
  }
}
