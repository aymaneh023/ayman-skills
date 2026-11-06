---
name: ayman-pr-file-comment
description: Draft the short "what happened here and why" comments Ayman El Hattache posts on individual files in the Files Changed tab of his own PR, in his own voice. Use when he wants a per-file explanation comment for one or more changed files (not the whole PR body, and not a review of someone else's PR), e.g. "draft me a comment for agent_loop.py explaining what happened", or when he's about to post file-level comments on his own PR and asks for a draft per file.
---

# Ayman's PR file comments

A short comment Ayman posts on one specific file in his own PR's Files Changed tab, so a
reviewer scrolling through the diff gets a plain explanation of what changed in that file and
why, without having to reconstruct it from the code alone.

This is a third sibling alongside [[pr-message]] (the whole-PR title and body) and
[[ayman-pr-review]] (reviewing someone else's PR). Read [[ayman-tone]] first for the base voice.
This skill is narrower than both of those: one file, one short paragraph, author explaining his
own change to a colleague, not a full PR narrative and not a review verdict on someone else's
work.

## Shape

Natural prose, no bold labels, no "What happened:" / "Why:" headers. One short paragraph per
file, normally two sentences:

1. **Name the actual thing that changed** — the function, class, or override, by its real name
   — and say plainly what it does. Not "refactored the logic" or "updated the helper", the
   literal symbol and its behavior.
2. **Say why**, in the same paragraph, flowing straight out of sentence 1 rather than announced
   as a separate section. The why is the problem this solves or the constraint it works within,
   not a restatement of what the code does.

> "Created a function `_last_call_token_buckets` which reads the last raw Anthropic call's own
> token usage off `agent.client`, and the guard now compares that against the threshold instead
> of the turn's summed usage. Needed this because a tool-calling turn is actually two Anthropic
> calls, and the framework sums both into the one response this loop sees, so the old comparison
> ran at almost double the real number and fired at about half the intended depth."

> "Added an override `_process_message` which grabs each raw call's usage right after it returns
> and stores it as `last_call_token_buckets` on the client. Needed this to have somewhere to
> read a single call's real usage from before the framework sums it with the next call in the
> turn, and it follows the same override pattern `_prepare_options` already uses here, so no
> vendored file gets touched."

Internal register throughout (see [[ayman-tone]]'s internal-register section): first person,
contractions, bare jargon assumed, dry and direct. Not addressed to "you" the way
[[ayman-pr-review]] is — this isn't reviewing someone else's work, it's Ayman explaining his own,
so "I did X, needed this because Y" rather than "you should know X".

## Process

1. Read the diff for that specific file (`git diff` / `gh pr diff <number> -- <path>`), not the
   whole PR, so the comment is anchored to what that file actually contains.
2. Identify the one or two symbols that carry the change, if the file touches several, pick the
   ones a reviewer would actually stop and ask about, not every renamed variable.
3. Write the paragraph: name the symbol, say what it does, say why, in that order, in natural
   sentences.
4. One paragraph per file. If a file's change genuinely needs more than ~3 sentences to explain,
   that is itself worth flagging back to the user rather than padding, it may mean the file is
   doing more than one thing.

## Rules

- No em dashes, comma or period instead, same as every other Ayman artifact.
- No bold section labels inside the comment itself. The two-part shape (what, then why) is
  structural, not typographic, it should read as one natural paragraph.
- Name real symbols (`_last_call_token_buckets`, `_process_message`), never "the relevant
  function" or "this logic".
- Don't restate the PR's overall why here, that already lives in the PR body via [[pr-message]].
  This comment's why is scoped to this one file's change.
- Don't editorialize about quality ("nice clean refactor") — that's review language for someone
  else's PR, not what an author says about his own file.

## Before posting

1. Does it name the actual symbol changed, not a vague description of "the code"?
2. Is the why in the same flowing paragraph, not split into a separate labelled section?
3. Any em dashes or bold "What/Why" headers? Remove them, prose only.
4. Would a reviewer who can already read the diff learn something from this, or does it just
   narrate what's visibly in front of them?
