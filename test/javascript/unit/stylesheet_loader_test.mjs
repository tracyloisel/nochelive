import test, { beforeEach } from "node:test"
import assert from "node:assert/strict"

const links = []
globalThis.window = { location: { origin: "https://noche.test" } }
globalThis.CSS = { escape: (value) => value }
globalThis.document = {
  baseURI: "https://noche.test/play",
  documentElement: { dataset: {} },
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

beforeEach(() => {
  links.length = 0
  document.documentElement.dataset = {}
})

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

test("stylesheet loader accepts and deduplicates styles from the configured asset host", async () => {
  document.documentElement.dataset.assetHost = "https://nochelive-assets-prod.storage.googleapis.com"
  const href = `${document.documentElement.dataset.assetHost}/assets/surfaces/scripture.css`
  const firstPromise = loadStylesheet(href, "scripture")
  const secondPromise = loadStylesheet(href, "scripture")
  const [first] = await Promise.all([firstPromise, secondPromise])
  assert.equal(firstPromise, secondPromise)
  assert.equal(first.link.href, href)
  assert.equal(first.owned, true)
  assert.equal(links.length, 1)

  const mounted = await loadStylesheet(href, "scripture")
  assert.equal(mounted.link, first.link)
  assert.equal(mounted.owned, false)
  releaseStylesheet(mounted)
  assert.equal(links.length, 1)
  releaseStylesheet(first)
  assert.equal(links.length, 0)
})

test("stylesheet loader rejects origins other than the page and configured asset host", async () => {
  document.documentElement.dataset.assetHost = "https://cdn.noche.test"
  for (const href of [
    "https://cdn.invalid/style.css",
    "https://cdn.noche.test.evil.test/style.css",
    "http://cdn.noche.test/style.css",
    "https://cdn.noche.test:8443/style.css"
  ]) {
    await assert.rejects(loadStylesheet(href, "untrusted"), /same-origin/)
  }
  assert.equal(links.length, 0)
})

test("stylesheet loader rejects non-HTTP URLs even when their origin matches", async () => {
  document.documentElement.dataset.assetHost = "https://cdn.noche.test"
  for (const href of [
    "blob:https://noche.test/style.css",
    "blob:https://cdn.noche.test/style.css",
    "data:text/css,body{}",
    "javascript:alert(1)"
  ]) {
    await assert.rejects(loadStylesheet(href, "unsupported-scheme"), /same-origin/)
  }
  assert.equal(links.length, 0)
})

for (const assetHost of [undefined, "", "not a URL", "/assets", "ftp://cdn.noche.test", "blob:https://cdn.noche.test/id"]) {
  test(`stylesheet loader keeps same-origin working with absent or invalid asset host: ${assetHost}`, async () => {
    document.documentElement.dataset.assetHost = assetHost
    const resource = await loadStylesheet("/assets/surfaces/scripture.css", "scripture")
    assert.equal(resource.link.href, "https://noche.test/assets/surfaces/scripture.css")
    await assert.rejects(loadStylesheet("https://cdn.noche.test/style.css", "untrusted"), /same-origin/)
    await assert.rejects(loadStylesheet("ftp://cdn.noche.test/style.css", "unsupported-scheme"), /same-origin/)
    releaseStylesheet(resource)
    assert.equal(links.length, 0)
  })
}
