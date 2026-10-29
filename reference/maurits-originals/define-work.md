---
name: define-work
description: Runs the planning/refinement pipeline (grill-with-docs → to-spec → to-tickets → triage) for a Linear Project (or a single ticket), entirely inline in whatever session invokes it — no worktree, no background agent, no batched Q&A relay, since planning produces only Linear artifacts (docs, issues, labels, comments), never code. Asks the user directly via ask_user as it goes. Stops once every issue in scope is `ready-for-agent` (or explicitly parked), ready for `factory-create` to pick up later.
---

# Define work

Takes a Linear Project (the normal case — created via a Wayfinder session or manually, holding a raw idea plus some initial tickets) through planning and refinement, entirely **inline**: no worktree, no herdr, no background agent. Planning produces no code — only Linear artifacts — so there's no infra to set up and no headless boundary to relay questions across. Ask the user directly, one question at a time, as you go.

## Quick start

```
/define-work <linear-project-url>
```

Falls back to single-ticket mode if given a plain ticket URL instead of a project — same pipeline, just scoped to that one ticket and its (to-be-created) children instead of a project's issues.

## The pipeline

| Stage | What it means | Skill that produces it |
|---|---|---|
| 1 | Raw idea (project/ticket created, maybe via a Wayfinder session) | — |
| 2 | Idea sharpened through interview | `grill-with-docs` |
| 3 | Overarching spec/PRD published | `to-spec` |
| 4 | Broken into small issues under the project | `to-tickets` |
| 5 | Each issue triaged to `ready-for-agent` (category + state labeled, agent brief posted) | `triage` |

**Never auto-advance a stage.** Detect where the project currently sits, tell the user, and ask before running `grill-with-docs`, `to-spec`, `to-tickets`, or `triage` — one stage, one confirmation, at a time, via `ask_user`.

## Workflow

1. **Resolve the project** via the Linear MCP server (name, id, description, existing issues/comments) and figure out which stage it's at.
2. **Stage 2 — grill-with-docs**: if the idea hasn't been sharpened yet, ask the user for a go-ahead, then run `grill-with-docs` faithfully (full docs research, full question depth) — but deliver it as a normal live interview via `ask_user`, one topic at a time, since there's no headless boundary here to batch questions across.
3. **Stage 3 — to-spec**: ask for a go-ahead, then run `to-spec`, publishing the spec (as a Linear document/project overview, per that skill's own conventions).
4. **Stage 4 — to-tickets**: ask for a go-ahead, then run `to-tickets`, creating each subticket as an **issue under the project** (`projectId` set, not a child of a single root ticket — this project may not have one root ticket at all):
   - **Never assign a cycle/sprint** — leave that field unset.
   - Title each with a two-digit human-readable execution-order hint (e.g. `01 - Add data model`), but this is a hint only.
   - **Declare every real dependency as a native Linear relation**: when an issue can only start once another completes, set `blockedBy` on it (`Linear-save_issue`) at creation time, pointing at the depended-on sibling. Issues with no dependency on any sibling get no `blockedBy` — this is what later lets `factory-start` run them concurrently. When in doubt whether two issues touch overlapping files/schema, declare the edge rather than leave it implicit.
   - Each issue's description holds full implementation details/acceptance criteria as a starting point — refined next by `/triage`.
   - Each issue starts unlabeled/`needs-triage`.
5. **Stage 5 — triage**: ask for a go-ahead, then run `/triage` against each issue in dependency order (issues with no unfinished `blockedBy` first) — category label, verification, grilling if needed, agent brief, exactly as that skill is written. Don't batch multiple issues' triage into one pass.
   - If `/triage` lands an issue on `needs-info`, `ready-for-human`, or `wontfix`: surface it to the user immediately. Because later execution is dependency-gated rather than strictly sequential, this only blocks issues that declare a `blockedBy` on it (or transitively depend on it) — independent issues can still be triaged and marked ready.
6. **Report**: once every issue in scope is `ready-for-agent` (or the user has explicitly told you to stop with some parked), summarize the project's issue set, their labels, and declared dependencies. Tell the user it's ready for `factory-create` whenever they choose to execute it — this skill does not create any worktree or launch anything itself.

## Notes

- **No worktree, no herdr pane, no background agent.** Planning produces Linear artifacts only. `grill-with-docs` may read the repo (read-only) from whatever checkout the invoking session already has, for context — it never needs an isolated worktree.
- **Runs inline wherever it's invoked** — in your main-branch session, in a herdr pane, wherever. There's no separate orchestrator identity for this skill; the invoking session simply *is* the orchestrator for the duration of the pipeline.
- **Issues live under the project, not a parent ticket.** `projectId` is the scoping field; there may be no single "outer ticket" at all in this workflow.
- **`blockedBy` relations are the one thing later execution (`factory-start`) actually reads** to decide what can run concurrently — the numeric title prefix is just a human hint. Get the dependency graph right here; it's the main thing this skill hands forward.
- **Never assign issues to a cycle/sprint** — they track work under the project without bloating the sprint board.
- **This skill's output is the input `factory-create` re-verifies.** It doesn't hand off directly to `factory-create` or `factory-start` — those are separate, deliberate invocations you make later, possibly much later, possibly after further manual refinement.
