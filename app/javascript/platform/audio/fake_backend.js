export class FakeAudioBackend {
  constructor() {
    this.calls = []
    this.unlocked = false
    this.muted = false
  }

  configure(config) { this.calls.push([ "configure", config ]) }
  unlock() { this.unlocked = true; this.calls.push([ "unlock" ]); return Promise.resolve(true) }
  preload(names) { this.calls.push([ "preload", names ]); return this.unlocked ? names : [] }
  play(name, options) { this.calls.push([ "play", name, options ]); return this.muted ? null : this.calls.length }
  startBed(name, options) { this.calls.push([ "startBed", name, options ]); return this.calls.length }
  stopBed(options) { this.calls.push([ "stopBed", options ]) }
  setMuted(value) { this.muted = value; this.calls.push([ "setMuted", value ]) }
  dispose() { this.calls.push([ "dispose" ]) }
}
