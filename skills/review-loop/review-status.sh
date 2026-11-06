#!/usr/bin/env bash
# review-status.sh: the deterministic half of /review-loop. No AI, only gh.
# Run from inside the repo. Every command prints plain text the agent can read.
#
#   request <pr>                          ask Copilot (and Codex when connected) to review the head commit
#   wait    <pr> <sha> <since> <reviewers> block until each reviewer is done with <sha> (max 20 min)
#   threads <pr>                          print open bot threads and bot review summaries, as JSON lines
#   reply   <thread-id> <body-file>       reply on a thread, leave it open
#   resolve <thread-id> <body-file>       reply on a thread and resolve it
#   checks  <pr>                          block until the PR checks settle, print the result
set -euo pipefail

usage() { sed -n '4,10p' "$0"; exit 2; }
[ $# -ge 2 ] || usage
cmd="$1"; shift

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
owner="${repo%/*}"; name="${repo#*/}"
bots='copilot|codex'

# Login of the Codex bot when it has reviewed one of the last 10 PRs here; empty otherwise.
codex_login() {
  local n l
  for n in $(gh pr list --state all --limit 10 --json number -q '.[].number'); do
    l="$(gh api "repos/$repo/pulls/$n/reviews" --jq '[.[].user.login | select(test("codex"))][0] // empty')"
    [ -n "$l" ] && { echo "$l"; return; }
  done
}

# Number of reviews by a login matching $2 on commit $3 of PR $1.
reviews_on() {
  gh api "repos/$repo/pulls/$1/reviews" --paginate \
    --jq "[.[] | select((.user.login | test(\"$2\")) and .commit_id == \"$3\")] | length"
}

case "$cmd" in
  request)
    pr="$1"
    sha="$(gh pr view "$pr" --json headRefOid -q .headRefOid)"
    since="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    reviewers="copilot"
    # Copilot often reviews a new push by itself; ask only when it has not reviewed this commit yet.
    [ "$(reviews_on "$pr" copilot "$sha")" -gt 0 ] || gh pr edit "$pr" --add-reviewer @copilot >/dev/null
    if [ -n "$(codex_login)" ]; then
      reviewers="copilot codex"
      [ "$(reviews_on "$pr" codex "$sha")" -gt 0 ] || gh pr comment "$pr" --body "@codex review" >/dev/null
    fi
    echo "sha=$sha since=$since reviewers=\"$reviewers\""
    ;;

  wait)
    [ $# -eq 4 ] || usage
    pr="$1"; sha="$2"; since="$3"; reviewers="$4"
    deadline=$(( $(date +%s) + 20 * 60 ))
    while :; do
      pending=""
      for r in $reviewers; do
        done_n="$(reviews_on "$pr" "$r" "$sha")"
        if [ "$done_n" -eq 0 ] && [ "$r" = codex ]; then
          # Codex reacts with a thumbs-up on the PR when it has nothing to say.
          done_n="$(gh api "repos/$repo/issues/$pr/reactions" \
            --jq "[.[] | select((.user.login | test(\"codex\")) and .content == \"+1\" and .created_at >= \"$since\")] | length")"
        fi
        [ "$done_n" -gt 0 ] || pending="$pending $r"
      done
      [ -z "$pending" ] && { echo "done: $reviewers reviewed $sha"; exit 0; }
      [ "$(date +%s)" -lt "$deadline" ] || { echo "timeout: did not answer:$pending"; exit 3; }
      sleep 60
    done
    ;;

  threads)
    pr="$1"
    sha="$(gh pr view "$pr" --json headRefOid -q .headRefOid)"
    gh api graphql -F owner="$owner" -F name="$name" -F pr="$pr" -f query='
      query($owner:String!, $name:String!, $pr:Int!) {
        repository(owner:$owner, name:$name) { pullRequest(number:$pr) {
          reviewThreads(first:100) { nodes { id isResolved isOutdated path line
            comments(first:20) { nodes { author { login } body url } } } } } } }' \
      --jq ".data.repository.pullRequest.reviewThreads.nodes[]
            | select(.isResolved | not)
            | select(.comments.nodes[0].author.login | test(\"$bots\"))
            | {kind: \"thread\", id, path, line, outdated: .isOutdated,
               author: .comments.nodes[0].author.login, url: .comments.nodes[0].url,
               comment: .comments.nodes[0].body,
               replies: [.comments.nodes[1:][] | {author: .author.login, body}]}"
    gh api "repos/$repo/pulls/$pr/reviews" --paginate \
      --jq ".[] | select((.user.login | test(\"$bots\")) and .commit_id == \"$sha\" and (.body | length) > 0)
            | {kind: \"summary\", author: .user.login, url: .html_url, body}"
    ;;

  reply|resolve)
    [ $# -eq 2 ] || usage
    thread="$1"; body_file="$2"
    gh api graphql -F thread="$thread" -F body=@"$body_file" -f query='
      mutation($thread:ID!, $body:String!) {
        addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$thread, body:$body}) { comment { url } } }' \
      --jq '.data.addPullRequestReviewThreadReply.comment.url'
    if [ "$cmd" = resolve ]; then
      gh api graphql -F thread="$thread" -f query='
        mutation($thread:ID!) { resolveReviewThread(input:{threadId:$thread}) { thread { isResolved } } }' \
        --jq '"resolved: \(.data.resolveReviewThread.thread.isResolved)"'
    fi
    ;;

  checks)
    pr="$1"
    if gh pr checks "$pr" --watch --interval 30 >/dev/null 2>&1; then
      echo "checks: green"
    else
      gh pr checks "$pr" 2>&1 | grep -v -E '\bpass\b' || echo "checks: none reported"
      exit 1
    fi
    ;;

  *) usage ;;
esac
