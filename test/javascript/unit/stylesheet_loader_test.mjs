import test from "node:test"
import assert from "node:assert/strict"

const links = []
globalThis.window = { location: { origin: "https://noche.test" } }
globalThis.CSS = { escape: (value) => value }
globalThis.document = {
  baseURI: "https://noche.test/play",
  createElement() {
    const link = new EventTarget()
    link.dataset = {}
    link.remove = () => {
      const index = links.indexOf(link)
      if (index >= 0) links.splice(index, 1)
    }
    return link
  },
  head: {
    querySelector(selector) {
      const key = selector.match(/"([^"]+)"/)?.[1]
      return links.find((link) => link.dataset.runtimeStylesheet === key) || null
    },
    append(link) {
      links.push(link)
      queueMicrotask(() => link.dispatchEvent(new Event("load")))
    }
  }
}

const { loadStylesheet, releaseStylesheet } = await import("../../../app/javascript/platform/loading/stylesheet_loader.js")

test("stylesheet loader deduplicates concurrent and mounted resources", async () => {
  const firstPromise = loadStylesheet("/assets/surfaces/scripture.css", "scripture")
  const secondPromise = loadStylesheet("/assets/surfaces/scripture.css", "scripture")
  assert.equal(firstPromise, secondPromise)

  const first = await firstPromise
  assert.equal(first.owned, true)
  assert.equal(links.length, 1)

  const mounted = await loadStylesheet("/assets/surfaces/scripture.css", "scripture")
  assert.equal(mounted.owned, false)
  assert.equal(mounted.link, first.link)

  releaseStylesheet(mounted)
  assert.equal(links.length, 1)
  releaseStylesheet(first)
  assert.equal(links.length, 0)
})

test("stylesheet loader rejects cross-origin styles", async () => {
  await assert.rejects(
    loadStylesheet("https://cdn.invalid/style.css", "cross-origin"),
    /same-origin/
  )
})
