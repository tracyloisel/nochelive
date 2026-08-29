import test from "node:test"
import assert from "node:assert/strict"
import { HttpError, createHttpClient } from "../../../app/javascript/platform/http/client.js"

test("HTTP client centralizes same-origin, CSRF and JSON parsing", async () => {
  let request
  const client = createHttpClient({
    csrfToken: () => "csrf-test",
    fetchImpl: async (url, options) => {
      request = { url, options }
      return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "Content-Type": "application/json" } })
    }
  })

  const result = await client.json("/answer", { method: "POST", body: JSON.stringify({ choice: "a" }) })

  assert.deepEqual(result, { ok: true })
  assert.equal(request.options.credentials, "same-origin")
  assert.equal(request.options.headers.get("X-CSRF-Token"), "csrf-test")
  assert.equal(request.options.headers.get("Accept"), "application/json")
})

test("HTTP client rejects non-ok responses with structured status", async () => {
  const client = createHttpClient({ fetchImpl: async () => new Response("no", { status: 503 }) })
  await assert.rejects(() => client.request("/slow"), (error) => error instanceof HttpError && error.status === 503)
})
