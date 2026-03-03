# Ranker — CLAUDE.md

> **Ecosystem:** RANKER (Password Recovery Pipeline)
> **Role:** Flagship — iOS memory excavation & seed ranking app
> **Flagship docs:** This repo. See `ECOSYSTEM.md` for the full UX redesign spec and pipeline overview.

## Quick Reference

| Item | Value |
|------|-------|
| Platform | iOS (SwiftUI) |
| Language | Swift |
| Database | SQLite via SQLite.swift (`db_full_words.sqlite3` + `associations_db.sqlite3`) |
| Min iOS | Check Ranker.xcodeproj |
| Branch | `master` (has unresolved merge conflicts) |

## Architecture

```
RankerApp (TabView)
├── Tab 1: WordSorterContentView → WordSorterViewModel → DatabaseManager
│   ├── CustomSlider (0-1 rank)
│   ├── ProgressView
│   ├── SearchView → SearchViewModel
│   └── ShareSheet
├── Tab 2: SearchView → AssociatedIdeasView → RecorderWidgetView
└── Tab 3: SettingsView → SettingsViewModel
```

**Two SQLite databases:**
- `db_full_words.sqlite3` — words table (id, word, rank, notable, reviewed)
- `associations_db.sqlite3` — word_associations + audio_recordings tables

## Critical Issues

1. **Merge conflict** in `DatabaseManager.swift` (lines 22-32) and `WordSorterContentView.swift` (lines 1-7): HEAD uses `Table("words")`, `feature/enhance-docs` uses `Table("fullwords")`. Must resolve before any DB work.
2. **90 dummy seed words** — needs replacement with real memory excavation data (see ECOSYSTEM.md Mode 1).
3. **Fake transcript** — RecorderWidgetView returns hardcoded text after 2s delay. Replace with iOS Speech framework.
4. **Simulator-only** — `fatalError()` prevents device builds.
5. **AssociatedIdeasView crashes** — file sharing/entitlement errors.

## Ecosystem Integration

- **Trigram Analyzer** (`~/WebstormProjects/trigram-analyzer/`): Scores candidate passwords against 27K trigram database. Ranker exports seeds → Trigram Analyzer scores them.
- **Maskgenerator** (`~/PycharmProjects/maskgenerator/`): Generates .hcmask files from ranked seeds. Priority tiers based on Ranker Elo scores.
- **Data flow:** Ranker → SQLite export → Trigram Analyzer → Maskgenerator → Hashcat

## Before Making Changes

1. Resolve the merge conflict first (decide: `words` vs `fullwords` table name)
2. Read `ECOSYSTEM.md` for the full UX redesign vision
3. Check `~/AI.md` Section 4 (RANKER ecosystem) for cross-project context
