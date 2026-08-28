# Noche Live Admin MCP

Private local MCP server for administering Noche Live through the authenticated Rails admin API. The server never connects directly to PostgreSQL and never stores the admin secret in this repository.

## Architecture and security

The MCP process runs locally over STDIO. Every tool calls `https://nochelive.com/internal/admin/...` with the private bearer token stored in `NOCHE_ADMIN_API_TOKEN`.

- Keep `NOCHE_ADMIN_API_TOKEN` out of Git, screenshots, logs, prompts, and shell history.
- Use the same secret configured on the Render web service.
- The API refuses tokens shorter than 32 characters.
- Administrative mutations are logged without including the secret or player device identifiers.
- Profile merging requires a preview followed by a short-lived, single-use confirmation.
- A Noche Live can only be edited through the rama that owns it.
- Presenter codes cannot be recovered because only their digest is stored. Rotation invalidates the previous code and returns the new one once.

## Install and verify

From the repository root:

```sh
cd mcp/admin
npm ci
npm run typecheck
```

To test that the process starts, provide the two required environment variables. The server waits silently for MCP messages on STDIN when startup succeeds.

```sh
export NOCHE_ADMIN_API_URL="https://nochelive.com"
export NOCHE_ADMIN_API_TOKEN="replace-with-the-render-secret"
npm start
```

Stop the manual test with `Ctrl-C`.

## Configure Codex

Codex supports local STDIO MCP servers. Its desktop app, CLI, and IDE extension share the MCP configuration on the same host. The default configuration file is `~/.codex/config.toml`; a trusted project can instead use `.codex/config.toml`.

Add the following configuration, adapting `cwd` if the repository moves:

```toml
[mcp_servers.nochelive_admin]
command = "./bin/start"
cwd = "/Users/tracyloisel/00-Codes/nochelive/mcp/admin"
startup_timeout_sec = 20
tool_timeout_sec = 60
enabled = true

[mcp_servers.nochelive_admin.env]
NOCHE_ADMIN_API_URL = "https://nochelive.com"
```

The launcher reads `NOCHE_ADMIN_API_TOKEN` from the macOS Keychain item named `com.nochelive.admin-api-token`, so the secret does not appear in `config.toml`. After saving, restart Codex. In the desktop app, the equivalent flow is **Settings → MCP servers → Add server → STDIO**, then save and restart. Use `/mcp` to confirm that `nochelive_admin` is connected.

Official reference: [OpenAI documentation — Model Context Protocol](https://developers.openai.com/codex/mcp).

## Tool reference and examples

The examples below show both a natural-language request that can be given to Codex and the structured input received by the tool. Codes and IDs are illustrative.

### `search_wards`

Search ramas by name, public code, or city. Returns at most 25 results.

> Cherche la rama de Benidorm.

```json
{ "query": "Benidorm" }
```

### `inspect_ward`

Inspect one rama and list up to 100 profiles with their avatar, points, and creation date.

> Inspecte la rama RAMA et montre-moi ses profils.

```json
{ "ward_code": "RAMA" }
```

### `platform_stats`

Return aggregate platform statistics without personal player data.

> Donne-moi les statistiques globales de Noche Live.

```json
{}
```

### `ward_stats`

Return aggregate activity statistics for one rama.

> Donne-moi les statistiques de la rama RAMA.

```json
{ "ward_code": "RAMA" }
```

### `people_seen_today`

List unique people active on a given day through either the street experience or a live night. With no scope filter, the query covers the whole platform. `country` accepts an ISO country code such as `ES` or a country name. `date` defaults to today in the requested timezone.

> Qui s'est connecté aujourd'hui en Espagne ?

```json
{
  "country": "ES",
  "timezone": "Europe/Madrid"
}
```

For one rama on a historical date:

```json
{
  "ward_code": "RAMA",
  "date": "2026-08-28",
  "timezone": "Europe/Madrid"
}
```

### `rotate_presenter_code`

Invalidate a rama's old presenter code and return the replacement once. This is a destructive credential rotation, so record the returned value securely before closing the result.

> Fais tourner le code présentateur de la rama RAMA.

```json
{ "ward_code": "RAMA" }
```

### `preview_profile_merge`

Preview a merge between two same-name profiles in the same rama. The oldest profile is selected as keeper. No player data changes at this step.

> Prépare la fusion des profils 41 et 96 dans la rama RAMA.

```json
{
  "ward_code": "RAMA",
  "first_id": 41,
  "second_id": 96
}
```

Inspect the returned keeper, source, and effect before using the returned `confirmation` value.

### `confirm_profile_merge`

Execute exactly one previously previewed merge. The confirmation token is short-lived and single-use.

> Confirme la fusion que nous venons de vérifier.

```json
{
  "confirmation": "short-lived-confirmation-returned-by-preview"
}
```

### `create_noche_live`

Create a new Noche Live owned by an explicit rama. `starts_at` must be an ISO 8601 timestamp including its UTC offset. Supported presenter languages are `es`, `pt-BR`, `fr`, and `en`. The response includes the generated session code and player, presenter, and public paths.

> Crée une Noche Live pour la rama RAMA le 30 août à 19 h 30, heure de Madrid, en français, avec Sœur Martin et Élder Silva.

```json
{
  "ward_code": "RAMA",
  "starts_at": "2026-08-30T19:30:00+02:00",
  "presenter_locale": "fr",
  "broadcast_delay_ms": 0,
  "missionary_names": ["Sœur Martin", "Élder Silva"],
  "theme_id": "reyes_y_profetas"
}
```

The lifecycle remains manual: creation does not start the night.

### `edit_noche_live`

Edit the schedule, presenter language, broadcast delay, or complete missionary list of an existing Noche Live. `ward_code` is mandatory even when the session code is known; the API rejects cross-rama edits. Omitted fields remain unchanged. Passing an empty `missionary_names` array removes all missionaries.

> Décale la Noche Live DAVID de la rama RAMA à 20 h et garde seulement Sœur Martin.

```json
{
  "ward_code": "RAMA",
  "session_code": "DAVID",
  "starts_at": "2026-08-30T20:00:00+02:00",
  "missionary_names": ["Sœur Martin"]
}
```

Starting, pausing, resuming, and finishing a night are intentionally not exposed by these two scheduling tools.

## Expected errors

- `401 Unauthorized`: the token is absent, different from Render, or too short.
- `404 Not Found`: the rama/session code does not exist, or the session does not belong to the supplied rama.
- `422 Unprocessable Entity`: invalid timestamp, locale, broadcast delay, missionary name, merge pair, or expired confirmation.
- MCP startup failure: check `NOCHE_ADMIN_API_URL`, `NOCHE_ADMIN_API_TOKEN`, `cwd`, then run `npm run typecheck` and restart Codex.

## Development checks

Run the focused application tests and MCP type check before deploying changes:

```sh
bin/rails test test/controllers/admin_api_test.rb
npm --prefix mcp/admin run typecheck
```
