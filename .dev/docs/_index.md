---
type: index
updated: 2026-01-27
---

# Documentation Index

> Generated documentation for external consumption. This directory contains finalized, publishable artifacts.

---

## Purpose

The `docs/` directory holds documentation artifacts that are:
- Ready for external audiences (users, stakeholders, contributors)
- Generated or distilled from internal development documents
- Versioned alongside releases

**Note**: Internal development docs (research, decisions, work packages) live in their respective directories. This directory is for polished output only.

---

## Document Types

| Type | Naming | Purpose |
|------|--------|---------|
| User Guide | `guide-{topic}.md` | End-user documentation |
| API Reference | `api-{module}.md` | API documentation |
| Changelog | `CHANGELOG.md` | Release history |
| Contributing | `CONTRIBUTING.md` | Contributor guidelines |
| Architecture Overview | `architecture-overview.md` | Public architecture summary |

---

## Documentation Workflow

### Creating Documentation

1. **Source**: Draw from internal docs (`design/`, `work/`, research findings)
2. **Draft**: Create document in `docs/` with `status: draft`
3. **Review**: Design-lead or designated reviewer approves
4. **Publish**: Update status to `published`, tag with version

### Frontmatter

```yaml
---
type: documentation
status: draft          # draft | review | published
version: 1.0.0         # Semantic version
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: design-lead
audience: [users, developers, contributors]
---
```

---

## Published Documents

| Document | Version | Updated | Audience |
|----------|---------|---------|----------|
| *None published yet* | | | |

---

## Style Guidelines

### Tone
- Clear and concise
- Action-oriented (use imperatives: "Run the command", "Configure the setting")
- Avoid jargon; define technical terms on first use

### Structure
- Lead with purpose/outcome
- Use headings liberally for scannability
- Include code examples where applicable
- End sections with "Next steps" or cross-references

### Formatting
- Use fenced code blocks with language hints
- Tables for structured comparisons
- Blockquotes for important callouts
- Relative links to other docs in this directory

---

## Maintenance

- Review docs at each phase transition (MVP, Beta, Release)
- Archive outdated versions to `archive/docs/` if needed
- Keep changelog updated with each release
