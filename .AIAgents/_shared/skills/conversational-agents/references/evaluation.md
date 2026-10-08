# Evaluation of conversational agents
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

## Principle

Validate by reading what the agent actually said and did. Counting fields, scores or tool calls hides the failures that matter. A rule derived from field counts was rolled back within minutes once real conversations were read.

## Procedure for any prompt or flow change

1. **Baseline.** Identify a known-working configuration (usually the current live version). Never rewrite from scratch without comparing against it.
2. **Read first.** Sample real conversations or calls (see shadow sampling) and list concrete failures with quotes.
3. **One variable.** Change exactly one thing: one rule, one tool description, one model, one parameter. One test cannot tell a cause from a coincidence, so repeat runs.
4. **Candidate vs live.** Run the same scenarios against both, several runs each (N >= 3; more for stochastic behavior). Record outcomes per run.
5. **Read transcripts.** Open every failing run and a random sample of passing ones.
6. **Decide.** Promote only if the candidate is equal or better on every must-check and shows the targeted improvement. Otherwise revert and try the next hypothesis.
7. **Record.** Add version, change, evidence and result to the changelog.

## Scenario batteries

A scenario is a scripted caller or user with a goal, plus checks.

- Cover: the happy path, each tool, each gate (refusal, out-of-hours, missing data), ambiguous input, interruptions, wrong language, abusive or off-topic input, and a request the agent must not fulfil.
- Each scenario has **must** checks (required tool call, required fact stated, handoff happened) and **must-not** checks (price quoted, promise made, tool called without consent, forbidden phrase).
- Check the tool trace and the downstream effect, not only the words.
- Use a designated test resource (test number, test contact, test calendar) so runs never touch real people.
- Keep batteries in the repo next to the prompt; add a scenario for every production failure you fix.

## Shadow sampling

- Review or replay a large sample of real traffic (hundreds of conversations) against the candidate without letting it act.
- Sample across channels, times, languages and outcomes, including failures and short or abandoned conversations.
- Use it to find rule gaps and to estimate how often a failure occurs before and after a change.

## Baselines and thresholds

- Store per-version baselines: pass rate per scenario, plus rates measured from shadow sampling (handoff rate, tool-error rate, abandonment).
- Set a threshold per metric. A change that crosses a threshold needs an explicit decision, not a silent merge.
- Mark each figure as measured or inferred in the changelog.

## Structural checks

Run these before any behavioral test; they are cheap and catch outright breakage.

- No dangling references: every node, step or branch target exists.
- No phantom tools: every tool mentioned in the prompt is attached, and every attached tool is described.
- No orphan variables: every placeholder in the prompt is supplied at runtime.
- No contradictions between the invariant block and per-tenant playbook text.
- Required output fields are present in the structured-output schema.

## Independent adversarial review

Before go-live of a new or heavily changed agent, get a review from someone (or a separate agent session) who did not write it. Brief the reviewer to break it: prompt injection, social engineering around gates, tool misuse, hallucinated facts, unsafe promises. Fix findings and rerun the battery.

## Post-call and summary analysis

Where an LLM produces summaries, categories or extracted fields from a conversation, derive them from facts (tool results, recorded events) rather than the model's impression, and force the output language. Evaluate these outputs with the same read-the-sample method.
