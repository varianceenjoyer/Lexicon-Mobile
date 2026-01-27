---
type: index
updated: 2026-01-22
---

# Design Index

> Architecture, research, and design decisions. Primary reference for design-lead role.

---

## Quick Navigation

| Document | Purpose |
|----------|---------|
| [architecture.md](architecture.md) | System architecture (authoritative) |
| [roadmap.md](roadmap.md) | High-level phases and milestones |
| [research/](research/_index.md) | Technical research findings |
| [decisions/](decisions/_index.md) | Architecture Decision Records |

---

## Architecture

The authoritative system architecture document:
- **[architecture.md](architecture.md)** — Component design, interfaces, data flow

---

## Roadmap

High-level project phases and delivery strategy:
- **[roadmap.md](roadmap.md)** — MVP → Beta → Release phases

---

## Research

Technical research organized by category:

| Category | Prefix | Count |
|----------|--------|-------|


See [research/_index.md](research/_index.md) for full index.

---

## Decisions

Architecture Decision Records (ADRs) track significant technical decisions:

| ID | Decision | Status |
|----|----------|--------|


See [decisions/_index.md](decisions/_index.md) for ADR index.

---

## Document Relationships

```
architecture.md (authoritative)
       │
       ├──▶ roadmap.md (delivery phases)
       │
       ├──▶ research/*.md (technical findings)
       │         │
       │         └──▶ inform decisions
       │
       └──▶ decisions/*.md (ADRs)
                 │
                 └──▶ work packages in ../work/
```
