---
name: define-work
description: Plan and refine a Linear project or ticket until its tickets are ready for an agent to build alone in a worktree. Runs grill → spec → scenarios → split into tickets → refine, live in the current session, and writes only to Linear, never code. Use when the user wants to plan, scope, refine, break down or "define" a Linear project or ticket, turn an idea into agent-ready tickets, or refine a parked ticket further, even if they don't name this skill.
---

# Define work

Turn a Linear project (or one ticket) into tickets that an agent can build **from start to finish without asking anything**. That is the whole point: the worktree agent has nobody to ask, so every question must be answered here.

```
/define-work <linear-project-url>     # project mode
/define-work <ticket-id-or-url>       # ticket mode: refine one (parked) ticket into sub-tickets
```

This runs in the session that calls it. It makes no worktree and writes no code.

## Before you start

- The repo must be set up for Matt Pocock's skills: an "Agent skills" block in `CLAUDE.md` or `AGENTS.md` and files in `docs/agents/` (tracker = Linear, triage label names). If it is not, tell the user to run `/setup-matt-pocock-skills` first.
- The stages below use Matt Pocock's skills and Per Hassle's `spec-to-scenarios`, linked into `~/.claude/skills/` from the clones in `~/dev/vendor/`. Load them like this, at the start of each stage, never from memory:
  - **Grill**: load `grilling` and `domain-modeling` with the Skill tool.
  - **Spec, scenarios, split, refine**: `to-spec`, `spec-to-scenarios`, `to-tickets` and `triage` only start when a user types them, so the Skill tool cannot load them. Read `~/.claude/skills/<name>/SKILL.md` in full, and every file it links (for `triage`: `AGENT-BRIEF.md` and `OUT-OF-SCOPE.md`). When it names another skill that the Skill tool can load (`grilling`, `domain-modeling`), load that one with the Skill tool. Then follow it step by step, as if the user had typed it, with the changes this skill gives for that stage.
  - Not found: tell the user which skill is missing from `~/.claude/skills/`, and stop.
- Labels are real Linear labels, set with `mcp__linear__save_issue`, never a `**Label:**` line in the description. A label that does not exist yet: create it first, as `docs/agents/issue-tracker.md` says.
- Tool differences (question tool, model names) are in [references/tools.md](references/tools.md).

## The stages

Find out where the project is now (existing spec? existing tickets? labels?), tell the user, and start at that stage.

1. **Grill.** `grill-with-docs` only loads two other skills, so load those two with the Skill tool (see *Before you start*; do not only read the files), and follow them fully: rounds of at most four numbered questions through `AskUserQuestion`, a recommended answer first, wait for the answers, update the glossary and ADRs as you go. Go on until the frontier is empty and the user confirms. **Pause:** "Grill done. Go on to spec and scenarios?"
2. **Spec.** Run `to-spec` and publish it to the project in Linear. No pause.
3. **Scenarios.** Run `spec-to-scenarios` on the spec, with these changes:
   - **Destination** is the spec itself: the Linear document from stage 2 (project mode), or the parent ticket (ticket mode). Save the Gherkin there under `## Scenarios`. Do not ask for another ticket.
   - **No brief file.** Skip its `specs/<id>-brief.md` and the planner request: this skill writes only to Linear. Keep its readiness verdict.
   - **No UI** (no web app in the repo, such as a pipeline or an API): skip the browser parts and the Environment step. Each scenario then describes the observable result of a run (a row in a table, a file, a returned value) and becomes a test obligation at that level.
   - Its criteria questions only cover what the grill left open; skip decisions the grill already settled.

   **Pause:** show the scenarios per criterion and the verdict. "Scenarios done. Go on to tickets?"
4. **Split.** Run `to-tickets`. Rules for each ticket:
   - The description ends with `Covers: AS-1, AS-3` (the scenario IDs it makes pass, or `Covers: none`). Every scenario is covered by at least one ticket; say so before the pause, or name the uncovered ones.
   - Project mode: the ticket is under the project (`projectId`). Ticket mode: it is a sub-ticket of the ticket (`parentId`).
   - Every real "waits for" goes in as a native Linear `blockedBy` link. When unsure if two tickets touch the same files or data, add the link.
   - Title starts with an order hint: `01 - ...`. It is a hint for people; agents only read `blockedBy`.
   - No cycle or sprint.
   - Label `needs-triage`.

   **Pause:** show the list (title, waits for, one line of what it delivers) and ask which tickets to refine **now**. The others stay `needs-triage`; the user refines them later with `/define-work <ticket>`.
5. **Refine.** For each chosen ticket, in `blockedBy` order, run `triage` on it. The brief it writes must follow [references/ticket-brief.md](references/ticket-brief.md): derive the **test seams** and the **done check** from the scenarios the ticket covers and agree them with the user here, and set the **level** and (if there is a reason) the **tool**. One ticket at a time.
   - A ticket that is too big to build in one session: do not force it. Leave it `needs-triage` and say "refine this one with `/define-work <ticket>`".
   - Outcome `ready-for-agent`, `ready-for-human`, `needs-info` or `wontfix`: as `triage` says. Set it as the real Linear label and remove `needs-triage`. Check with `mcp__linear__get_issue` that the label is on the ticket. Tell the user about every ticket that does not end `ready-for-agent`.

## Report

End with a table: ticket, label, waits for, level, tool. Then say how to start the build:
- Project mode: "Start it with `/factory-create <project-url>`."
- Ticket mode: "Start it with `/factory-create <parent-ticket>`."

Do not start anything yourself.
