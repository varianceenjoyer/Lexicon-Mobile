---
type: index
updated: YYYY-MM-DD
---

# Architecture Decisions Index

> Architecture Decision Records (ADRs) document significant technical decisions.

---

## Active Decisions

| ID | Title | Status | Date |
|----|-------|--------|------|

---

## ADR Template

Create new ADRs using this template:

```markdown
---
id: ADR-NNN
type: decision
status: accepted  # proposed | accepted | deprecated | superseded
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: design-lead
supersedes: []     # List of ADR IDs this replaces
superseded-by: []  # ADR ID that replaces this
tags: []
---

# ADR-NNN: Title

## Status
Accepted

## Context
What is the issue that we're seeing that is motivating this decision?

## Decision
What is the change that we're proposing and/or doing?

## Consequences
What becomes easier or more difficult because of this change?

## Alternatives Considered
What other options were evaluated?
```

---

## Decision Lifecycle

1. **Proposed** — Under discussion, not yet accepted
2. **Accepted** — Decision made and in effect
3. **Deprecated** — No longer recommended but still in use
4. **Superseded** — Replaced by a newer decision
