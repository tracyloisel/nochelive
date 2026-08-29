export class FakeClock {
  constructor(now = 0) {
    this.time = now
    this.nextId = 1
    this.tasks = new Map()
  }

  now() {
    return this.time
  }

  timeout(callback, delay) {
    const id = this.nextId++
    this.tasks.set(id, { at: this.time + delay, callback })
    return id
  }

  clearTimeout(id) {
    this.tasks.delete(id)
  }

  tick(ms) {
    const end = this.time + ms
    while (true) {
      const due = Array.from(this.tasks.entries())
        .filter(([, task]) => task.at <= end)
        .sort((one, two) => one[1].at - two[1].at || one[0] - two[0])[0]
      if (!due) break
      const [id, task] = due
      this.tasks.delete(id)
      this.time = task.at
      task.callback()
    }
    this.time = end
  }
}
