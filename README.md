# ayman-skills

Personal skills for one way of working: plan in the main session, build in herdr worktrees. Works with Claude Code, Codex and Copilot CLI.

## Way of working

1. **Plan.** `/define-work <Linear project>`: grill → spec → tickets → refine the tickets you pick. Big tickets stay `needs-triage` and get refined later with `/define-work <ticket>`.
2. **Build.** `/spin-up <ticket> [tool]`: one herdr space per ticket. The agent runs `/implement` from start to finish without asking. It does not run paid calls, deploy or merge.
3. **Review.** The agent reports "Done / For the user / Assumptions" in its space and on the ticket, and moves the ticket to In Review. The user runs the paid checks and merges.

## Skills

| Skill | Status |
|---|---|
| `define-work` | draft |
| `spin-up` | to do |

## Install

Each skill folder is linked into each tool's skill folder (a Windows junction). Example for Claude Code:

```powershell
New-Item -ItemType Junction -Path "$HOME\.claude\skills\define-work" -Target "$HOME\dev\ayman-skills\skills\define-work"
```
