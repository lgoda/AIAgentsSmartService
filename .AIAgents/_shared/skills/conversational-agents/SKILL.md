---
name: conversational-agents
description: Design and change LLM agents for chat or voice - prompt layout, deterministic gates, fallbacks, retrieval rules and evaluation. Use when writing or editing an agent prompt, adding tools, or choosing a model for a conversational agent.
metadata:
  managed-by: aiagents
---

# Skill: conversational-agents

## Purpose

Treat an agent prompt as a production artifact: behavior you ship, test and roll back.

## When to use

- Writing or editing a system prompt, flow node prompt or persona text
- Adding, renaming or removing an agent tool
- Choosing or changing the model behind an agent

## Hard rules

- The prompt is behavior, not documentation. Never promise what the infrastructure cannot do (callbacks, emails, follow-ups).
- The platform is the system of record. Keep a repo copy of each live prompt marked "regenerate after change", plus a changelog.
- Change one thing at a time. Compare against a known-working configuration before rewriting.
- Layout: invariant rules first (cacheable), volatile context (date, caller, tenant data) after.
- Compute variables in code (dates, availability, caller status) and inject them. Never ask the model to calculate or look up.
- Keep gates outside the model: consent, permissions, payments, business hours. Code enforces; the prompt only explains.
- Per-tenant or per-persona behavior comes from injected playbook text in configuration, not forked prompts.
- Never claim success after a tool error. Verify the tool-call trace, not the model's self-report.
- Retrieval is a tool the agent calls. Never quote prices from the knowledge base; add a final deterministic check.
- Force the output language explicitly (generated summaries default to English). Use the locale's register; no emoji.
- Every LLM call feeding a workflow needs a deterministic template fallback for missing key, provider error or unparsable output.

## Workflow

1. Read real conversations first. Write rules from observed failures, not from field counts.
2. State the single behavior to change and the observable difference expected.
3. Place it: code gate, code variable, invariant rule, or volatile context.
4. Make the narrowest edit. Remove contradicting older text.
5. Check structure: no dangling step references, no tool named in the prompt that is not attached.
6. Run the evaluation procedure against the known-working version.
7. Record change and evidence in the changelog.

## Verification

- Read full transcripts of scenario runs, not summaries.
- Confirm the expected tool calls and the downstream effect (record created, message sent) in the target system.
- Repeat each scenario several times; one pass proves nothing.

## Failure modes

- Says "done", nothing happened -> tool errored and the prompt allowed continuing -> read the trace; add a stop-and-report path.
- Wrong date, price or availability spoken -> model computed or recalled it -> compute in code, or force a tool call.
- Promised callback never comes -> prompt describes an unbuilt capability -> remove the promise or build it.
- Rewrite made things worse -> several variables changed -> revert, compare, change one.

## References

Open only what you need. The automation domain skill owns the live-change workflow.

| Sub-task | Open |
|---|---|
| Testing or changing a live agent | references/evaluation.md |
| Choosing/configuring models | references/openai.md |
