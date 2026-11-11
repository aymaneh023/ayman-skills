---
name: spin-up-worktree
description: Make (or reopen) a git worktree, open it as a space in the Herdr app with a fresh Claude Code session, and give that session a starting prompt from the caller. The session starts in the repo's own trusted checkout, so it keeps the approved permissions, then moves into the worktree. Checks that the prompt really landed. Use whenever something needs its own branch and worktree with an agent in it: factory-create, or a direct "spin up an agent on branch X" or "spin up <ticket>". Not tied to Linear. The hc and herdr-app commands are in REFERENCE.md.
---

# Spin up a worktree

Make a worktree, install dependencies, open a space for it in the Herdr app with Claude Code in it, and give that session a prompt. This skill does not care *why*. The caller (`factory-create`, or the user) gives the starting prompt.

```
/spin-up-worktree <branch> [prompt]
```

## Two tools, one app

The Herdr app (macOS) has two command-line tools. Use only these two:

| Tool | Job here |
|---|---|
| `herdr-app` (`~/.local/bin/herdr-app`) | Changes what the user sees: makes the space and tab, puts the focus back. |
| `hc` (`~/.local/bin/hc`) | Talks to the terminals: waits for the session, reads its screen. |

Never use the old `herdr` command (`/opt/homebrew/bin/herdr`). It talks to an old background server that the app does not show, so a session started with it is invisible to the user.

## Always talk to the user's own window

`herdr-app` finds its window through `HERDR_APP_HOME` (default `~/.config/herdr-app`, socket `herdr-app.sock`), and `hc` finds its core through `HC_SESSION` and `HC_TERMINAL_SOCKET`. A session that did not start inside the Herdr app (another Claude Code window, an IDE, a background agent) can carry other values, or values from an old session. Then the space opens in a window the user does not see, or the check reads another core.

So never call `herdr-app` or `hc` bare. Start every Bash block that uses them with these two functions, and use `ha` and `hcx` in their place:

```bash
ha()  { env -u HC_SESSION -u HC_TERMINAL_SOCKET HERDR_APP_HOME="$HOME/.config/herdr-app" herdr-app "$@"; }
hcx() { env -u HC_SESSION -u HC_TERMINAL_SOCKET hc "$@"; }
```

The commands below and in REFERENCE.md are written as `herdr-app` and `hc`; run them as `ha` and `hcx`. `herdr-app: no Herdr window at …` means the app is not open: stop and say so.

## Run it in the background

When the user runs this skill directly, do not do the steps in this session. Hand them to a background agent, so the user can keep working here:

- Agent tool, `subagent_type: general-purpose`, `model: sonnet`, `description: spin up <ID or branch>`.
- Prompt: "Read and follow `~/.claude/skills/spin-up-worktree/SKILL.md` (`~` is the home folder), from *Ticket* on, with these inputs: <inputs>. The current repo is `<repo path>`. You cannot ask the user anything. Where the skill says to ask, stop and report the question instead."
- Tell the user in one line: "Spinning up `<ID>` in the background. I'll tell you when the space is up."
- When it finishes, relay its result: the outputs, or exactly what stopped it. If it stopped on a question, ask the user, then start it again with the answer as an input.

When `factory-create` calls this skill, do the steps in place. That session has nothing else to do.

## Before you start

- The Herdr app must be running: `ha status` prints JSON with a `space`. It fails: say "the Herdr app is not open" and stop. Do not open it yourself (bare `herdr-app` opens the window).
- The window and the core must be the same pair: every terminal that `ha ls` shows must also be in `hcx ls`. One is missing: the window and the core do not match. Stop and tell the user what each one showed.
- Run git from inside the target repo. Not clear which repo: ask.
- Paths can have spaces (`Company profile agents`). Quote every path.
- When unsure about a command, run `hc <command> --help`, `herdr-app commands`, or `hc --skill` / `herdr-app --skill`. See [REFERENCE.md](REFERENCE.md).

## Inputs

- `branch`: lowercase kebab-case, no slashes. Required.
- `label`: the space name, `<LINEAR-ID> <Short Title>`, e.g. `CPE-1619 Bulk Company Export`. Not given: take the Linear id from the branch or request, fetch the issue (`mcp__linear__get_issue`), and shorten its title to 2–3 words. No ticket: a 2–3 word summary of the task.
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

Return `space_id`, `tab_id`, `terminal` (the hc address, e.g. `t5`), `worktree_path`, `branch`, `model`, and "new" or "reopened". The caller tells the user. You only talk to the user about problems.

## Rules

1. **Start Claude Code in the repo's main checkout, never in the worktree.** Claude Code ties trust and permissions to the folder it starts in. A new worktree is not trusted yet, so starting there shows a trust dialog. The main checkout is trusted, because the user already works there.
2. **A launch reply is not proof.** `herdr-app do space.new` says the terminal was made, not that Claude Code read the task. Always do the check in step 6.
3. **Target by address.** Once you have the terminal address (`t5`), use it for every `hc` command. Never target by name or label.
4. **Ask, don't guess.** Never reuse, rename or recreate a branch, worktree or space without asking when it is not clear.
5. **Never answer a dialog yourself** (trust, permission, login). Read the screen and tell the user.

## Steps

### 0. Note the user's focus

Every Bash block from here on starts with the `ha` and `hcx` functions (*Always talk to the user's own window*).

```bash
ha status
```
Note `space` as `<original_space_id>`.

### 1. Is there a live session for this branch?

```bash
ha ls
hcx ls
```
A space named `<label>` with a live `claude-code` terminal:
- One → it is already running. Ask before you send it anything. To give it the prompt, go to step 6 with that terminal's address.
- More than one → ask which one.
- None → step 2.

### 2. Does the branch or worktree exist?

```bash
repo_root=$(git rev-parse --path-format=absolute --git-common-dir | sed 's|/\.git$||')   # the main checkout, also from inside a worktree
worktree_path="${repo_root}.worktrees/<branch>"
git show-ref --verify --quiet "refs/heads/<branch>"
git worktree list --porcelain
```
- No branch → create (step 3).
- Branch, but no worktree folder → ask: "Use the existing branch `<branch>`" (recommended), "Make a new branch", or custom.
- Branch and folder → reopen: skip step 3.

### 3. Create the worktree

```bash
git -C "$repo_root" fetch origin "<base_ref>" --quiet
git -C "$repo_root" worktree add -b "<branch>" "$worktree_path" "<base_ref>"
```
Existing branch without a folder: `git -C "$repo_root" worktree add "$worktree_path" "<branch>"`.

### 4. Install dependencies

Run it in the worktree, from this session, in every folder that has a lockfile: the root and each package folder (`find "$worktree_path" -maxdepth 3 \( -name package-lock.json -o -name pnpm-lock.yaml -o -name uv.lock \) -not -path '*/node_modules/*'`). A repo can have both: a root package for repo-wide tools (a linter the code review reads from the root) and its own packages below it. Per folder:

| File | Command |
|---|---|
| `uv.lock` | `uv sync --frozen` |
| `pyproject.toml` without `uv.lock` | `uv sync` |
| `pnpm-lock.yaml` | `pnpm install --frozen-lockfile` |
| `package-lock.json` | `npm ci` |

These install exactly what the lockfile says and leave it untouched. One fails because the lockfile is out of date: run the plain install (`uv sync`, `pnpm install`, `npm install`) in that folder instead, and name the folder in the output.

Then check that the install changed no tracked file: `git -C "$worktree_path" status --short`. A changed lockfile: `git -C "$worktree_path" checkout -- <file>`, so the build starts clean.

Run it on a reopen too: `.venv` and `node_modules` are per worktree. Skip it when `install_deps: no`.

### 5. Open the space and start Claude Code

Make a nonce of 6 hex characters. The task is this text, with the caller's prompt at the end:

> **First, run `cd "<worktree_path>" && pwd`. Then reply with one line: `cwd-confirmed <nonce>: <the path pwd printed>`.** After that, run every git, file and shell command inside `<worktree_path>`. If the path is not `<worktree_path>`, stop and report it. Do not use another folder.
>
> Then: `<starting_prompt>`

Pass the arguments as one JSON object, built with a JSON tool, so quotes and newlines in the prompt cannot break it:

```bash
ha do space.new "$(python3 -c 'import json,sys; print(json.dumps({"name": sys.argv[1], "folder": sys.argv[2], "tab": "agent", "argv": ["claude", "--model", sys.argv[3]], "task": sys.argv[4]}))' "<label>" "$repo_root" "<model>" "$task")"
```

- `folder` is the main checkout (rule 1), not the worktree.
- The reply is `{ "space": ..., "tab": ..., "terminal": "t5" }`. Read the ids from it. Do not predict them. `{ "error": ... }`: tell the user exactly what it said and stop.
- Reopen with a live space (step 1): send the task with `hcx send <terminal> "<task>"` instead.

### 6. Check the prompt landed

```bash
hcx wait <terminal> --timeout 120
```

`hcx wait` returns when the session stops working. A `timeout` reason is a check-in, not a failure: read the screen, and wait again if it is still busy. Status `blocked` (a trust or permission dialog): read the screen, tell the user, stop.

Look for the session's own reply, not the prompt: a long prompt scrolls off the top of the screen, the reply sits below it. The screen wraps long lines, so join the text before you search it:

```bash
hcx read <terminal> --lines 2000 | tr -d '\n ' | grep -oE "cwd-confirmed<nonce>:<worktree_path without spaces>"
```

It must print one match. The nonce proves the session read this task; the path proves it is in the worktree. (The prompt itself holds `<the path pwd printed>` in that place, so it never matches.)

No match: stop. Do not report success. Say what is missing. The user can open the space and paste the prompt. Never send the task a second time without reading the screen first: it may have arrived.

Check the model too: the status line at the bottom of `hcx read <terminal> --lines 0` shows it. A wrong model: tell the user.

Then check the space is in the user's window: `ha ls` must list a space with the id from step 5, named `<label>`, with terminal `<terminal>` in it. Not there: the space opened in another window. Stop and say so; do not open a second one.

### 7. Give back focus and report

`ha status` shows another `space` than `<original_space_id>`? Run `ha do space.select --id <original_space_id>`. Then return the outputs.
