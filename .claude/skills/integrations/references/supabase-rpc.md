# Supabase RPCs as the Automation Contract
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

Use when a workflow engine or service keeps automation state in Postgres and talks to it through PostgREST RPC calls.

## Pattern

Put state transitions in database functions so workflows stay thin and logic is testable in one place.

- `claim_<thing>` and `release_<thing>`: atomic claim and release of an item (see the queue rules in the integrations skill).
- `get_next_<thing>`: returns the next item; the gates (quiet hours, caps, opt-out, cooldown) live inside the function, not in the workflow.
- `update_after_<thing>`: owns retry logic, attempt counts and the next-attempt time. The caller reports the outcome only.
- `health_check_<area>()`: one function built from UNION ALL of cheap checks, one row per check with a status column. Call it from the heartbeat.

## Return shapes

- Return at least two columns. A single-column result is serialized by PostgREST as a bare scalar, and workflow engines then read the body as `false` or empty. Add a status or id column alongside.
- Changing a return signature requires DROP then CREATE; `CREATE OR REPLACE` cannot change it.
- `CREATE OR REPLACE` is atomic and live immediately. Save the previous definition (from the catalog) to a dated file before replacing.
- Avoid `WHEN OTHERS` catch-alls that return a default; they hide errors. Catch specific conditions or re-raise.

## Access and security

- Without GRANT EXECUTE on the function and table privileges for the calling role, PostgREST answers 42501 regardless of RLS policies. Grant explicitly after every new function.
- Use SECURITY DEFINER with a fixed `SET search_path` for lookups that must bypass RLS, and keep them narrow.
- Filter by tenant in every query even when RLS is on.
- The service-role key is server-only, used on system paths that have their own authentication. Never reuse it as an HMAC or signing secret.
- Public anon keys pasted into workflow nodes may hold write or delete rights. Audit what the role can do; prefer a dedicated narrow role.
- Session checks: prefer verifying claims from the token locally over a round-trip user lookup on every request. One project saw the round-trip account for most auth traffic and cause timeouts.

## PostgREST limits

- Default page size truncates results at 1000 rows, so counts and lists silently under-report. Paginate with ranges or request an exact count.
- An embed with more than one foreign key path between two tables fails with PGRST201; name the foreign key in the embed.
- After schema changes, the schema cache may lag; reload it before concluding a function is missing.

## Verify

Call the RPC with the same role and client the workflow uses, then inspect the raw JSON shape (array of objects, not a scalar). Check the effect in the table, not only the response.
