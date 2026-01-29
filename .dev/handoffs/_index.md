---
type: index
updated: 2026-01-29
---

# Handoffs Index

> Agent-to-agent task transitions. Check here for work assigned to your role.

---

## Active Handoffs

| ID | Work Package | From | To | Priority | Status | Blocked By |
|----|--------------|------|-----|----------|--------|------------|
| (none) | All MVP handoffs complete | — | — | — | — | — |

---

## Implementation Order

```
┌────────────────────────────────────────────────────────────────────────┐
│                        IMPLEMENTATION PHASES                            │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PHASE 1: Foundation (Start Here)                                      │
│  ─────────────────────────────────                                     │
│  ► WP-SETUP ← START HERE (no blockers)                                 │
│                                                                         │
│  PHASE 2: Core Services (After WP-SETUP, can be parallel)              │
│  ────────────────────────────────────────────────────────              │
│    • WP-AUDIO — audio capture + playback services                      │
│    • WP-STATE — Riverpod providers and notifiers                       │
│    • WP-NAV   — GoRouter + bottom navigation                           │
│                                                                         │
│  PHASE 3: Views (After Phase 2 complete)                               │
│  ──────────────────────────────────────                                │
│    • WP-NOTE  — Note View (transcription + TTS)                        │
│    • WP-CHAT  — Chat View (diarized conversation)                      │
│    • WP-FILES — File Manager (browse, search, import)                  │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Dependency Summary

| Work Package | Depends On | Blocks |
|--------------|------------|--------|
| WP-SETUP | — | WP-AUDIO, WP-STATE, WP-NAV |
| WP-AUDIO | WP-SETUP | WP-NOTE, WP-CHAT |
| WP-STATE | WP-SETUP | WP-NOTE, WP-CHAT, WP-FILES |
| WP-NAV | WP-SETUP | WP-NOTE, WP-CHAT, WP-FILES |
| WP-NOTE | WP-AUDIO, WP-STATE, WP-NAV | — |
| WP-CHAT | WP-AUDIO, WP-STATE, WP-NAV | — |
| WP-FILES | WP-STATE, WP-NAV | — |

---

## Human-Blocked Work

| Handoff | Blocker | Action Required |
|---------|---------|-----------------|

Currently no human-blocked work.

---

## Completed Handoffs

| ID | Work Package | Completed | Notes |
|----|--------------|-----------|-------|
| [HO-2026-01-29-wp-setup](HO-2026-01-29-wp-setup-flutter-init.md) | WP-SETUP | 2026-01-29 | Flutter project structure |
| [HO-2026-01-29-wp-audio](HO-2026-01-29-wp-audio-services.md) | WP-AUDIO | 2026-01-29 | Audio services |
| [HO-2026-01-29-wp-state](HO-2026-01-29-wp-state-riverpod.md) | WP-STATE | 2026-01-29 | Riverpod providers |
| [HO-2026-01-29-wp-nav](HO-2026-01-29-wp-nav-router.md) | WP-NAV | 2026-01-29 | Navigation + shell |

---

## Handoff Workflow

1. **Sender** creates handoff document in `handoffs/`
2. **Sender** updates this index
3. **Recipient** reviews handoff, acknowledges receipt
4. **Recipient** begins work, updates work package status to `in-progress`
5. **Recipient** completes work, updates status to `complete`
6. **Sender/Recipient** archives completed handoff to `archive/handoffs/`

---

## Quick Reference

### Starting Implementation

1. Begin with **WP-SETUP** (no blockers)
2. After WP-SETUP, Phase 2 packages can run in parallel
3. Phase 3 views require all Phase 2 dependencies

### For Each Work Package

1. Read the handoff document for context
2. Read the full work package (`.dev/work/WP-*.md`) for details
3. Update work package status to `in-progress`
4. Implement per acceptance criteria
5. Update status to `complete` when done
6. Create handoff back if issues found

---

*Last updated: 2026-01-29*
