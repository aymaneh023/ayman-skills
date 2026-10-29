# Tool differences

The skills work in Claude Code, Codex and Copilot CLI. Only the parts below differ. Change model names here when models change.

## Level → model

| Level | Claude Code | Codex | Copilot CLI |
|---|---|---|---|
| `light` | Haiku | to check | to check |
| `standard` | Sonnet | to check | to check |
| `heavy` | Opus | to check | to check |

## Asking the user

| Tool | Question tool |
|---|---|
| Claude Code | `AskUserQuestion` |
| Codex | `request_user_input` |
| Copilot CLI | to check |

If the tool has none, ask in the chat.

## Linear

All three use the Linear MCP server. Tool names differ per host (Claude Code: `mcp__linear__save_issue`). Use whatever Linear tools the host shows.
