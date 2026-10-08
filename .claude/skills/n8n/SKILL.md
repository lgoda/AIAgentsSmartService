---
name: n8n
description: Operate and edit live n8n workflows safely, including instance selection, narrow reads, partial updates, webhook-path versioning, activation rules and execution debugging. Use when reading, changing, testing or debugging an n8n workflow through an MCP server or API.
metadata:
  managed-by: aiagents
---

# Skill: n8n

## Purpose

Change and debug n8n workflows without dropping live webhooks or breaking shared logic. Follow the live-change steps of the automation domain skill; this skill adds the n8n rules. The optional third-party `n8n-workflow-patterns` skill covers generic node and workflow architecture.

## When to use

- Reading or editing a workflow, node, sub-workflow or webhook on an n8n instance
- Adding a tenant or cloning a shared workflow
- Investigating a failed, missing or "green but wrong" execution

## Hard rules

- Select the instance first, using the mapping in the project context. Never fall back to another instance.
- Read structure first, then only the nodes you need by name. Never fetch or rewrite a whole large workflow.
- Use field-level partial updates. A partial `nodes` array in a full update replaces all nodes and wipes the workflow.
- After every write, re-read the node. Some tools report success and change nothing, especially on node-level and settings-level fields.
- A webhook path is active in only one workflow. Version by swap: new copy active, old copy inactive, same path and webhook id. Keep the old copy as rollback.
- Never deactivate a live inbound workflow to update it: its webhooks drop. To stop a scheduler, disable only its trigger node.
- Set the workflow timezone explicitly to the tenant's configured timezone.
- Shared sub-workflows have high blast radius: additive changes only, since every tenant is affected. When cloning for a tenant, check residues: tenant id, credentials, null filters.
- Test Code-node logic offline with a case battery before publishing.

## Workflow

1. Select the instance, find the workflow by name, read its structure.
2. Read only the target nodes; confirm which version is active (not the draft) and record it as the rollback point.
3. Pick the write path (references/mcp-editing.md), preferring a field-level patch.
4. Validate in validate-only mode, then validate the workflow.
5. Apply, then re-read the node.
6. Trigger a test through the designated test resource and open the execution, including per-node run data.

## Verification

- The re-read node shows the new value on the active version.
- A test execution reaches the changed node with correct output.
- The downstream effect exists (message delivered, record written), not only a green run.

## Failure modes

- Update succeeded, behaviour unchanged -> node-level or settings-level field -> full node update or editor, then re-read.
- Webhook 404 or activation refused -> workflow deactivated, or another copy holds the path -> fix which copy is active.
- Workflow emptied -> partial `nodes` array sent -> restore the rollback copy.
- Executions missing, or `canceled` after a restart -> short retention and restart behaviour, not errors -> capture evidence early.
- Green run, wrong output -> a node failed softly -> inspect per-node run data.

## References

| Sub-task | Open |
|---|---|
| Editing a live workflow through an MCP server or API | references/mcp-editing.md |
| Designing or extending workflows | references/patterns.md |
