#!/usr/bin/env bash
# macOS setup. Links own skills from skills/ into Claude Code, Codex and Copilot CLI,
# clones the vendor repos into ~/dev/vendor, and links the vendor skills in vendor-links.txt
# into Claude Code. Safe to run again: it skips links that exist and pulls nothing.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
vendor="$HOME/dev/vendor"

link() {  # link <target> <link path>
  if [ -e "$2" ] || [ -L "$2" ]; then
    # Leave a real folder alone; it is not ours to replace.
    [ -L "$2" ] || echo "skip $2 (exists, not a link)" >&2
    return
  fi
  ln -s "$1" "$2"
  echo "linked $2"
}

for skill in "$repo"/skills/*/; do
  name="$(basename "$skill")"
  for root in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.copilot/skills"; do
    mkdir -p "$root"
    link "${skill%/}" "$root/$name"
  done
done

mkdir -p "$vendor"
for pair in "mattpocock-skills https://github.com/mattpocock/skills.git" \
            "phassle-skills https://github.com/phassle/skills.git" \
            "phassle-multi-code-review https://github.com/phassle/multi-code-review.git"; do
  set -- $pair
  [ -d "$vendor/$1" ] || git clone "$2" "$vendor/$1"
done

mkdir -p "$HOME/.claude/skills"
while read -r name path; do
  [ -n "$name" ] || continue
  if [ ! -d "$vendor/$path" ]; then
    echo "missing $vendor/$path (vendor repo moved it?)" >&2
    continue
  fi
  link "$vendor/$path" "$HOME/.claude/skills/$name"
done < "$repo/vendor-links.txt"
