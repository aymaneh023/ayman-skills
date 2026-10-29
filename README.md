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

Clone to `~/dev/ayman-skills`, then link every skill into Claude Code, Codex and Copilot CLI:

```powershell
.\install.ps1      # Windows
```

```bash
./install.sh       # macOS
```

Run it again after you add a skill. It skips links that exist.

Also needed on each machine: the SuperMatt plugin, herdr, and the Linear MCP. In each project repo, run `/supermatt:setup-supermatt-skills` once.
