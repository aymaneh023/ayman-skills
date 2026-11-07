---
name: factory-create
description: Start the build of one Linear project, or one parent ticket with sub-tickets, whose tickets are ready for an agent. Makes a worktree and a space in the Herdr app (via spin-up-worktree), starts a fresh Claude Code session there, and tells it to run factory-start. Then this session is done. Use after define-work, or when the user says "start the factory", "factory-create <project or ticket>", or wants a planned project or ticket built by agents. It does not plan, triage or build anything itself. One project or ticket per run.
---

# Create factory

Take a project or ticket that `define-work` made ready, and start the build. This skill only does the Linear part: find the tickets, check they are ready, write the starting prompt. `spin-up-worktree` does the worktree, the app space and the session. `factory-start` does the build, inside that session.

```
/factory-create <linear-project-url>   # project mode
/factory-create <ticket-id-or-url>     # ticket mode, e.g. CPE-1613
```

Run it from inside the repo, with the Herdr app open. Not in the repo: ask which one.

## Labels

Read the triage label names from the repo's `docs/agents/` (written by `/setup-matt-pocock-skills`). Below, `ready-for-agent` means the repo's name for that label. A ticket counts as ready when it has the label, or when its description has a `**Label:** ready-for-agent` line (some repos put it there). No `docs/agents/`: tell the user to run that setup first, or use the default names if they say so.

## Ticket mode

A project gets parallel branches. A parent ticket gets **one branch and one worktree**. Its sub-tickets are built on that branch, one after another.

- The work is the sub-tickets (`mcp__linear__list_issues` with `parentId`). The parent holds the spec. It is never built and needs no label.
- A ticket without sub-tickets is not a factory. Stop and say so. For one ticket, use `/spin-up-worktree` with a prompt to build it.
- Branch: `<identifier>-<title in kebab-case>`, lowercase, e.g. `cpe-1613-topics-selection`. The id links the PR in Linear. Never use Linear's `gitBranchName` (`<user>/cpe-…`): the slash breaks the worktree path.
- Base: `main`, unless the ticket says another base branch.

## Steps

### 1. Find the project or ticket

Project mode: `mcp__linear__get_project` for name, id and URL. Slug: the name in kebab-case, max ~60 characters.

Ticket mode: `mcp__linear__get_issue` for id, title, URL and description. Slug: `<identifier>-<title in kebab-case>`, lowercase, max ~60 characters. Note a base branch if the description names one.

### 2. Check every ticket is ready

List every ticket in the project (or every sub-ticket) and check each has `ready-for-agent`. Always check again, even right after `define-work`. Labels change.

- All ready → step 3.
- Not all ready → list which ones, with their label. Ask (`AskUserQuestion`):
  - Go on with only the ready ones (recommended)
  - Wait, make nothing yet
  - I fix it first

Never make a worktree for tickets that are not ready, without asking.

### 3. Write the starting prompt

Project mode:

> You run the build of Linear project `<project-url>` (`<project-name>`), on branch `<slug>`. Do all git, file and shell work in this worktree. Every ticket is checked `ready-for-agent`. Start now: run the `factory-start` skill yourself, in this session, with `linear_project_url: <project-url>`, `base_branch: <slug>`, `base_worktree_path: <this worktree's path>`, `max_concurrency: 3`. Ask me if I want another concurrency, but do not wait for my answer to start. When I ask for progress, answer from the state file. When it is done, ask me before you push or open a PR into `main`.

Ticket mode:

> You run the build of Linear ticket `<identifier>` (`<title>`, `<issue-url>`), on branch `<slug>`. Do all git, file and shell work in this worktree, on this one branch. Every sub-ticket is checked `ready-for-agent`. Start now: run the `factory-start` skill yourself, in this session, with `linear_parent_issue: <identifier>`, `base_branch: <slug>`, `base_worktree_path: <this worktree's path>`. It builds the sub-tickets one after another on this branch. When I ask for progress, answer from the state file. When it is done, ask me before you push or open a PR into `<base-ref>`.

### 4. Run `spin-up-worktree`

With:
- `branch: <slug>`
- `label: <LINEAR-ID> <Short Title>`, e.g. `CPE-788 Bulk Company Export`. Project mode: the lead ticket's id. Ticket mode: the parent's id and title.
- `base_ref: main`, or the ticket's base
- `starting_prompt: <the prompt from step 3>`
- `install_deps: yes`
- `model: sonnet`. This session only plans the order, checks and merges. The builders it starts get their own model per ticket Level. Never `opus` here.

It fails (unclear branch, check failed): tell the user exactly what it said. Do not retry.

### 5. Report and stop

Tell the user: project or ticket, branch, worktree path, the space name, the terminal address (e.g. `t5`), and that the prompt landed (checked). Then stop. Do not follow the build from here. The user opens the space in the app for that.

## Why factory-start runs in the space's own session

A Claude Code subagent cannot start its own subagents. `factory-start` starts one agent per ticket. So it must run in the space's main session, not as a background agent. The session stays free anyway: the builders run in the background.
