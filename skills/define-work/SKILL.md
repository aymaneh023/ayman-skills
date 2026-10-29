---
name: define-work
description: Plan and refine a Linear project or ticket until its tickets are ready for an agent to build alone in a worktree. Runs grill → spec → split into tickets → refine, live in the current session, and writes only to Linear, never code. Use when the user wants to plan, scope, refine, break down or "define" a Linear project or ticket, turn an idea into agent-ready tickets, or refine a parked ticket further, even if they don't name this skill.
---

# Define work

Turn a Linear project (or one ticket) into tickets that an agent can build **from start to finish without asking anything**. That is the whole point: the worktree agent has nobody to ask, so every question must be answered here.

```
/define-work <linear-project-url>     # project mode
/define-work <ticket-id-or-url>       # ticket mode: refine one (parked) ticket into sub-tickets
```

This runs in the session that calls it. It makes no worktree and writes no code.

## Before you start

- The repo must be set up for the SuperMatt skills: an "Agent skills" block in `CLAUDE.md` or `AGENTS.md` and files in `docs/agents/` (tracker = Linear, triage label names). If it is not, tell the user to run `/supermatt:setup-supermatt-skills` first.
- The stages below use the SuperMatt `grill-with-docs`, `to-spec`, `to-tickets` and `triage`. They only start when a user types them. So read each one's installed `SKILL.md` and follow it yourself.
- Tool differences (question tool, model names) are in [references/tools.md](references/tools.md).

## The stages

Find out where the project is now (existing spec? existing tickets? labels?), tell the user, and start at that stage.

1. **Grill.** Run `grill-with-docs` on the idea. **Pause:** "Grill done. Go on to spec and tickets?"
2. **Spec.** Run `to-spec` and publish it to the project in Linear. No pause.
3. **Split.** Run `to-tickets`. Rules for each ticket:
   - Project mode: the ticket is under the project (`projectId`). Ticket mode: it is a sub-ticket of the ticket (`parentId`).
   - Every real "waits for" goes in as a native Linear `blockedBy` link. When unsure if two tickets touch the same files or data, add the link.
   - Title starts with an order hint: `01 - ...`. It is a hint for people; agents only read `blockedBy`.
   - No cycle or sprint.
   - Label `needs-triage`.

   **Pause:** show the list (title, waits for, one line of what it delivers) and ask which tickets to refine **now**. The others stay `needs-triage`; the user refines them later with `/define-work <ticket>`.
4. **Refine.** For each chosen ticket, in `blockedBy` order, run `triage` on it. The brief it writes must follow [references/ticket-brief.md](references/ticket-brief.md): agree the **test seams** and the **done check** with the user here, and set the **level** and (if there is a reason) the **tool**. One ticket at a time.
   - A ticket that is too big to build in one session: do not force it. Leave it `needs-triage` and say "refine this one with `/define-work <ticket>`".
   - Outcome `ready-for-agent`, `ready-for-human`, `needs-info` or `wontfix`: as `triage` says. Tell the user about every ticket that does not end `ready-for-agent`.

## Report

End with a table: ticket, label, waits for, level, tool. Then say: "Start a ticket with `/spin-up <ticket>`." Do not start anything yourself.
