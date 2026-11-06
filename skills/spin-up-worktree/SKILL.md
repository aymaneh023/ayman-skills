---
name: spin-up-worktree
description: Make (or reopen) a git worktree with a herdr workspace and pane, and start a fresh Claude Code session in it with a starting prompt from the caller. The session starts in the trusted ~/dev folder, so it keeps the approved permissions, then moves into the worktree. Checks that the prompt really landed. Use whenever something needs its own branch and worktree with an agent in it: factory-create, or a direct "spin up an agent on branch X" or "spin up <ticket>". Not tied to Linear. Herdr commands are in REFERENCE.md.
---

# Spin up a worktree

Make a worktree, put it in a herdr pane, install dependencies, start Claude Code there and give it a prompt. This skill does not care *why*. The caller (`factory-create`, or the user) gives the starting prompt.

```
/spin-up-worktree <branch> [prompt]
```

## Run it in the background

When the user runs this skill directly, do not do the steps in this session. Hand them to a background agent, so the user can keep working here:

- Agent tool, `subagent_type: general-purpose`, `model: sonnet`, `description: spin up <ID or branch>`.
- Prompt: "Read and follow `~/.claude/skills/spin-up-worktree/SKILL.md` (`~` is the home folder), from *Ticket* on, with these inputs: <inputs>. The current repo is `<repo path>`. You cannot ask the user anything. Where the skill says to ask, stop and report the question instead."
- Tell the user in one line: "Spinning up `<ID>` in the background. I'll tell you when the pane is up."
- When it finishes, relay its result: the outputs, or exactly what stopped it. If it stopped on a question, ask the user, then start it again with the answer as an input.

When `factory-create` calls this skill, do the steps in place. That session has nothing else to do.

## Before you start

- You must be in a herdr pane: `test "${HERDR_ENV:-}" = 1`. If not, say so and stop.
- Run git from inside the target repo (a folder under `~/dev`). Not clear which repo: ask.
- Repo names have spaces (`Company profile agents`). Quote every path.
- The herdr binary is the authority. When unsure, run `herdr <group> <command> --help`. See [REFERENCE.md](REFERENCE.md).

## Inputs

- `branch`: lowercase kebab-case, no slashes. Required.
- `label`: the workspace title, `<LINEAR-ID> <Short Title>`, e.g. `CPE-1619 Bulk Company Export`. Not given: take the Linear id from the branch or request, fetch the issue (`mcp__linear__get_issue`), and shorten its title to 2–3 words. No ticket: a 2–3 word summary of the task.
- `base_ref`: the branch to start from, e.g. `main`. Only needed when the branch does not exist yet.
- `starting_prompt`: the exact text for the new session. The caller writes it.
- `install_deps`: default yes.
- `model`: `haiku`, `sonnet` or `opus`. Not given:
  - A Linear ticket is involved: read the `Level:` in its brief (the `triage` comment, `mcp__linear__list_comments`) and map it with [tools.md](../define-work/references/tools.md): `light` → `haiku`, `standard` → `sonnet`, `heavy` → `opus`.
  - No ticket, or no Level: `sonnet`.

  Never leave it empty. An empty model takes the default from `settings.json`, which is `opus`.

## Ticket

When the user spins up a Linear ticket directly (`/spin-up-worktree VAS-53` or a ticket URL), do this first. Skip it when `factory-create` calls you: `factory-start` moves the tickets itself.

1. Fetch it: `mcp__linear__get_issue`, then `mcp__linear__list_comments`. The brief is in the description or in the `triage` comment.
2. Check it is ready: the `ready-for-agent` label (name from `docs/agents/triage-labels.md`), or a `**Label:** ready-for-agent` line in the description. Not ready: tell the user and ask before you go on.
3. Take from the brief: `Level` (for `model`), `Tool`. A Tool other than empty or `claude`: tell the user and stop.
4. Branch: `<identifier>-<title in kebab-case>`, lowercase, max ~60 characters, without a `01 - ` number. Never Linear's `gitBranchName` (the slash breaks the path). Label: `<ID> <2–3 word title>`.
5. Starting prompt, unless the caller gave one: build the ticket with the `tdd` skill against the brief's test seams; commit on the branch with messages that start with `<ID>:`; done when the Done check passes; do not run "For the user" steps, list them; do not push or open a PR without asking. Add the full ticket description and brief.
6. Move the ticket to `In Progress` (`mcp__linear__save_issue`, `state: "In Progress"`). Do this only after step 6 of *Steps* confirms the prompt landed. A failed spin-up leaves the ticket as it was.

## Output

Return `workspace_id`, `root_pane_id`, `agent_name`, `worktree_path`, `branch`, `model`, and "new" or "reopened". The caller tells the user. You only talk to the user about problems.

## Rules

1. **Never take the user's focus.** Use `--no-focus` on every `worktree create`, `worktree open` and `pane split`. The only `focus` call is the restore in step 7.
2. **Start Claude Code in `~/dev`, never in the worktree.** Claude Code ties permissions to the folder it starts in. A new worktree is not trusted yet, so starting there asks for trust again. `dev` is trusted.
3. **A prompt response is not proof.** `agent prompt` types keys into the pane. Success means the keys were sent, not that the agent read them. A timeout does not mean they were lost. Always do the check in step 6.
4. **Target by pane id.** Once you have a `pane_id`, use it for every command. Never target by branch or label.
5. **Ask, don't guess.** Never reuse, rename or recreate a branch or worktree without asking when it is not clear.

## Steps

### 0. Note the user's focus

```bash
herdr workspace list
```
Note the workspace with `"focused": true` as `<original_workspace_id>`.

### 1. Is there a live pane for this branch?

```bash
herdr worktree list
```
- One → reuse it. Run `herdr workspace rename <workspace_id> "<label>"` and go to step 4.
- More than one → ask which one.
- None → step 2.

### 2. Does the branch or worktree exist?

```bash
git show-ref --verify --quiet "refs/heads/<branch>"
git worktree list --porcelain
```
- No branch → create (step 3).
- Branch, but no worktree folder → ask: "Use the existing branch `<branch>`" (recommended), "Make a new branch", or custom.
- Branch and folder, no pane → reopen (step 3).

### 3. Create or reopen

```bash
repo_root=$(git rev-parse --show-toplevel)
worktree_path="${repo_root}.worktrees/<branch>"
```

Create:
```bash
herdr worktree create --cwd "$repo_root" --branch "<branch>" --base "<base_ref>" --path "$worktree_path" --label "<label>" --no-focus
```

Reopen:
```bash
herdr worktree open --cwd "$repo_root" --path "$worktree_path" --label "<label>" --no-focus
herdr workspace rename <workspace_id> "<label>"
```

Read `workspace_id` and `root_pane.pane_id` from the JSON. Do not predict them.

A Git trust error: do not add `--trust-repository` yourself. Ask the user to confirm the repo first.

### 4. Install dependencies

Pick the command from the worktree root:

| File | Command | Wait for |
|---|---|---|
| `uv.lock` or `pyproject.toml` | `uv sync` | `--regex "(Installed\|Audited\|Resolved) \d+ package"` |
| `pnpm-lock.yaml` | `pnpm install` | `--match "Done in"` |
| `package-lock.json` | `npm install` | `--regex "(added\|up to date)"` |
| none | skip | |

```bash
herdr pane run <root_pane_id> "<command>"
herdr pane wait-output <root_pane_id> <wait-for> --timeout 180000
```
Run it on a reopen too: `.venv` and `node_modules` are per worktree. A timeout: read the pane (`herdr pane read <root_pane_id> --source recent-unwrapped --lines 20`) before you call it failed. Skip when `install_deps: no`.

### 5. Go back to `dev` and start Claude Code

```bash
herdr pane run <root_pane_id> 'cd ~/dev'
```
Leave `~/dev` unquoted so the shell expands it. It works in PowerShell, Git Bash and zsh panes.

Agent names must match `[a-z][a-z0-9_-]{0,31}`. So use the lowercase Linear id (`cpe-1619`), or the branch cut to 32 characters. Not the label.

```bash
herdr agent start "<agent_name>" --kind claude --pane <root_pane_id> -- --model <model>
```
Everything after `--` goes to Claude Code itself. Check the pane's status line shows the right model (`herdr pane read <root_pane_id> --lines 20`). Wrong model: tell the user.
`agent_not_ready` (for example a trust prompt): read the pane and tell the user. Never answer a dialog yourself.

### 6. Send the prompt and check it

Make a nonce of 6 hex characters. Send this, with the caller's prompt at the end:

> `verify-<nonce>` **First, run `cd "<worktree_path>" && pwd`. Then reply with one line: `cwd-confirmed: <the path pwd printed>`.** After that, run every git, file and shell command inside `<worktree_path>`. If the path is not `<worktree_path>`, stop and report it. Do not use another folder.
>
> Then: `<starting_prompt>`

```bash
herdr agent prompt <root_pane_id> "<prompt above>" --wait --timeout 120000
```

The line must be in the reply text. Claude Code runs each shell command in its own process, so herdr's cwd fields never change and cannot prove the `cd`.

`agent_prompt_stalled`, `timeout` or `blocked`: do not send again. Check first. Send once more only if the nonce is missing. `blocked`: read the pane and ask the user.

Check, every run:
```bash
herdr pane read <root_pane_id> --source recent-unwrapped --lines 80
```
Both must be there:
1. `cwd-confirmed: <worktree_path>`. Git Bash may print `/c/Users/...` for `C:/Users/...`. That counts as the same. Nothing looser.
2. `verify-<nonce>`.

One is missing: stop. Do not report success. Say what is missing. The user can open the pane and paste the prompt. Never retry in a loop.

### 7. Give back focus and report

`<original_workspace_id>` no longer focused? Run `herdr workspace focus <original_workspace_id>`. Then return the outputs.
