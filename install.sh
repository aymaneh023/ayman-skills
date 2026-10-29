#!/usr/bin/env bash
# Links every skill in skills/ into each tool's skill folder (symlinks).
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
for skill in "$repo"/skills/*/; do
  name="$(basename "$skill")"
  for root in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.copilot/skills"; do
    mkdir -p "$root"
    link="$root/$name"
    if [ -e "$link" ] || [ -L "$link" ]; then
      # Leave a real folder alone; it is not ours to replace.
      [ -L "$link" ] || echo "skip $link (exists, not a link)" >&2
      continue
    fi
    ln -s "${skill%/}" "$link"
    echo "linked $link"
  done
done
