---
name: review-loop
description: Step after a PR is opened, before the user reviews it. Gets the PR through the review bots (Copilot, and Codex when connected) - fix or accept the risk per comment - then has pr-message rewrite the body for the final code and pings the user. Use right after pr-message opens a PR, or when the user asks to handle the bot reviews on a PR.
---

# Review loop

The goal: when the user is pinged, every bot comment is fixed or decided, the checks are green, and the PR body describes the code as it is now. The user is the last reviewer.

This is a gate, not a loop to perfection. A bot always finds one more edge case, so a round never ends "clean". The question after each round is: **is this good enough to go forward?** Fix only what makes the answer no.

The checking is done by [review-status.sh](review-status.sh) in this folder: asking for reviews, waiting, listing comments, replying, watching checks. Run it as `bash ~/.claude/skills/review-loop/review-status.sh <command>` from the repo. Your own work is only the **decision** per comment and the fix.

You never merge, approve, force-push, or push to the base branch. You change only what a comment is about.

## 1. Start

- `gh pr view [<number>] --json number,url,headRefName,state`: the PR must be open, you must be on its head branch, and the working tree must be clean. Otherwise say so and stop.
- Read the repo's `AGENTS.md` / `CLAUDE.md`, `CODING_STANDARDS.md` if present, and the PR's ticket (linked in the body). The ticket is the scope; the standards are the bar.
- Commit messages for fixes follow the repo's convention (`git log --oneline -30`, for example `Copilot review: <fix>`).

## 2. One round

1. `review-status.sh request <pr>` prints `sha`, `since` and `reviewers`.
2. `review-status.sh wait <pr> <sha> <since> "<reviewers>"` with `run_in_background`. You are woken when it exits. Exit 3 means a reviewer did not answer in 20 minutes: go on with what is there.
3. `review-status.sh threads <pr>` prints every open bot thread and bot review summary as JSON lines.
4. **Gate first.** Read the review summary and the threads, and decide: good enough to go forward? Say the verdict in one line before you change anything.
   - A summary that says no open issues (Copilot: blue "Needs a closer look" with "No open issues") is good enough. Stop the loop.
   - A "changes recommended" summary (Copilot: yellow) can still be good enough when every item is **Accept risk** or **Not valid** under section 3.
   - Items in code the PR did not change ("previously missed issue") are **Accept risk** by default.
5. Decide each item (section 3), make the fixes, run the repo's tests and lint until they pass, commit and `git push`.
6. Answer each thread with a reply written to a temp file: `resolve <thread-id> <file>` for **Fix** and **Not valid**, `reply <thread-id> <file>` for **Accept risk** and **Ask** (those stay open for the user).

Repeat rounds until one of these is true:
- **Good enough**: the gate of step 4 says go forward.
- **Quiet**: the round has no new Fix.
- **Three rounds** are done.
- A bot raises again something you already decided: keep your decision; it goes to the user.
- Tests or checks stay red after two tries.

Then `review-status.sh checks <pr>`.

## 3. The decision per comment

For each comment, first state the **risk** in one sentence: what goes wrong, for whom, and how likely, if the code stays as it is. Then pick one:

| Decision | When | Reply on the thread |
|---|---|---|
| **Fix** | Only one of these, within the ticket: a wrong value (a number, sign, scale or duplicated value) on input we can expect; a crash or stall on input we can expect; a security or data-loss problem; a regression this PR introduced; a break of `CODING_STANDARDS.md`. Fix these even when the fix is not small. | What changed, and the commit SHA. |
| **Accept risk** | Everything else that is real: an edge case we do not expect to happen, a case that is missed but not wrong (the value stays out, it is not changed), an issue in code the PR did not change, a fix outside the ticket, or a fix that costs more than the risk. A cheap fix is not a reason to fix. | The risk, why it is acceptable now, and what would make it matter later. |
| **Not valid** | The comment is wrong, already handled, or conflicts with a repo rule or ADR. | Why, pointing at the code, rule or ADR. |
| **Ask** | It needs a product or design choice that the ticket does not settle. | Nothing yet; it goes to the user. |

Base each decision on the code you read, not on how the bot words the comment. A security or data-loss risk, or a wrong value on input we can expect, is never **Accept risk** on your own: make it **Fix** or **Ask**.

Accepted risks go into the PR body as one line each under Risk (section 4), so the user sees them before merging.

## 4. Rewrite the PR body

When a round made any Fix, load the `pr-message` skill with the Skill tool and update the existing PR's body, so it describes the final code: the behaviour as it is now, not the review history. Pass it the accepted risks and the Ask items. Accepted risks go under its Risk, as plain facts about the code, without saying a bot raised them. An Ask item makes its verdict "Merge: not yet".

Post the body without waiting for a yes: the user asked for it by starting the flow that opened the PR.

## 5. Hand over

Send a push notification (PushNotification tool): `PR #<n> ready for your review: <accepted> risks accepted, <ask> need you.` End your turn with the PR link, the accepted risks and the Ask items, one line each.
