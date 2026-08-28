import assert from "node:assert/strict"
import fs from "node:fs"
import test from "node:test"
import vm from "node:vm"

const source = fs.readFileSync(new URL("../../app/views/pwa/service-worker.js", import.meta.url), "utf8")

function createWorker({ windows = [], matchError = null } = {}) {
  const listeners = new Map()
  const opened = []
  const shown = []
  const clients = {
    claim: async () => {},
    matchAll: async () => {
      if (matchError) throw matchError
      return windows
    },
    openWindow: async (path) => { opened.push(path); return { path } }
  }
  const self = {
    location: { origin: "https://nochelive.com" },
    clients,
    registration: {
      showNotification: async (title, options) => { shown.push({ title, options }) }
    },
    addEventListener: (name, callback) => listeners.set(name, callback),
    skipWaiting: () => {}
  }
  const context = vm.createContext({ self, URL, console })
  vm.runInContext(source, context)
  return { listeners, opened, shown, api: self.NochePushTest }
}

async function dispatch(listener, event) {
  let promise
  listener({ ...event, waitUntil: (value) => { promise = value } })
  await promise
}

test("accepts only internal paths and falls back safely", () => {
  const { api } = createWorker()
  assert.equal(api.safeNotificationPath("/desafio/abc?src=push#resultado"), "/desafio/abc?src=push#resultado")
  for (const value of [undefined, "", "https://evil.test/x", "//evil.test/x", "/\\evil.test/x", "javascript:alert(1)"]) {
    assert.equal(api.safeNotificationPath(value), "/")
  }
})

test("push renders a defensive, internal notification payload", async () => {
  const worker = createWorker()
  await dispatch(worker.listeners.get("push"), {
    data: {
      json: () => ({
        title: "Un défi t’attend", body: "Carmen te défie",
        data: { path: "https://evil.test/steal", delivery_id: 42 }
      })
    }
  })

  assert.equal(worker.shown.length, 1)
  assert.equal(worker.shown[0].title, "Un défi t’attend")
  assert.equal(worker.shown[0].options.data.path, "/")
  assert.equal(worker.shown[0].options.data.delivery_id, 42)
})

test("click focuses an exact destination without navigating or opening a duplicate", async () => {
  let focused = 0
  let navigated = 0
  const exact = {
    url: "https://nochelive.com/desafio/abc?nl_delivery=7",
    focus: async () => { focused += 1 },
    navigate: async () => { navigated += 1 }
  }
  const worker = createWorker({ windows: [exact] })
  let closed = 0
  await dispatch(worker.listeners.get("notificationclick"), {
    notification: {
      data: { path: "/desafio/abc?nl_delivery=7" },
      close: () => { closed += 1 }
    }
  })

  assert.equal(closed, 1)
  assert.equal(focused, 1)
  assert.equal(navigated, 0)
  assert.deepEqual(worker.opened, [])
})

test("click reuses and navigates an existing Noche Live window", async () => {
  const calls = []
  const reusable = {
    url: "https://nochelive.com/",
    navigate: async (path) => { calls.push(["navigate", path]) },
    focus: async () => { calls.push(["focus"]) }
  }
  const worker = createWorker({ windows: [reusable] })
  await dispatch(worker.listeners.get("notificationclick"), {
    notification: { data: { path: "/fr/bible/genese/1" }, close: () => {} }
  })

  assert.deepEqual(calls, [["navigate", "/fr/bible/genese/1"], ["focus"]])
  assert.deepEqual(worker.opened, [])
})

test("click opens the exact path when the app is closed and falls back on client failure", async () => {
  const closedWorker = createWorker()
  await dispatch(closedWorker.listeners.get("notificationclick"), {
    notification: { data: { path: "/desafio/closed" }, close: () => {} }
  })
  assert.deepEqual(closedWorker.opened, ["/desafio/closed"])

  const brokenWorker = createWorker({ matchError: new Error("client lookup failed") })
  await dispatch(brokenWorker.listeners.get("notificationclick"), {
    notification: { data: { path: "/desafio/unreachable" }, close: () => {} }
  })
  assert.deepEqual(brokenWorker.opened, ["/"])
})
