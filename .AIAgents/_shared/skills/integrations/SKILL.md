---
name: integrations
description: Rules for webhooks, third-party APIs, queues and retries, in code or a workflow engine - auth, idempotency, timeouts, error mapping, secrets, time and phone handling. Use when adding or changing an inbound webhook, outbound API call or retry queue.
metadata:
  managed-by: aiagents
---

# Skill: integrations

## Purpose

Make integrations fail loudly, run once and stay within latency budgets. Pair with the automation domain skill.

## When to use

- Adding or changing a webhook receiver, provider call or retry queue
- Debugging "it said success but nothing happened"
- Handling secrets, timezones or phone numbers at a boundary

## Hard rules

- A 2xx is not delivery. Poll status or read back; `pending`, `unconfirmed` ids and ignored-error runs are unproven.
- Run a daily heartbeat that always reports; fire each alert channel once to prove it works.
- Verify tool trace or platform state, never a model's self-report.
- Mark first, then send. Release every claim on every error branch. Claim before slow work.
- Dedupe keys are deterministic, never "now". Create endpoints take an idempotency key per (tenant, key); a replay returns 200 flagged as replay.
- Upserts never overwrite final states or manual edits with placeholders.
- Queues live in a table, not wait steps: pending, processing, then sent, failed, cancelled or dead_letter. Claim atomically, cap attempts, back off exponentially, release stale claims. Fix root cause before mass retry.
- Webhook auth fails closed (missing secret returns 500), compares in constant time, uses a per-tenant header secret (never a query string), and verifies HMACs over the raw body.
- Latency-bound webhooks (voice routing) never reject: on error return safe defaults.
- Budget every call: per-request timeout, total below the platform limit, one retry, then a retryable 503.
- Providers sit behind an interface plus a mock, returning ok or `error{code,message,retryable,statusCode}`. Never show raw provider errors to end users.
- Validate env with a schema at boot, failing fast. Per-client keys are stored encrypted, never returned by an API, never in repo or logs.
- Store UTC; pass the tenant timezone explicitly. Anchor date math at midday UTC.
- Normalize phones to E.164 at the boundary; never send a partial number.

## Workflow

1. Name the contract: direction, auth, idempotency key, latency budget, retry owner.
2. Write the failure path first: caller response, log, alert.
3. Add auth and idempotency before business logic.
4. Add timeouts and error mapping to outbound calls; test against the mock.
5. For deferred work, build table, claim, backoff and dead-letter first.
6. Apply the change via the automation domain skill.

## Verification

- Send a duplicate and a malformed request: one effect, clean rejection.
- Break the dependency: alert fires, claim released.
- Check final state at the provider, and times across a DST change.

## Failure modes

- Success shown, nothing sent -> status unpolled -> read back status.
- Double sends -> late claim or time-based key -> claim early, deterministic key.
- Jobs stuck processing -> worker died holding claim -> stale-claim release.
- Times off by hours -> offset-less parse or UTC cron -> explicit timezone.
- Webhook retried forever -> non-2xx on a known bug -> log, return 200.

## References

Optional companions: the `supabase` and `supabase-postgres-best-practices` skills.

| Sub-task | Open |
|---|---|
| RPC-based automation state | references/supabase-rpc.md |
| Italian-market projects | references/locale-it.md |
