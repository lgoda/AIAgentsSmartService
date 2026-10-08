# OpenAI models and API usage notes
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

These notes are volatile. Model names, parameters, pricing and API surfaces change often. Before relying on any name or setting below, check the provider's current documentation (or its docs tool, if one is attached) and the live platform configuration. If they disagree with this file, trust them and report the drift.

## Model families observed in production automation

| Use | Family observed | Notes |
|---|---|---|
| Chat and workflow agents (reasoning, tool use) | gpt-5.x | Often with per-tenant credentials chosen through a model selector, so each tenant is billed on its own account |
| Voice agent flows and post-call analysis | gpt-4.1 and its mini variant | Latency matters more than depth; mini for extraction and analysis |
| Voice notes (inbound audio) | Whisper-class speech-to-text | Transcribe first, then pass text to the agent |
| Photos and images | Vision-capable models | Pass the image to a vision model; keep the result as text context |
| Low-cost secondary apps | A small model (gpt-4o-mini class) via an aggregator such as OpenRouter | Acceptable for simple classification and drafting |

## Selection guidance

- Match the model to the latency budget first. Voice turns tolerate far less latency than chat; prefer smaller, faster models there and keep reasoning effort low.
- Use a small model for classification, extraction and analysis of finished conversations; reserve larger models for open-ended tool-using agents.
- Pin an explicit model name in configuration. Do not depend on a floating alias in production without a test run when it moves.
- Keep the model in per-tenant configuration, not in the prompt, so a model swap does not require a prompt edit. Change model or prompt, never both in one step.
- When a model changes, rerun the scenario battery (see evaluation.md); behavior around tool calls and refusals shifts between versions.

## API surface notes

- One setup ran a workflow-engine agent node with the Responses API option disabled (chat-completions style). If tool calls or parameters behave unexpectedly after a node or library upgrade, check this option first and compare against a working configuration.
- Structured output: prefer the provider's schema-constrained output when available; still keep a tolerant parser (accept JSON inside a code block) and a deterministic fallback for parse failures.
- Prompt caching rewards a stable prefix: keep invariant instructions and tool definitions first, volatile context last.
- Limit concurrency of parallel model calls and add retry with backoff, or a fallback model, for transient provider errors (rate limit, timeout, overload). Bound total time against the caller's timeout.
- Keys: one credential per tenant where billing or data isolation matters; reference credentials by name, never paste them into prompts or logs.

## Checking what is current

1. List the provider's current models and their documented limits (context window, supported parameters).
2. Confirm the parameter names you rely on still exist (reasoning effort, temperature support, max output tokens naming).
3. Test one call with the exact configuration the agent will use before changing a live agent.
4. Update this file's Last verified date only after doing the above.
