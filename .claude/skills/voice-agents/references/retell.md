# Retell Platform Reference
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

Scope: versioning, API behaviour, tuning values and per-tenant provisioning for agents on the Retell platform. Generic rules live in SKILL.md.

## Versioning and publish

- Published versions are immutable; editing one returns 422.
- To change a published agent: create a new version from the published base, PATCH it with `?version=N`, then publish with the version in the request body.
- An unpublished version is edited in place. Calls that do not pin a version use the latest version even when it is unpublished. Treat every flow save as live.
- A flow update may or may not bump the version. Read the agent's response engine version after each write and do not assume.
- Record the previous published version id before editing; that is the rollback point.

## PATCH semantics

- PATCH on `nodes` replaces the whole array. There is no merge by node id: read the full array, modify it, send it all back.
- The global prompt can be patched alone.
- Boosted keywords are replaced, not merged. Send the full list.
- Phone to agent binding uses the `inbound_agents[]` and `outbound_agents[]` arrays. The scalar agent fields are deprecated.
- Do not use the dashboard while editing through the API. A dashboard save can overwrite API changes.
- Re-read the object after every write. Do not trust the write response.

## API quirks

- Get-call takes the call id as a path parameter.
- `list-agent` is unversioned; other agent calls take a version.
- Version 3 list-calls takes structured filter criteria and omits the transcript. Fetch the transcript per call on demand.
- A cheap total count: request with `include_total` and a large skip, so almost no rows come back.
- There is no official SDK in use here. A thin fetch client with a typed error class is enough: status, endpoint and response body in the error.
- Keys are sent as Bearer tokens. Use one key per tenant account, never shared across clients.

## Tuning values that mattered

Starting points observed in production, not universal:

| Setting | Value |
|---|---|
| Begin-message delay | about 1s |
| Responsiveness | about 0.85 |
| Interruption sensitivity | 0.3 to 0.45 |
| Filler words | off |
| Backchannel | off |
| Speech recognition | accurate mode |
| Tool timeout (external tool servers) | 30s to 120s |

- Cost scales with prompt size times duration. Put node-specific rules in nodes and use cheaper models for simple nodes.
- Cloned voices are not portable across organizations. Always set the voice model explicitly; leaving it unset produced the wrong accent.
- Variables are not substituted inside finetune examples.

## Conversation flow patterns

- Use one central variable-extraction hub with ordered equation edges and `asked` and `verified` flags.
- Every extraction node has an else edge. Tool-error edges go to an error node.
- Pre-action nodes (skip response, block interruptions) cover the time a tool runs.
- FAQs are global nodes.
- Outbound calls receive context variables (prior chat transcript, agreed callback time, summary) and branch the opening line on them.

## Post-call

- Process only the "analyzed" event; ignore earlier call events.
- Map the disconnection reason to a call result.
- Typed analysis fields (enums, booleans) are more reliable than free text.
- Set the summary instruction language explicitly.
- Re-running analysis on a stored call validates a post-call model change.

## Per-tenant provisioning

1. Keep a template JSON with placeholders and a template version constant.
2. Make reruns idempotent: look the agent up by name before creating.
3. Issue a scoped key per agent and rotate it on each deploy.
4. Importing community voices is not idempotent: search by name first.
5. Bind the number through the `inbound_agents[]` array only after the agent is published and tested.

## Health monitoring

Script over paginated call lists, grouped by agent version, with baselines and alarm thresholds (failed tool calls, short calls, error disconnections). Run it after every publish.
