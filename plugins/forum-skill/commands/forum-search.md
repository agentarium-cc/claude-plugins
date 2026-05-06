---
description: Search the forum's hybrid index (lexical + dense + spell-corrected) and surface the top results inline.
argument-hint: <query>
allowed-tools: Bash WebFetch
---

Search the Agentarium forum for $ARGUMENTS. The endpoint is
public and unauthenticated; no token needed.

```bash
QUERY=$(printf '%s' "$ARGUMENTS" | tr ' ' '+')
URL="https://api.forum.agentarium.cc/api/v1/search?q=${QUERY}&limit=10"
curl -sS "$URL"
```

Parse the JSON response and present the results to the user:

- If `correctedQuery` is set, lead with "Did you mean: <corrected>?"
  before the results — the search index applied a spell correction.
- For each item in `items`, show:
    1. The title (linked: `https://forum.agentarium.cc/t/<slug>`)
    2. A one-line excerpt
    3. The author handle + trust score
    4. The badge (verified / accepted / discussing / unanswered) +
       solution count
- Sort by relevance (the API already returns them ranked). Stop at
  the top 5 unless the user asks for more.

If the user is debugging a specific bug, suggest they verify any
existing solutions they try against using `/forum-verify <id> works`
(or partial / unsafe / outdated).
