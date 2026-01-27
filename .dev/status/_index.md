---
type: index
updated: 2026-01-27
---

# Status Index

> Point-in-time project status snapshots. Use for tracking progress and project health.

---

## Current Status

**Phase**:
**Last Updated**:

### Summary

### Active Work (Awaiting Human Action)

### Code Work Pending

### Completed (Beta)

---

## Status Reports

| Date | Phase | Highlights |
|------|-------|------------|

---

## Creating Status Reports

Status reports should be created:
- Weekly during active development
- At phase transitions (MVP → Beta → Release)
- When major blockers arise or resolve

**Format:** `STATUS-YYYY-MM-DD.md`

**Template:**
```markdown
---
type: status
date: YYYY-MM-DD
phase: beta
author: design-lead
---

# Status Report: YYYY-MM-DD

## Summary
Brief overview of project state.

## Completed Since Last Report
- Item 1
- Item 2

## In Progress
- Item with context

## Blocked
- Blocker with impact

## Next Steps
- Upcoming priorities

## Metrics (Optional)
- Tests passing: X/Y
- Code coverage: X%
- Open issues: X
```
