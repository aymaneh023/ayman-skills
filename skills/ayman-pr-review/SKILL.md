---
name: ayman-pr-review
description: Write GitHub PR / code review comments in Ayman El Hattache's own voice, addressed directly to the colleague reading them (second person, "you"), never by name. Use whenever drafting or posting a review comment, inline diff comment, or PR summary comment that Ayman will post as himself — especially when he says "comment on this PR", "review this PR", "leave a comment", or pastes a PR/diff and asks for a review. Builds on the base voice in `ayman-tone`; this skill is the code-review-specific shape of it. Default to this over a generic review-comment format any time the comment is going out under Ayman's own GitHub account.
---

# Ayman's PR review comments

This is the code-review-specific shape of [[ayman-tone]]. Same person, same honesty about
limits, but the artifact is a GitHub comment on a diff, not an email. Read `ayman-tone` first
for the base voice (no em dashes, lead with the conclusion, concrete numbers, hand over the
next move) — this file only adds what's specific to reviewing code.

## Who it's written to

Always second person, direct address, as if one specific colleague (e.g. Mauno) is reading it.
Never open with their name — a PR comment isn't an email, it doesn't get a greeting line. The
"direct to one person" framing is a register choice, not a literal addressee: it kills the
generic-broadcast tone ("for anyone reading this cold...", "reviewers should note...") and
replaces it with "you"/"we".

Assume that person has *some* context (they can read the diff) but not full background on why
the surrounding wave of work exists or what depends on this PR. Give them that in one or two
sentences, in plain terms, without over-explaining code they can already see in front of them.

## Shape

1. **Open with why this PR matters right now**, not a restatement of its title. If it's a base
   PR in a stack, say so and say what breaks downstream if it's wrong. If it's standalone, say
   what it's actually for in one line.

   > "Went through this one carefully since it's the base every other PR in the stack builds
   > on, so if something's off here it drags into all 7 that follow."

2. **One short paragraph of context**, only the part the reader wouldn't already have. Connect
   the change to the actual problem it exists to solve, not just what the code does.

   > "Quick context in case you haven't looked at this angle yet: every existing
   > `run_agent_loop` test mocks out the agent entirely, so a 'turn' is just one model call by
   > definition. That's exactly why nobody caught the accounting bug this whole DAT-4851 wave
   > is about, the tests literally can't see it."

3. **Verify, don't just relay the PR description.** State plainly that the claims were checked
   against the actual source, and name the specific files/functions traced. This is the
   review-comment version of "be honest about the limits of your own work" — except here it's
   flipped positive: he's telling the reader the confidence in the "looks good" *is* earned,
   with receipts.

   > "I didn't just take the PR body's word for it, went and checked against the actual
   > source:
   > - `tool_choice={"type": "none"}` on the second call is real vendored behaviour, traced it
   >   to `FunctionInvocationLayer` in `vendor/agent-framework-core/agent_framework/_tools.py`.
   > - `_get_freetext_client` / `_FREETEXT_INVOCATION_CONFIG` match what's actually in
   >   `core/agent_factory.py` today."

4. **State the verdict on the core idea in one line** before moving to gaps. Don't bury
   "this is fine" under a pile of nitpicks, and don't bury a real problem under praise either.

   > "So this harness is pinning real behaviour, not asserting against a guess of what we
   > think happens. Good foundation."

5. **Flag real gaps forward-looking, tied to what depends on this.** A gap only worth
   mentioning if it matters — say what it is, why it matters for what comes *next* (the next
   PR in the stack, the next caller, the next person who trusts this), and what closes it.
   Don't hedge it as "just a thought" if it's a real risk; don't dress it up as blocking if
   it isn't.

   > "One gap I want to flag now, before #35 (DAT-4863, context guard) builds on top of this:
   > `usage_block()` here already accepts `cache_read_tokens` / `cache_creation_tokens`, but
   > neither test passes non-zero values for those, only plain `input_tokens`/`output_tokens`
   > summation across the two calls is pinned. #35 is specifically about the context guard
   > reading Total context, and cache tokens are part of that total. So right now we're
   > assuming cache read/write sums across both raw calls the same way fresh input does, we
   > haven't actually proven it. Might be worth adding a third case for that in #35 rather
   > than carrying the assumption forward."

6. **Close plainly, no summary restatement.** Either "rest of it is solid, no other notes" or
   a concrete next action. Never end by repeating what the comment already said.

## Rules specific to review comments

- **No em dashes.** Same as every other Ayman artifact — comma, full stop, or colon instead.
- **No em dashes, again, because code reviewers reach for them constantly for parenthetical
  asides** ("the fix here (which touches three files) is..."). Rewrite as two sentences.
- **Name real files and symbols**, not "the relevant code" or "the logic in question". If a
  claim can be traced to a line, trace it and say where.
- **Don't praise generically.** "Looks good", "LGTM", "nice work" carry no information here.
  Either say specifically what was checked and that it held up, or say nothing positive at all
  and just move to substance.
- **A gap flagged for a *future* PR in a stack should name that PR/ticket explicitly**
  (`#35`, `DAT-4863`), not "later" or "down the line" — the reader needs to know exactly where
  to pick this back up.
- **Don't manufacture a gap to seem thorough.** If a PR is genuinely clean, say so in one line
  and stop. Padding a clean review with invented nitpicks is worse than a short review.
- Internal register throughout (see `ayman-tone`'s internal-register section): contractions,
  bare jargon, dry, no corporate throat-clearing, no hedged non-answers.

## Before posting

1. Did I actually check the claims in the PR body against source, or am I relaying them?
2. Is the verdict on the core idea stated in one clear line, separate from any gaps?
3. Is every gap tied to a concrete downstream consequence (a PR, a ticket, a caller), not
   vague risk-speak?
4. Any em dashes, "LGTM", "looks good", "great work", or "just a nit"? Remove or replace with
   something specific.
5. Does it read like it's talking to one person who'll actually act on it, not a broadcast to
   "reviewers"?
