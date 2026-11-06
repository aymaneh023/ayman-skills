# ayman-skills

My own skills for one way of working, plus the list of Matt Pocock and Per Hassle skills I use with them. The Windows work laptop is the source: skills are edited in `~/.claude/skills/` there and copied here to bring them to the Mac.

## Way of working

1. **Plan.** `/define-work <Linear project or ticket>`: grill, spec, scenarios, split into tickets, refine. Writes only to Linear.
2. **Build.** `/factory-create <project or ticket>` makes a worktree and herdr pane (`spin-up-worktree`) and starts `factory-start` there. Each ticket gets a builder agent with `/tdd`, then lint, multi-code-review and the Done check, and a `## Build notes` comment on the ticket.
3. **PR.** `pr-message` writes the PR: a "Merge: yes / not yet" verdict, a status table, why, a problem-to-fix table with a diagram, real before/after examples, risk, spec gaps, scope and where to review.
4. **Bot review.** `review-loop` gets the PR through Copilot and Codex, fixes or accepts each comment, has `pr-message` rewrite the body and pings me.
5. **Me.** I review last and merge. `/retro` after a build.

## Skills

| Skill | What |
|---|---|
| `define-work` | Plan a Linear project or ticket until its tickets are ready for an agent |
| `factory-create` | Start the build of one project or parent ticket in a new worktree |
| `factory-start` | Build every ready ticket, check and merge each one |
| `spin-up-worktree` | Worktree + herdr pane + fresh Claude Code session with a prompt |
| `pr-message` | PR title and body in my voice |
| `review-loop` | Copilot/Codex review round after a PR opens |
| `ayman-pr-review` | Review comments on someone else's PR, in my voice |
| `ayman-pr-file-comment` | Per-file comments on my own PR |
| `durable-docs` | Check durable docs for content that won't last |

`ayman-tone` is not here: it comes with the claude.ai account.

## Install on the Mac

```bash
git clone https://github.com/aymaneh023/ayman-skills.git ~/dev/ayman-skills
~/dev/ayman-skills/install.sh
```

It links my skills into Claude Code, Codex and Copilot CLI, clones `mattpocock/skills`, `phassle/skills` and `phassle/multi-code-review` into `~/dev/vendor`, and links the vendor skills listed in `vendor-links.txt`. Run it again after a pull; it skips links that exist. Update the vendor clones by hand with `git pull` in each.

Also needed:
- herdr, with its Claude Code integration (it installs its own SessionStart hook).
- The Linear MCP in Claude Code.
- Docker running, then once: `cd ~/dev/vendor/phassle-multi-code-review && ./setup.sh`. The Windows-only `mcr-winpath` hook and the local gateway patch are not needed on macOS.
- Repos live under `~/dev`, and `~/dev` is a trusted folder in Claude Code (`spin-up-worktree` starts sessions there).

## Bringing changes over from Windows

Copy the changed skill folders from `~/.claude/skills/` into `skills/`, update `vendor-links.txt` if the vendor links changed, commit and push with the personal account (`gh auth switch -u aymaneh023`, then back to `aymaneh023-val`). On the Mac: `git pull` and `./install.sh`.
