# Frontend vendored dependencies

Noche Live does not depend on a third-party CDN at runtime. The following files are
version-pinned under `vendor/javascript` and are exposed through the importmap with
`preload: false`.

| Import | Upstream | Version | Local SHA-256 | Runtime owner |
| --- | --- | ---: | --- | --- |
| `howler-core` | `howler.js/dist/howler.core.min.js` | 2.2.4 | `e7b836445d8c44bddc99b7678fa336a9d5c5ede27cc709c5fae8b1748ba7431b` | `platform/audio/howler_backend.js` only |
| `motion` | `motion` ESM browser bundle | 13.1.1 | `bab41f3579239576784977cb218b6f8a243b1f3df46438e4bfb43ae2a657ca3a` | `platform/motion/motion_backend.js` only |

Regenerate deliberately, update the version and hash together, then run the import
boundary tests. Do not replace these pins with `latest` or a network URL.

Howler 2.2.4 remains behind an adoption gate. Its upstream tracker still contains
iOS background/interrupted-context reports, so the native backend remains production
default until the physical iOS/PWA/Android matrix is green.
