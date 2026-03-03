# AGENT BRIEF: Ranker iOS — Memory Excavation Engine

> **Give this entire file to a Claude Code session working on Ranker.**
> Last updated: 2026-03-02

## You Are Working On

Ranker is an iOS SwiftUI app at `~/ios_code/ranker/`. It is the flagship of the RANKER ecosystem — a password recovery pipeline for an Ethereum genesis block presale wallet (~July 2014). The password is 12 years old and buried in memory. Your job is to transform this app from a broken slider-grid prototype into a genuine memory excavation tool.

Read these files first, in order:
1. `~/AI.md` — master project context (search for "RANKER" section)
2. `~/ios_code/ranker/ECOSYSTEM.md` — full UX redesign spec, database schemas, pipeline overview
3. `~/ios_code/ranker/CLAUDE.md` — project-specific architecture and known issues

## Current State — What You're Inheriting

The app is **not functional on master**. Two critical blockers:

### Merge Conflict (MUST FIX FIRST)
`DatabaseManager.swift` lines 22-32 and `WordSorterContentView.swift` lines 1-7 have unresolved `<<<<<<< HEAD` markers. HEAD uses `Table("words")`, `feature/enhance-docs` uses `Table("fullwords")`.

**Decision: use `fullwords`** — this is the name used in the bundled `db_full_words.sqlite3` and in the associations DB foreign key references. Resolve both conflicts, choosing the `feature/enhance-docs` side for table naming. Clean out all merge markers.

### 90 Dummy Seed Words
`populateInitialDataIfNeeded()` in `DatabaseManager.swift` (around line 281) inserts 90 fruits/herbs/Greek letters. This data is useless for password recovery. You will replace it with Mode 1 (Free Association Dump) infrastructure.

### Other Issues
- `fatalError()` somewhere in `RankerApp.swift` init that prevents device builds — remove it
- `RecorderWidgetView.swift` returns fake transcript (hardcoded text after 2s delay)
- `AssociatedIdeasView.swift` crashes on file sharing/entitlement errors
- `FileManager.swift` and `ExportSheet.swift` are empty stubs (comments only)

## Task Priority (Execute In Order)

### P0: Make It Build
1. Resolve merge conflicts in `DatabaseManager.swift` and `WordSorterContentView.swift` — use `fullwords` table name
2. Remove the `fatalError()` that blocks device builds
3. Verify the app compiles: `xcodebuild -scheme Ranker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
4. Commit: "Fix merge conflicts, resolve fullwords table name, remove fatalError"

### P1: Free Association Dump (Mode 1)
This is the foundation. Before ranking anything, capture raw memory.

**New table:**
```sql
CREATE TABLE memory_dumps (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    prompt     TEXT,
    content    TEXT,
    created_at TEXT
);
```

**New view: `MemoryDumpView.swift`**
- Shows one guided prompt at a time with a large multiline TextEditor
- Prompts (hardcoded list, shown sequentially):
  - "Type every password you can remember ever using — any era, any service"
  - "Words associated with 2014 for you — people, places, events, feelings"
  - "Names: pets, partners, family, friends, fictional characters you liked"
  - "Numbers that mean something: birthdays, addresses, PINs, jersey numbers"
  - "What computer/browser/OS did you use in 2014?"
  - "What were you excited about when you bought ETH?"
- "Next" button saves content to `memory_dumps` table and advances to next prompt
- "Skip" button advances without saving
- After all prompts: parse all saved content into individual words/phrases, insert each unique entry into `fullwords` table with `rank = 0.5, reviewed = false`
- This REPLACES the dummy seed data — delete the 90 fruit/herb entries from `populateInitialDataIfNeeded()`

**Tab bar change:** Add "Dump" tab as the FIRST tab (before Ranker). This is the entry point for new users.

### P2: Comparative Ranking — Elo System (Mode 2)
Replace the slider grid with paired comparisons.

**New table:**
```sql
CREATE TABLE elo_comparisons (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    word_a_id  INTEGER,
    word_b_id  INTEGER,
    winner_id  INTEGER,
    created_at TEXT
);
```

**Add column to fullwords:**
```sql
ALTER TABLE fullwords ADD COLUMN elo_score REAL DEFAULT 1200.0;
```

**New view: `EloRankingView.swift`**
- Shows two words side by side as large tappable cards
- Prompt above: "Which FEELS more like something you'd use as a password?"
- Tap one → record comparison → update both Elo scores → show next pair
- Elo algorithm: K-factor = 32, standard formula:
  ```
  expected_a = 1 / (1 + 10^((elo_b - elo_a) / 400))
  new_elo_a = elo_a + K * (result - expected_a)
  ```
  where result = 1.0 for winner, 0.0 for loser
- Pair selection: pick from words with fewest comparisons, prefer pairs with similar Elo scores (for faster convergence)
- Show progress: "12 comparisons done — top 5: [word1, word2, ...]"
- Replace the current "Ranker" tab content with this view

### P3: Pattern Template Ranking (Mode 3)
**New view: `PatternRankingView.swift`**

Show password structure patterns as a ranked list. Each pattern is a tappable card with an example:

```swift
let patterns = [
    ("word + number", "Dragon123"),
    ("Word + Special + Number", "Dragon!2014"),
    ("two words", "DragonFire"),
    ("all lowercase", "dragonfire"),
    ("ALLCAPS", "DRAGONFIRE"),
    ("l33tspeak", "Dr4g0nF1r3"),
    ("phrase", "iloveethereum"),
    ("word + year", "Dragon2014"),
    ("name + digits", "Joseph42"),
]
```

**New table:**
```sql
CREATE TABLE pattern_rankings (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern     TEXT,
    example     TEXT,
    confidence  REAL,
    created_at  TEXT
);
```

- User can drag-to-reorder patterns (most likely at top)
- Or use Elo-style pairwise: "Which pattern feels more like you?"
- Store confidence as position-derived score (top = 1.0, bottom = 0.0)
- Add as a section within Settings tab or as a 4th tab

### P4: Contextual Memory Priming (Mode 4)
**New view: `ContextPrimingView.swift`**

Shown before each ranking session as an interstitial:
- "The Ethereum presale was July 22 – Sep 2, 2014"
- "Bitcoin was ~$600 at the time"
- "You created this password on a web form at ethereum.org"
- "Take a moment: what browser were you using? What was your desktop wallpaper?"
- Optional: PHPickerViewController to browse Camera Roll photos from 2014 (filter by date)
- "Ready" button dismisses and opens EloRankingView

### P5: Voice Transcription (Mode 6 — Fix Existing)
Replace the fake transcript in `RecorderWidgetView.swift`:
- Import `Speech` framework
- Request `SFSpeechRecognizer` authorization
- After recording stops, run `SFSpeechURLRecognitionRequest` on the m4a file
- Set the transcript text from `result.bestTranscription.formattedString`
- Parse transcript into keywords → offer to add them to `fullwords` table
- Add `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription` to Info.plist

### P6: Association Chains (Mode 5)
**New table:**
```sql
CREATE TABLE association_chains (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    from_word   TEXT,
    to_word     TEXT,
    label       TEXT DEFAULT 'reminds me of',
    chain_id    TEXT,
    position    INTEGER,
    created_at  TEXT
);
```

**Upgrade `AssociatedIdeasView.swift`:**
- Instead of single text field, show a chain: word → linked word → linked word
- "Add link" button: type a word this reminds you of
- Each node tappable to branch a new chain
- Display as a vertical linked list (horizontal graph is future work)
- All chain words automatically added to `fullwords` if not already present

### P7: Export for Pipeline
Export a `ranker_export.json` file following the **canonical interchange format** defined in `ECOSYSTEM.md` (section "Canonical Interchange Format"). This is the contract between all three tools — follow it exactly.

- Query `fullwords` ordered by `elo_score DESC`
- Map Elo to priority: score > 1500 → priority 3, > 1200 → priority 2, else 1
- Include `pattern_rankings` in the `patterns` array
- Set `source` field from how the word entered the DB (free association, voice transcript, association chain, etc. — you'll need a `source` column on `fullwords` or derive from which table the word came from)
- Share via iOS share sheet (UIActivityViewController)
- File name: `ranker_export.json`

**Do NOT export as SQLite or plaintext.** JSON is the canonical interchange format so all three tools can read it without platform-specific SQLite libraries.

## What NOT To Do

- Do NOT add dummy/mock/fake data anywhere. All data comes from the user's memory.
- Do NOT use external APIs or cloud services for transcription — use on-device `Speech` framework only.
- Do NOT over-engineer the UI. SwiftUI defaults are fine. No custom design system needed.
- Do NOT change the SQLite.swift dependency or switch to Core Data/SwiftData. Stay with SQLite.swift.
- Do NOT delete existing git branches. Only work on `master`.
- Do NOT add third-party dependencies beyond what's already in the project.

## Verification Checklist

After each P-level task, verify:
- [ ] App compiles: `xcodebuild -scheme Ranker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
- [ ] No merge markers in any .swift file: `grep -r "<<<<<<" ~/ios_code/ranker/Ranker/`
- [ ] No `fatalError()` remaining (except in impossible code paths)
- [ ] New tables created on first launch (check `DatabaseManager`)
- [ ] Commit with descriptive message after each P-level

## Architecture Notes

- **DatabaseManager.swift** is the single persistence layer. All new tables go here.
- **ViewModels** follow the existing pattern: `@Published` properties, methods that call `DatabaseManager`, loaded in `onAppear`.
- **Tab structure** in `RankerApp.swift` — add new tabs here.
- **SQLite.swift** uses `Table()`, `Column()`, typed expressions. Match existing patterns in `DatabaseManager.swift`.
- Two database files: `db_full_words.sqlite3` (words) and `associations_db.sqlite3` (metadata). New tables can go in either — put word-related tables in the words DB, metadata in associations DB.

## Git Workflow

**WARNING:** Master has unresolved merge conflict markers in committed source files. The merge conflict resolution (P0) must happen on master, but all subsequent feature work should be on a branch.

1. **P0 only:** Fix merge conflicts directly on `master`, commit the resolution.
2. **P1 onwards:** Create a feature branch from the resolved master:
   ```bash
   git checkout -b feature/memory-excavation
   ```
3. Commit after each P-level task completes with descriptive messages.
4. When all work is done, push the feature branch:
   ```bash
   git push -u origin feature/memory-excavation
   ```
5. Do NOT force push. Default branch naming convention is `master` (not main).
6. The existing branches (`feature/enhance-docs`, `fourth_checkin`, `fifth_go`) should be left alone — they are the user's prior work.
