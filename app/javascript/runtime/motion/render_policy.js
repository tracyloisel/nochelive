export const RENDER_CADENCES = Object.freeze(["display", "30hz", "1hz", "event", "idle"])
export const RENDER_PATHS = Object.freeze(["compositor", "main-thread", "discrete"])

export function validateRenderContract(contract) {
  if (!RENDER_CADENCES.includes(contract?.cadence)) throw new TypeError("invalid render cadence")
  if (!RENDER_PATHS.includes(contract?.renderPath)) throw new TypeError("invalid render path")
  if (!(contract.maxDurationMs > 0 && contract.maxDurationMs <= 1_800)) throw new RangeError("invalid motion duration")
  if (!(contract.maxElements > 0)) throw new RangeError("invalid element budget")
  return Object.freeze({ ...contract })
}
