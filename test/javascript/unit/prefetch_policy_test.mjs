import test from "node:test"
import assert from "node:assert/strict"
import { PrefetchPolicy } from "../../../app/javascript/runtime/loading/prefetch_policy.js"
import { FakeNetworkPolicy } from "../fakes/fake_network.mjs"

const ready = { key: "next", bytes: 120_000, criticalReady: true, commandInFlight: false, visible: true, cached: false, inFlight: false }

test("prefetch is one-target, budgeted and network-aware", () => {
  const network = new FakeNetworkPolicy(false)
  const policy = new PrefetchPolicy({ networkPolicy: network })
  assert.deepEqual(policy.decide(ready), { allowed: true, reason: "allowed" })
  policy.begin("next")
  assert.equal(policy.decide({ ...ready, key: "other" }).reason, "active-limit")
  policy.cancelAll()
  network.value = true
  assert.equal(policy.decide(ready).reason, "network-constrained")
  network.value = false
  assert.equal(policy.decide({ ...ready, bytes: 180_001 }).reason, "byte-budget")
  assert.equal(policy.decide({ ...ready, visible: false }).reason, "background")
})
