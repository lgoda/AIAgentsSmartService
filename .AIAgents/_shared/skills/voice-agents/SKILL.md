---
name: voice-agents
description: Vendor-neutral rules for phone AI agents - inbound routing, variables, conversation flow, transfers, tools, post-call analysis, latency and cost, testing. Use when building, changing or debugging a voice agent or its call handling.
metadata:
  managed-by: aiagents
---

# Skill: voice-agents

## Purpose

Keep phone AI agents correct, fast and cheap. The automation domain skill owns the live-change workflow; this skill adds voice-specific rules.

## When to use

- Changing a voice agent prompt, flow, tools or voice settings
- Building or debugging inbound routing, transfers or outbound calls
- Diagnosing latency, cost or wrong behavior in a call log

## Hard rules

- Inbound routing never rejects. Unknown numbers get generic defaults; answer within the platform timeout (about 10s) and keep the endpoint warm.
- Compute spoken names, brand and greeting in code and pass them as variables; the model never chooses them.
- Boolean gates match positively (`== 'false'`) so a missing variable never blocks.
- Real gates are flow edges. Prompt-only rules on global nodes are best-effort.
- Every extraction node has an else edge; tool errors route to an error node.
- Silence the agent while a tool runs (skip response, block interruptions).
- Transfer only to predefined numbers. The failure edge ends with a courtesy close; never leave voicemail.
- Declare tools where the platform exposes them to the agent, not only on the server. Raise tool timeouts above the default.
- Tool errors for voice consumers are plain text (see the mcp-servers skill).
- Decide post-call outcomes from facts (transcript and tool calls). Use typed analysis fields; set the summary language explicitly.
- Treat every save as live: some platforms serve the latest unpublished version.
- Test only from a designated test number. Never call real people.

## Workflow

1. Identify direction and the object to change (agent, node, tool, number).
2. Read the current agent, flow and recent calls.
3. Volatile facts go in variables, per-node rules in nodes; keep the global prompt short (paid every turn).
4. Change one node or setting at a time, additively.
5. Replay scenarios, then place a real test call.
6. Watch calls by agent version afterwards.

## Verification

- Inspect a real test call: transcript, tool calls with arguments and results, disconnection reason, call result.
- Confirm the downstream effect (booking, CRM note), not the tool's 2xx.
- Scenario batteries: several runs each, must and must-not patterns; they cannot simulate external tools.
- After a post-call model change, re-run analysis on an old call; older calls lack new fields.

## Failure modes

- Silence on an unknown number -> routing rejected or timed out -> return defaults, warm the endpoint.
- Tool never called -> declared on the server, not the agent -> declare where exposed.
- Generic parse error from a tool -> structured error content -> plain text.
- Wrong accent -> voice model unset or voice not portable across organizations -> set explicitly.
- Slow call start -> cold tool server or slow auth hashing -> keep warm, cache verification.
- Cost creep -> large global prompt times duration -> move rules into nodes, cheaper model for simple nodes.
- Examples override instructions and get no variable substitution -> keep them neutral.

## References

| Sub-task | Open |
|---|---|
| Changing or provisioning an agent on the Retell platform | references/retell.md |
| Phone numbers, carriers, SIP trunks | references/sip-trunking.md |
