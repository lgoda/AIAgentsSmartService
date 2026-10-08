# Editing n8n via MCP or API
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

Tool names differ between n8n MCP servers and versions. Map each rule here to the equivalent tool of the server in use.

## Read path

1. Select the instance explicitly. Multiple instances may be exposed; confirm the one mapped to the account before any call.
2. Read the workflow structure (node names, types, connections) without parameters.
3. Fetch the target nodes individually by name.
4. Fetching a whole large workflow wastes context and invites rewriting it: avoid.

## Write path

1. Prefer field-level partial updates (find and replace on a parameter path).
2. Run the update in validate-only mode first when the tool offers it.
3. Validate the whole workflow after the update.
4. Re-read the node. The write response is not evidence.
5. Confirm which version is live: the active version can differ from the draft you edited. Test against what actually runs.

## Tool behaviours that report success but do nothing

- `retryOnFail`, `maxTries`, `onError`, and the workflow `errorWorkflow` are node-level or settings-level fields. Parameter-update tools accept them and change nothing. Use a full node update, a full workflow update, or the editor, then re-read.
- A disable-node operation has been reported as applied while the node stayed enabled. Re-read the `disabled` flag.
- Nested arrays and objects passed as parameter values can be serialized to strings. Re-read and check the type, not just the presence.
- Adding a node through a partial update sometimes fails. Workaround: create the node in a throwaway copy or use a full update, then swap.
- Credentials referenced by a node are not validated by the write. Run a test.

## API quirks

- Some n8n versions reject `PATCH` on workflows with HTTP 405. Fall back to `PUT` with the complete workflow body (nodes, connections, settings).
- A `PUT` replaces everything it is given. Build the body from a fresh full read, change one thing, and diff before sending.
- LLM clients that send a partial `nodes` array in a full update have wiped workflows. Guard against it: refuse any full update whose node count is lower than the current one unless the removal is intended and stated.
- Keep a rollback copy (inactive clone, or previous version id) before any full update.

## Activation

- Never deactivate a live inbound workflow to update it. The webhooks drop and inbound events are lost.
- Webhook paths are exclusive: a path can be active in only one workflow. When swapping versions, the new copy needs the old copy inactive first. Do the swap in the shortest window, and keep the same path and webhook id so callers do not change.
- Stop a scheduler by disabling only its trigger node, leaving the workflow active.
- Set the workflow timezone explicitly in settings. Do not rely on the instance default.
- After activation, call the webhook with a test payload and confirm an execution appears.

## Do not

- Do not copy credentials, tokens or keys into node parameters, notes or change records.
- Do not edit through the API a workflow someone has open in the editor: their save overwrites yours.
- Do not mass-edit shared sub-workflows; make additive changes and test each caller path.
