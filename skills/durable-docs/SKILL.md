---
name: durable-docs
description: Check a durable document (ARCHITECTURE.md, AGENTS.md, CLAUDE.md, CONTEXT.md, ADRs, docs/architecture, docs/facts, a README, or code comments and docstrings in files that ship) for content that will not last, and propose fixes. It finds plans, timelines, order of work, ticket and session references, meeting dates, to-dos for the user, person-dependent rules, "later we will" plans, overstated status, decisions that conflict with an ADR, and detail that belongs in a linked file. Use it whenever the user says "durable", "is this durable", "clean up the docs", "check ARCHITECTURE.md", "is this doc still up to date", "outdated docs", "progressive disclosure", or asks to review docs before a commit, and also before you yourself write meeting input or session results into one of these files.
---

# Durable docs

A durable document says what is true about the system and why. It stays true when the plan, the week, the ticket or the person changes. Agents and colleagues read these files at the start of each session, so each stale line costs every future reader time and can send them the wrong way.

The plan, tickets and session notes have their own place (for example `.scratch/`). Content that does not last goes there, or nowhere.

## Steps

1. **Find the rules of the repo.** Read `AGENTS.md` / `CLAUDE.md` for what each file is for (for example "ARCHITECTURE.md: durable architecture, no plans or tickets"). Read `CONTEXT.md` or a glossary if there is one, for the correct terms and the `_Avoid_` words. List the ADRs (`docs/adr/`). The repo rules come before the general rules below.
2. **Read the target file completely.** If the user names no file, take the durable files that changed (`git status` / `git diff`), or ask which file.
3. **Check each part against the checks below.** For a decision or a status, compare with the ADR or the detail file that it links to. Do not guess that a line is outdated: show the source that says otherwise.
4. **Report** (format below). Do not edit yet.
5. **Ask what only the user knows.** Before you edit, ask about each point that you cannot fix from a source, for example a missing status label or a possible conflict. Give enough context for each question: what the line says, what the sources say, and the possible answers. Use the repo's status labels as the options. Read the answer literally: "it is an option" means the label Option, not Accepted.
6. **Edit only what the user accepts.** Keep the edit small.
   - Before you delete a reason, an option that was not selected, or evidence from an overview file, check that the linked detail file already has it. If it does not, move it there first. Delete only the story around it (who, when, which ticket), not the content.
   - Fix the links that point to a heading that you renamed (search the repo for the old anchor).
   - Move content to the plan or a ticket only if the user says so.
7. **Close.** Search the file again for the signs (ticket, a year such as 2026, "the user", "later", "pilot", names) and report only what is left on purpose, with the reason. If linked detail files have the same problems, say so in one line. Do not fix them without a request.

## Checks

| # | Problem | Signs | Usual fix |
|---|---|---|---|
| 1 | Plan or timeline | week plans, "next sprint", dates of a next output, "first X, then Y" (order of work), "pilot in October" | Delete. It belongs in the plan, if anywhere. |
| 2 | Ticket or session reference | "(ticket 03)", "VAS-23", Linear/Jira links, "in this session", "as discussed today", heading with a date | Delete the reference; keep the content if it is durable. A link to an ADR or a facts file is fine. |
| 3 | Meeting log | "on 2026-10-08 the architect said…", who said what and when | Keep the result as a decision or a fact with a status. Drop the story. Dates stay only in facts (when a query ran) and in ADRs (when a decision was made). |
| 4 | To-do for the user or a team | "check with X", "give the data team Y", "Ayman to confirm" | Delete. The user decides what to do. An open question can stay as an open question, without an owner. |
| 5 | Person-dependent rule | "on failure, tell Ayman", a name as the owner of a process | Name a role or a mechanism ("the on-call engineer", "an alert to the team channel"). People leave. |
| 6 | "Later" plan | "V1 now, V2 later", "later the data team's model becomes the source", migration plans | Delete, or state the design as complete. A real uncertainty that a test must answer stays, marked Open. |
| 7 | Overstated or understated status | "Accepted" for a point that was only proposed; a new table or view recorded as accepted after a general "ok" | Use the status that matches what was agreed. Use the repo's labels (for example Accepted / Accepted for now / Proposed, to test / Option / Open). If you cannot tell, ask; do not upgrade. |
| 8 | Conflict with an ADR or a newer decision | old names, removed components, a choice that an ADR replaced | Align with the ADR, or flag it if the ADR may be the outdated one. |
| 9 | Wrong term | a word from the `_Avoid_` list, an old name | Use the glossary term. |
| 10 | Wrong level of detail | an overview file with long tables, full reasoning, query output | Keep one line plus a link; the detail goes to the linked file (progressive disclosure). |
| 11 | Process note about this conversation | "my goal is to walk through the tickets", "Claude proposed…", tool names of the session | Delete. |
| 12 | Internal references in shipped files | an ADR number or a repo path inside a prompt, YAML or docstring that is deployed (for example to Foundry) | Delete from the shipped file. Keep the reason in the ADR. |
| 13 | Temporary fact in a comment | "currently returns 200", "we found out today", a workaround with no reason | State the stable fact and why, or delete. |

Not every date, name or link is a problem. A fact file with the date of its query, an ADR with its date, and a link to a durable file are all correct. Ask: "Is this line still true and useful when the plan changes and this person leaves?"

For an old file that is mostly stale, do not delete it on your own. Propose one of: update it, delete it, or move it to an archive with a first line such as `> Not up to date. Do not use as a source.`, so that agents skip it.

## Report

Keep it short. One table, worst problems first, then one question. Put findings of the same type in one row with all their line numbers, so that 40 small findings become about 15 rows.

An open question about the product that is about later scope ("Types of output, later") is a real open question, not a "later" plan. Keep it.

```
**<file>**: <N> findings

| Line | Check | Text (short) | Fix |
|---|---|---|---|
| 90 | 2 Ticket/date in heading | "## Happy flow (ticket 03, 2026-10-12)" | "## Happy flow" |
| 141 | 7 Status | "Polling: Accepted" — the ADR says Proposed, to test | "Proposed, to test" |

Apply all, or which numbers?
```

If the file is clean, say so in one line. Do not invent findings to fill the table.
