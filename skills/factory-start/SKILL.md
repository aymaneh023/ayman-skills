---
name: factory-start
description: Build every ready ticket of one Linear project (or, in ticket mode, every sub-ticket of one parent ticket, one after another on one branch). Each ticket gets a background Claude Code agent that builds it with /tdd. Project mode runs a small pool in separate worktrees, ordered by `blockedBy`, checks each result and merges it into the base branch one at a time, then cleans up. Runs in the session factory-create starts in a worktree pane. Never inside a subagent.
---

# Start assembly line

Build the tickets that `define-work` made ready. Each ticket gets one background agent. You are the one who starts them, checks their work and merges it.

Run this in a main session (the pane `factory-create` made). Not in a subagent: a subagent cannot start its own subagents.

## Inputs

- `linear_project_url` **or** `linear_parent_issue`. Exactly one, always named. Never guess it from the branch or path. Missing, or both given: ask.
- `base_branch`: default `git branch --show-current`.
- `base_worktree_path`: default `git rev-parse --show-toplevel`.
- `max_concurrency`: project mode only. Default 3. For 2 tickets, a pool is not needed. For 15, ask if they want more.

## Before you start

- Read the triage label names from the repo's `docs/agents/`. Below, `ready-for-agent` means the repo's name for that label. A ticket counts as ready when it has the label, or when its description has a `**Label:** ready-for-agent` line.
- The brief is in the ticket description or in the `triage` comment. Read both, for every ticket: call `mcp__linear__list_comments` on each one, even when the description already looks like a brief. `triage` writes its brief, with `Level:` and `Tool:` at the end, as a comment.
- Read the repo's lint, type and test commands from `AGENTS.md`, `CLAUDE.md` or `docs/agents/`. They win over the defaults under *Check*.
- Paths have spaces. Quote every path.
- Check the code review can run, before any builder starts. A review that fails only at the end of a ticket parks work that was already built.
  1. Docker answers: `docker info`. It doesn't and the machine has OrbStack (`orb status` says Stopped): run `orb start` and check again.
  2. The review server can read the worktree: `docker inspect multi-code-review-review-mcp --format '{{range .Mounts}}{{.Source}} {{end}}'` lists a folder that contains `base_worktree_path`.

  Either fails: stop, and tell the user exactly which, with the fix (`orb start`, or widen `MCR_ROOT` in the review server's `.env` and run `docker compose up -d` there). No review server container at all: say so once, and go on under the exit 2 rule in *Check*.

## The brief

Each ready ticket has a brief, in the form of `define-work`'s [ticket-brief.md](../define-work/references/ticket-brief.md). It is in the description or in the `triage` comment (`mcp__linear__list_comments`). You use:

- **Test seams** and **Done check**: given to the builder; you run the Done check yourself.
- **Level**: picks the model.
- **Tool**: anything but empty or `claude` (e.g. `codex`): do not build it here. Park it and put it in the report.
- **For the user**: never run. Collect it for the report.

## Model

Always pass an explicit `model` to every agent you start. Never let it take this session's model. Pick it from the Level, as [tools.md](../define-work/references/tools.md) says:

| Level | `model` |
|---|---|
| `light` | `haiku` |
| `standard` (default) | `sonnet` |
| `heavy` | `opus` |

- Where the Level comes from: the last `Level:` line in the `triage` comment (headed `## Agent Brief`). No such comment: the description. Both have one: the comment wins, because triage wrote it later. Save `level_source` (`comment` or `description`) in the state file next to `level`.
- No Level in either place: `sonnet`, with `level_source: none`. Name those tickets in the first progress message, so the user can correct it before they start. Never default silently.
- Pick once, at the start. Do not change it during the run.
- A fix for the check can use `haiku` only when it is clearly mechanical (an unused import).
- Never run two `heavy` tickets at the same time.

## Order

Only `blockedBy` decides order. Read it with `mcp__linear__get_issue` and `includeRelations: true`. The `01 - ` in a title is a hint for people, not a dependency.

A ticket is ready to start when every ticket in its `blockedBy` (inside this scope) is `Done`.

## Ticket mode

All work happens on `base_branch` in `base_worktree_path`. No pool, no extra worktrees or branches, no merges, no cleanup. Everything else still applies.

1. Get the parent (`mcp__linear__get_issue`), its sub-tickets (`mcp__linear__list_issues` with `parentId`), and each one's relations and brief (description and comments, see *The brief*). Leave out and report sub-tickets that are not `ready-for-agent`. Move the parent to `In Progress`. Never mark the parent `Done`; the PR closes it.
2. Sort by `blockedBy`. When there is a choice, take the lower title number.
3. For each sub-ticket, one at a time:
   - Check its label again. Changed: park it and everything that waits for it.
   - `start=$(git -C "<base_worktree_path>" rev-parse HEAD)`. Move it to `In Progress`.
   - Start one builder (*Builder prompt*), in `base_worktree_path`. Wait for it. Never two at once: they share the folder.
   - Save its report to its report file, as step 4 of project mode says.
   - Check it (*Check*). Touched files: `git -C "<base_worktree_path>" diff --name-only --diff-filter=ACMR $start..HEAD`. Fails: `SendMessage` the same builder to fix exactly those errors. Check again. Never go on while it fails.
   - Post its Build notes (*Build notes*). Move it to `Done`.
4. Final check (step 6 of project mode).
5. Report.

## Project mode

### 1. Make the state file

Get the project (`mcp__linear__get_project`) and its tickets (`mcp__linear__list_issues`). For each: label, relations, and the brief from both the description and the comments (`mcp__linear__list_comments`). Tickets that are not `ready-for-agent`: leave out and report. They do not block the others.

Write the state to `$(git -C "<base_worktree_path>" rev-parse --git-common-dir)/factory/<base_branch>.json`. It is inside `.git`, so it is never committed:

```json
{
  "target": "<project url>",
  "base_branch": "<base_branch>",
  "issues": {
    "CPE-161": {
      "title": "01 - Add data model",
      "blocked_by": [],
      "level": "standard",
      "level_source": "comment",
      "model": "sonnet",
      "branch": null,
      "worktree_path": null,
      "agent_id": null,
      "state": "pending"
    }
  }
}
```

`state`: `pending`, `running`, `check_failed`, `done` or `parked`. Update it at every change. Answer progress questions from it.

### 2. Fill the pool

Free slots = `max_concurrency` minus tickets in `running` or `check_failed`. Ready = `pending` tickets whose `blocked_by` are all `done`.

For each ready ticket, up to the free slots, with `<id>` = its lowercase Linear id:

- Check its label again. Changed: `parked`, report it, go on.
- Make a plain worktree (git only, no herdr):
  ```bash
  sub_path="<base_worktree_path>-<id>"
  git -C "<base_worktree_path>" worktree add -b "<base_branch>-<id>" "$sub_path" "<base_branch>"
  ```
  Install dependencies there if tests need them, with the commands `spin-up-worktree` step 4 picks.
- Move it to `In Progress` in Linear. Leave the label alone.
- Start a background builder: Agent tool, `subagent_type: general-purpose`, `model` from the Level, `description: build <ID>`, with the *Builder prompt* for `$sub_path`.
- Save `branch`, `worktree_path`, `agent_id`, `model`, `state: running`.

### 3. Wait

Wait for the next notification. Do not poll. Handle one at a time, in the order they come. That keeps merges one at a time.

### 4. Check, then merge

First save the builder's report, word for word, to `<state folder>/<base_branch>/<ID>-report.md` (the state folder is where the state file lives, inside `.git`). Save `report_path` in the state file. Until the Build notes are posted, this file is the only copy of the builder's Decisions that survives a crash, a `/clear` or a moved session. A resumed run reads it from there. After a fix round, add the new report below the old one.

Check the ticket in its own worktree (*Check*). Touched files: `git -C "$sub_path" diff --name-only --diff-filter=ACMR "<base_branch>...HEAD"`.

- Fails: `SendMessage` the same builder (`agent_id`) to fix exactly those errors, tests green. `state: check_failed`. The slot stays taken. Back to step 3.
- Passes: merge, from `base_worktree_path`. Finish it fully before the next notification:
  ```bash
  git -C "<base_worktree_path>" merge --no-ff "<base_branch>-<id>" -m "<ID>: <title>"
  ```
  A conflict: `git merge --abort`. Start a fixer in the ticket's worktree to rebase on the current `base_branch`. Check and merge again. Never solve a conflict by dropping one side.
- Merged: post its Build notes (*Build notes*), then move it to `Done` in Linear. `state: done`. Keep the worktree and branch until the end.

Then back to step 2: start what is now ready, before you wait again.

### 5. Stuck

Nothing `running`, nothing ready, but not all `done` or `parked`: stop. Report which tickets are stuck and why (a label change, a `blockedBy` loop, a parked dependency). Never spin.

### 6. Final check

When all are `done` or `parked`: check the whole branch. Touched files: `git -C "<base_worktree_path>" diff --name-only --diff-filter=ACMR main...<base_branch>`. Run every merged ticket's Done check again. This finds two clean tickets that break together. Fails: start a fixer in `base_worktree_path` (model rule applies). Repeat until clean.

### 7. Clean up

Remove every worktree and branch this run made:
```bash
git -C "<base_worktree_path>" worktree remove "<base_worktree_path>-<id>"
git -C "<base_worktree_path>" branch -d "<base_branch>-<id>"
```
Never `-D` or `--force`. One refuses: leave it and report it.

## Builder prompt

The builder is alone. It cannot ask anything. Give it all of this:

> You build Linear ticket `<ID>` (`<title>`) alone, in the worktree `<worktree path>` on branch `<branch>`. First run `git -C "<worktree path>" branch --show-current`. It must print `<branch>`; if not, stop and report. Run every git, file and shell command inside that worktree. Run each git command as its own call with `git -C "<worktree path>"`, never as `cd ... && git ...`: the permission check refuses the combined form. Never touch another worktree or branch.
>
> Use the `tdd` skill, against the test seams in the brief. Commit on `<branch>` in small commits that start with `<ID>:`. Commit each test while it is red, before the code that turns it green: the check reads the commit order. Do not push, open a PR or change Linear. Do not run what is under "For the user" (paid calls, evals, deploys). Only prepare it.
>
> You are done when the brief's Done check passes. Report: the files you changed, the Done check output, the "For the user" steps with exact commands, and **Decisions**.
>
> **Decisions** is for the human who reviews the PR without reading every line. Keep a running list while you build, not from memory at the end. One entry per item, each with the file it lands in:
> - **Gap**: the brief or description did not say; what you chose, what you rejected and why.
> - **Assumption**: something about existing code, data or an API you took as true without checking it. Say how sure you are.
> - **Beyond scope**: code you added or changed that the ticket did not ask for (a refactor, a helper, a touched shared file), and why it was needed.
> - **Left out**: anything the brief asked for that you skipped, stubbed, mocked or hard-coded, and test seams you did not cover.
> - **Judgement call**: a threshold, limit, default, prompt wording, model or parameter you picked.
>
> Write "None" for a type only when it is truly empty. A list that says the brief was clear on everything is almost always wrong.
>
> Ticket description:
> `<description>`
>
> Brief:
> `<full brief>`

## Check

Only the files the ticket touched. A full-project type check counts only errors in those files. The repo's own commands win. Otherwise:

| Repo | Lint | Types |
|---|---|---|
| Python (`pyproject.toml`) | `uv run ruff check <files>` and `uv run ruff format --check <files>` | `uv run mypy <files>` or `uv run pyright <files>` if set up, else skip |
| JS/TS (`pnpm-lock.yaml`) | `pnpm eslint <files>` | `pnpm typecheck` |

Then the deterministic review (Per Hassle's multi-code-review: offline analyzers, seconds, no tokens). It reviews the diff of the worktree against the branch it came from. It runs the repo's own eslint from the root's `node_modules`, and reads `lcov.info` files for coverage, so first run the repo's coverage command in every package the ticket touched (the repo's docs name it). A review that notes "eslint skipped" or no coverage report read: say so in the Build notes.

```bash
node ~/dev/vendor/phassle-multi-code-review/scripts/mcr.mjs review "<worktree path>" --base "<base_branch>"
```

On Windows, put `NODE_OPTIONS="--import=file:///C:/Users/AymanElHattache/.claude/hooks/mcr-winpath.mjs"` in front of it. That hook turns `C:\` paths into `/c/` paths for the Docker gateway. macOS needs nothing extra.

- Exit 0: passed.
- Exit 1: blocking findings. They count as a failed check: send them to the builder to fix. A finding the builder thinks is wrong goes to the user under Build notes; never silence it.
- Exit 2: read stderr. Only `mcr: the gateway does not answer` means Docker is off: go on without the review and say so in the Report. Any other exit 2 is a broken review, not a skipped one: set the ticket to `parked` (not `Done` in Linear), and give the exact stderr with the parked tickets in the Report. A ticket is never `done` without a review that ran or a gateway that was off.

For the whole-branch check, use `--base main` on `base_worktree_path`.

Then **test first**: every code change must have a test seen red before it. Read the ticket's commits oldest first (`git -C "<worktree path>" log --reverse --name-only <start>..HEAD`, where `<start>` is `<base_branch>` in project mode and the saved `start` in ticket mode). Each commit that changes a source file must change a test file itself, or come after a commit that does. A source commit with no test before it: `SendMessage` the builder to prove those tests red. In a temporary worktree at the commit before that code, copy in the new test files, run them, and report the output. They must fail for the reason the test names. A test that passes without the code tests nothing: the builder fixes the test. The proof goes in the Build notes. No red proof: the check fails.

And always: run the brief's Done check yourself. Do not trust the builder's report. Never lint the whole repo as the check. Never run paid checks.

## Build notes

When a ticket passes its check (before you move it to `Done`), post one Linear comment on it (`mcp__linear__save_comment`), headed `## Build notes`:
- The builder's **Decisions**, from its report file (`report_path`). The file is missing: say so in the comment, never rebuild the Decisions from memory.
- What you saw yourself: touched files the brief did not point to, and anything the diff shows that the builder did not mention. Add it as a **Beyond scope** entry or a **Left out** entry.
- Fixes after a failed check, and how you resolved any merge conflict (what each side wanted, what was kept).
- The "For the user" steps with exact commands.

This comment is the source for the PR's Risk, Gaps and Scope sections, so it must survive this session. Fixes made in the final check go as a comment on the parent ticket (ticket mode) or the ticket whose code they touch.

## Report

End with:
- A table: ticket, state (`done` or `parked`), model, merged.
- The final check result.
- Every "For the user" step, with exact commands.
- Parked or stuck tickets and why, and tickets with another Tool.
- Next: "Say yes and I push it, open a PR into `main`, and get it through the Copilot and Codex reviews. I ping you when it is ready for you."

Never push or open a PR without the user's yes. On a yes, write the PR with the `pr-message` skill (load it with the Skill tool), then run `review-loop`. `pr-message` reads the Build notes comments for its Risk, Gaps and Scope sections.

## After the merge

The user says the PR is merged: close the run out, in this order. Check first with `gh pr view <pr> --json state,mergedAt`: anything but `MERGED` → say so and stop.

1. **Threads.** The merge accepts the risks. Resolve every open thread from `review-loop`: `review-status.sh threads <pr>`, then `review-status.sh resolve <thread-id> <file>` with a one-line reply: "Accepted at merge, see Risk in the PR body." Ask items still open: list them, leave them open.
2. **Main.** In the repo's main checkout (`git rev-parse --path-format=absolute --git-common-dir` without `/.git`): `git fetch origin --prune`, then `git merge --ff-only origin/main` when it is on `main` with a clean tree. Otherwise say why you skipped it.
3. **Worktree and branch.** From the main checkout: `git worktree remove "<base_worktree_path>"`, then `git branch -d <base_branch>`. `-d` needs the branch in `main`, so update `main` first. Never `-D` or `--force`. One refuses: leave it and report it. Delete the state file and its report folder.
4. **Linear.** Every `done` ticket is `Done`. Ticket mode: the parent too (the PR should have closed it).
5. **Report** in one short list: what you resolved, removed and updated, and what you left and why.
6. **Space.** Last, because it ends this session: close this session's Herdr space. Use the `ha` function from `spin-up-worktree` (*Always talk to the user's own window*). In `ha ls`, find the space whose name starts with a ticket id of this run (`factory-create` names it `<ID> <Short Title>`). Not exactly one: list them and leave the space to the user. One: run `ha do space.close '{"id":"<space id>","confirmed":true}'`.