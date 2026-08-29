import test from "node:test"
import assert from "node:assert/strict"
import { validateRenderContract } from "../../../app/javascript/runtime/motion/render_policy.js"

test("render contracts require bounded cadence, path, duration and elements", () => {
  const contract = validateRenderContract({ cadence: "display", renderPath: "compositor", maxDurationMs: 560, maxElements: 12 })
  assert.equal(contract.maxDurationMs, 560)
  assert.throws(() => validateRenderContract({ cadence: "60hz", renderPath: "compositor", maxDurationMs: 560, maxElements: 12 }), /cadence/)
  assert.throws(() => validateRenderContract({ cadence: "display", renderPath: "compositor", maxDurationMs: 2_000, maxElements: 12 }), /duration/)
})
