# RANKER Ecosystem — Password Recovery Pipeline

> **Target:** Ethereum genesis block presale wallet (~July 2014). Hashcat mode 16300 (PBKDF2-SHA256, 2000 rounds, password=salt, AES-256-CBC).
>
> **Philosophy:** Memory excavation, not data entry. The password is buried in 12 years of accumulated memory. These tools are designed to dig it out through association, context, comparative judgment, and emotional priming — not by rating "banana" on a slider.

## Project Inventory

| Project | Path | Language | Role | Status |
|---------|------|----------|------|--------|
| **Ranker** (flagship) | `~/ios_code/ranker/` | Swift/SwiftUI | iOS memory excavation & seed ranking | Active — needs deep UX redesign |
| Trigram Analyzer | `~/WebstormProjects/trigram-analyzer/` | TypeScript/JS | Web candidate scoring & trigram visualization | Functional — needs iteration features |
| Maskgenerator | `~/PycharmProjects/maskgenerator/` | Python + Kotlin | Hashcat .hcmask generation | Functional — saveToFile bug, no CLI entry |

## Recovery Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HUMAN MEMORY EXCAVATION                          │
│                                                                     │
│  Free Association → Comparative Ranking → Pattern Templates         │
│  Context Priming  → Association Chains  → Voice Mnemonics           │
└──────────────┬──────────────────────────────────────────────────────┘
               │ Export ranked seeds (SQLite)
               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    TRIGRAM ANALYZER (Web)                            │
│                                                                     │
│  Score candidates → Compare side-by-side → Generate variations      │
│  Flag promising   → Track history        → Export to maskgen        │
└──────────────┬──────────────────────────────────────────────────────┘
               │ Priority-weighted seed files
               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    MASKGENERATOR (Kotlin/Python)                     │
│                                                                     │
│  Capitalization → Keystroke errors → Variable interleaving          │
│  Leetspeak      → Permutations    → Priority-tiered .hcmask output │
└──────────────┬──────────────────────────────────────────────────────┘
               │ .hcmask files (tiered by priority)
               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    HASHCAT EXECUTION                                 │
│                                                                     │
│  Mode 16300 → Split across machines → Session management            │
│  .pot aggregation → Attack tracking → Progress dashboard            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Deep UX Redesign Spec

### 1A. Ranker iOS — From Slider Grid to Memory Excavation Engine

#### Current State (What's Wrong)

- **Seeded with dummy data**: 90 random words (alpha, banana, cinnamon...) — nothing related to the actual password
- **Ranking is too abstract**: Sliding 20 random words on a 0-1 scale doesn't engage memory. Memory doesn't work by rating "banana" 0.3 on a slider
- **No memory priming**: No contextual prompts about 2014, no era-specific triggers
- **Association view is shallow**: Single text field + audio recording per word. No chaining, no graph
- **Merge conflicts**: HEAD vs `feature/enhance-docs` on table naming (`words` vs `fullwords`) in DatabaseManager.swift
- **Simulator-only**: `fatalError()` prevents running on real device
- **Transcript is fake**: Hardcoded 2-second delay returning dummy text

#### Redesigned Modes

**Mode 1: Free Association Dump**

Before ranking anything, capture raw memory. Multiple guided prompts:
- "Type every password you can remember ever using — any era, any service"
- "Words associated with 2014 for you — people, places, events, feelings"
- "Names: pets, partners, family, friends, fictional characters you liked"
- "Numbers that mean something: birthdays, addresses, PINs, jersey numbers"
- "What computer/browser/OS did you use in 2014?"
- "What were you excited about when you bought ETH?"

Each prompt has a large text area. Everything typed becomes seed corpus. This **replaces the 90 dummy words entirely**.

**Mode 2: Comparative Ranking (Elo-style)**

Instead of absolute 0-1 sliders, show PAIRS:
> "Which FEELS more like something you'd use as a password?"
> [Dragon] vs [Phoenix]

Tap one. Next pair. This is psychologically validated — comparative judgments are more reliable than absolute ratings. Use Elo algorithm to converge on rankings. 20 comparisons tells you more than 100 slider adjustments.

**Mode 3: Pattern Template Ranking**

Most passwords follow patterns. Rank the STRUCTURES:
- `word + number` (Dragon123)
- `Word + Special + Number` (Dragon!2014)
- `two words` (DragonFire)
- `all lowercase` (dragonfire)
- `ALLCAPS` (DRAGONFIRE)
- `l33tspeak` (Dr4g0nF1r3)
- `phrase` (iloveethereum)

The user rates which patterns feel RIGHT. This constrains mask generation enormously.

**Mode 4: Contextual Memory Priming**

Before each session, show context to trigger recall:
- "The Ethereum presale was July 22 – Sep 2, 2014"
- "Bitcoin was ~$600"
- "You would have created this password on a web form at ethereum.org"
- Optionally: show the user's own photos from that era (Camera Roll access by date range)
- "What browser were you using? What was your wallpaper?"

**Mode 5: Association Chains (Graph)**

The current single-text-field association view becomes a chain builder:
- "dragon" → reminds me of → "game of thrones" → reminds me of → "fire" → reminds me of → "2014"
- Build a visual web/graph of associations
- AI can analyze clusters and suggest promising candidates
- Tap any node to branch off a new chain

**Mode 6: Voice Mnemonic Sessions**

Keep audio recording but add REAL transcription (iOS Speech framework, not fake delay). Let the user talk freely about what they remember. Transcribe → extract keywords → feed into seed corpus.

#### Seed Corpus Strategy

- Delete the 90 dummy words entirely
- Replace with user's free association dumps + imported data
- Future: import from email archives, documents, browser history
- The 27,575 trigram corpus from trigram-analyzer serves as a background scoring layer, not as primary ranking targets

---

### 1B. Trigram Analyzer — From One-Shot to Password Lab

#### Current State (What's Wrong)

- **One-shot tool**: Paste text → see colors. No history, no comparison, no iteration
- **No candidate management**: Can't save, compare, or rank candidates
- **Disconnected**: Doesn't feed into Ranker or maskgenerator
- **No inverse mode**: Can't say "show me words that score like this"

#### Redesigned Features

**Candidate Workspace**
- Persistent list of candidate passwords (saved between sessions via localStorage or SQLite)
- Type a candidate → instant score breakdown with trigram visualization
- Star/flag promising candidates
- Add notes ("this feels 70% right but the number is wrong")

**Comparison Mode**
- Side-by-side scoring of two candidates
- "Dragon2014 vs DragonFire2014" — see which trigrams differ
- Highlight the divergent trigrams

**Variation Generator**
- Type a base word → auto-generate common variations:
  - Capitalizations: dragon, Dragon, DRAGON, dRAGON
  - Number suffixes: Dragon1, Dragon12, Dragon123, Dragon2014
  - Special char insertions: Dragon!, Dragon@2014, D!ragon
  - Leetspeak: Dr4g0n, Drag0n
- Score all variations simultaneously
- One-click export to maskgenerator as seeds

**History & Progress**
- What has been analyzed (don't repeat work)
- Export scored candidates to Ranker or maskgenerator
- Session log: "Explored 47 candidates, 12 flagged, 3 sent to maskgen"

---

### 1C. Maskgenerator — From Broken to Pipeline-Ready

#### Current State (What's Wrong)

- **saveToFile bug**: Overwrites `hellpcombos.hcmask` on each seed group iteration (only last group survives)
- **No CLI entry point**: All logic, no main() function
- **No ranking integration**: TODO comment mentions it but nothing built
- **No attack tracking**: No record of what's been tried
- **containsLower() bug**: Potential error when `?u` placeholder is involved (noted in comments)

#### Immediate Fixes

1. **saveToFile**: Accumulate all results across seed groups, write once at end (or append mode)
2. **CLI entry point**: Add `main()` with argument parsing (seed file, output file, depth level)
3. **containsLower()**: Fix `?u` placeholder handling

#### Ranking Integration

- Accept priority-weighted seed files (from Ranker export)
- High-ranked seeds: full permutation depth (all 6 stages — capitalization, capslock, keystroke errors, variable interleaving, permutations, filtering)
- Medium-ranked: reduced permutations (skip keystroke errors)
- Low-ranked: minimal (capitalization variants only)
- Output: priority-tiered `.hcmask` files (high/medium/low)

#### Attack Tracking (new module)

SQLite database tracking:
- Which `.hcmask` files have been generated
- Which have been run through hashcat
- On which machine
- Keyspace covered vs remaining
- Time spent, hash rate achieved
- Never repeat an already-tried mask
- Dashboard: "X% of priority-1 keyspace exhausted"

---

## Database Schemas

### Ranker (iOS) — Current

**db_full_words.sqlite3:**
```sql
CREATE TABLE fullwords (  -- or "words" (merge conflict)
    id    INTEGER PRIMARY KEY AUTOINCREMENT,
    word  TEXT UNIQUE,
    rank  REAL DEFAULT 0.5,      -- 0.0 to 1.0
    notable  INTEGER DEFAULT 0,
    reviewed INTEGER DEFAULT 0
);
```

**associations_db.sqlite3:**
```sql
CREATE TABLE word_associations (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    main_word_id    INTEGER,
    associated_text TEXT,
    is_starred      INTEGER DEFAULT 0,
    created_at      TEXT
);

CREATE TABLE audio_recordings (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    main_word_id    INTEGER,
    audio_filename  TEXT,
    transcript_text TEXT,
    is_starred      INTEGER DEFAULT 0,
    created_at      TEXT
);
```

### Ranker (iOS) — Proposed Additions

```sql
-- Free association dumps (Mode 1)
CREATE TABLE memory_dumps (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    prompt     TEXT,         -- which prompt triggered this
    content    TEXT,         -- raw user text
    created_at TEXT
);

-- Elo rankings (Mode 2)
CREATE TABLE elo_comparisons (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    word_a_id  INTEGER,
    word_b_id  INTEGER,
    winner_id  INTEGER,      -- which word was chosen
    created_at TEXT
);

-- Elo scores derived from comparisons
ALTER TABLE fullwords ADD COLUMN elo_score REAL DEFAULT 1200.0;

-- Pattern template rankings (Mode 3)
CREATE TABLE pattern_rankings (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern     TEXT,        -- e.g. "word + number"
    example     TEXT,        -- e.g. "Dragon123"
    confidence  REAL,        -- 0.0 to 1.0
    created_at  TEXT
);

-- Association chains (Mode 5)
CREATE TABLE association_chains (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    from_word   TEXT,
    to_word     TEXT,
    label       TEXT,        -- "reminds me of"
    chain_id    TEXT,        -- group chains together
    position    INTEGER,
    created_at  TEXT
);
```

### Trigram Analyzer — Current

**rankedwordletdb.sqlite3:**
```sql
CREATE TABLE words (
    word TEXT PRIMARY KEY,   -- 3-character trigram
    rank REAL                -- frequency/ranking score
);
-- 27,575 records
```

### Trigram Analyzer — Proposed Additions

```sql
-- Candidate workspace (persistent)
CREATE TABLE candidates (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    password    TEXT,
    score       REAL,
    starred     INTEGER DEFAULT 0,
    notes       TEXT,
    created_at  TEXT,
    exported_to TEXT         -- "ranker", "maskgen", null
);

-- Analysis history
CREATE TABLE analysis_log (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id  TEXT,
    candidates_analyzed INTEGER,
    candidates_flagged  INTEGER,
    candidates_exported INTEGER,
    created_at  TEXT
);
```

### Attack Tracker — Proposed (New)

```sql
CREATE TABLE mask_files (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    filename    TEXT UNIQUE,
    priority    TEXT,         -- "high", "medium", "low"
    keyspace    INTEGER,      -- total combinations
    seed_words  TEXT,         -- JSON array of source seeds
    created_at  TEXT
);

CREATE TABLE attack_runs (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    mask_file_id INTEGER REFERENCES mask_files(id),
    machine     TEXT,         -- "josephs-mac-mini", "vancouver-m4", etc.
    hashcat_session TEXT,     -- session name for --restore
    status      TEXT,         -- "running", "completed", "exhausted", "paused"
    keyspace_done INTEGER,
    hash_rate   REAL,         -- H/s achieved
    started_at  TEXT,
    finished_at TEXT
);

CREATE TABLE tried_masks (
    mask TEXT PRIMARY KEY,    -- individual mask string
    mask_file_id INTEGER REFERENCES mask_files(id),
    tried_at TEXT
);
```

---

## Canonical Interchange Format

All three tools must agree on ONE exchange format. This is the contract. Any agent working on any of the three projects must implement import/export against this spec exactly.

### `ranker_export.json` — The Canonical Interchange File

Ranker exports. Trigram Analyzer imports and exports. Maskgenerator imports.

```json
{
  "version": 1,
  "exported_from": "ranker",
  "exported_at": "2026-03-02T12:00:00Z",
  "seeds": [
    {
      "word": "dragon",
      "elo_score": 1847.2,
      "priority": 3,
      "source": "free_association",
      "notes": "strong feeling, came up in first dump"
    },
    {
      "word": "ethereum",
      "elo_score": 1623.5,
      "priority": 3,
      "source": "context_priming",
      "notes": ""
    },
    {
      "word": "phoenix",
      "elo_score": 1201.0,
      "priority": 2,
      "source": "association_chain",
      "notes": "linked from 'fire'"
    }
  ],
  "patterns": [
    {
      "pattern": "word + year",
      "example": "Dragon2014",
      "confidence": 0.85
    },
    {
      "pattern": "two words",
      "example": "DragonFire",
      "confidence": 0.60
    }
  ]
}
```

**Field definitions:**
- `version`: Always `1`. Bump if schema changes.
- `seeds[].word`: The candidate word/phrase. Lowercase, no whitespace.
- `seeds[].elo_score`: From Ranker's Elo system. Default 1200.0 for unranked.
- `seeds[].priority`: `3` = high (full mask depth), `2` = medium, `1` = low. Derived from Elo: score > 1500 → 3, > 1200 → 2, else 1.
- `seeds[].source`: One of `"free_association"`, `"context_priming"`, `"association_chain"`, `"voice_transcript"`, `"import"`, `"trigram_variation"`.
- `seeds[].notes`: Free text, may be empty string.
- `patterns[]`: Ranked password structure patterns from Mode 3. Maskgenerator uses these to weight which mask templates to prioritize.

**Priority → Maskgenerator depth mapping:**
- Priority 3 → `full` depth (all 6 stages: capitalize, capslock, mistype, combos, permutations, filter)
- Priority 2 → `medium` depth (skip keystroke errors)
- Priority 1 → `minimal` depth (capitalization variants only)

### Why JSON, Not SQLite

SQLite requires platform-specific libraries (SQLite.swift on iOS, sql.js on web, sqlite-jdbc on JVM). JSON is universally readable without dependencies. The file is small (hundreds of seeds, not millions). For the interchange file, simplicity wins.

### Export/Import Contract Per Tool

| Tool | Exports | Imports |
|------|---------|---------|
| Ranker (iOS) | `ranker_export.json` via share sheet | Nothing (it's the source of truth) |
| Trigram Analyzer (Web) | `ranker_export.json` (with trigram scores added) | `ranker_export.json` (from Ranker or own prior exports) |
| Maskgenerator (Kotlin) | `.hcmask` files for hashcat | `ranker_export.json` (reads seeds + priorities + patterns) |

---

## Phase 1.5: Data Safety — Ranking Checkpoint System

> **Non-negotiable:** Every ranking decision is irreplaceable human judgment. A single database corruption, bad migration, or botched git reset could destroy hours/days of careful work. Build automatic protection before doing serious ranking sessions.

### Automatic Database Backups

**On every app launch and every N saves, copy the live DB to a timestamped backup:**

```
~/Documents/ranker_backups/
  db_full_words_2026-03-07T14-30-00.sqlite3
  db_full_words_2026-03-07T15-45-22.sqlite3
  associations_db_2026-03-07T14-30-00.sqlite3
  ...
```

**Implementation (DatabaseManager):**
- On `init()`: copy both `.sqlite3` files to backup directory with ISO8601 timestamp
- After every 100 `updateWord()` calls: trigger a checkpoint backup
- Keep last 20 backups, prune older ones automatically
- Show "Last backup: 3 min ago" in Settings

### iCloud / File Export Checkpoints

- **Periodic JSON export:** Auto-export `ranker_export.json` every 500 rankings to a known folder (e.g., iCloud Drive or app Documents)
- **Manual checkpoint button** in Settings: "Save Checkpoint Now" — creates a named backup the user can label ("after first 2000 eliminations")
- **Restore from checkpoint** in Settings: pick any backup to restore from

### Git-Level Protection

- Before any schema migration or destructive DB operation, copy the database file first
- Never run `DROP TABLE` or `DELETE FROM fullwords` without a backup gate
- The bundled `db_full_words_bundled.sqlite3` is the baseline — user can always re-derive from it, but **all ranking decisions would be lost**

### What We're Protecting

| Data | Source | Replaceable? |
|------|--------|-------------|
| Word ranks (0-1 slider values) | Human judgment | **NO** — hours of work |
| Notable flags (stars) | Human judgment | **NO** |
| Elo comparison history | Human judgment | **NO** |
| Memory dump text | Human memory | **Partially** — can redo but may not recall same things |
| Association chains | Human memory | **Partially** |
| Voice transcripts + audio files | Human voice | **NO** — recordings are unique |
| Pattern rankings | Human judgment | Easy to redo but annoying |
| The 2.95M word corpus | Wikipedia/Wiktionary | YES — re-derive from bundled DB |

**Priority:** Implement automatic backups BEFORE the next heavy ranking session. The cost of building this is 1-2 hours. The cost of losing ranking data is days of irreplaceable work.

---

## Phase 2: Digital Archive Mining

> **Goal:** Mine 20 years of digital history — Gmail, Google Drive, local documents, images, books, films — to surface forgotten words, phrases, and patterns from the 2014 era. Feed everything into Ranker for human judgment.

**Core principle:** Every word you have ever read, written, or spoken is a potential password candidate. The corpus must be as exhaustive as possible. Wikipedia/Wiktionary (8.96M words) is the baseline vocabulary. Your personal archive is where the password actually lives.

**Key constraint:** This is a massive pipeline. Each sub-phase has clear gates so it can be built incrementally. The Document Triage UI (2.1) is the minimum viable starting point — even before text extraction works, being able to browse and tag documents from CHOAM's catalog has standalone value.

### Planned Word Sources (Priority Order)

| Source | Est. Unique Words | Status | Notes |
|--------|------------------|--------|-------|
| Wikipedia + Wiktionary (EN/FR/ES/LA) | 8.96M | **DONE** | Bundled in Ranker DB, strict ASCII, no accents |
| password_roots.txt | 1,720 | **DONE** | Common password base words |
| Memory Dump sessions | User-generated | **ACTIVE** | 6 guided prompts, words auto-extracted |
| Gmail archive (Google Takeout MBOX) | TBD | Planned (2.2) | Primary window: Jun–Sep 2014 |
| Google Drive documents | TBD | Planned (2.3) | Docs, Sheets, Keep notes |
| Local documents (CHOAM-indexed drives) | TBD | Planned (2.4) | txt, pdf, docx across AGENTMINI1, ALPHA, etc. |
| **OCR of all images containing text** | TBD | **Planned (2.6)** | Screenshots, photos of notebooks, whiteboards, sticky notes. Use Apple Vision/Tesseract. Prioritize 2013-2015 era photos. Search CHOAM for .jpg/.png on all drives. |
| **Physical notebooks (photographed + OCR'd)** | TBD | **Planned (2.6)** | Photograph every page of personal notebooks from 2014 era. OCR extract all handwritten text. |
| **Books read (full text extraction)** | TBD | **Planned (2.7)** | Extract unique words from every book read before/during 2014. Sources: Kindle library, epub files on drives, Project Gutenberg for public domain titles. Character names, place names, memorable phrases. |
| **Film/TV transcripts** | TBD | **Planned (2.8)** | Screenplays and subtitles of films/TV watched before 2014. Sources: OpenSubtitles, IMSDB, local .srt files. Character names, catchphrases, memorable dialogue. Cross-reference with Ridulian's existing transcript corpus. |
| **Communications (all platforms)** | TBD | **Planned (2.9)** | WhatsApp, WeChat, Signal, Google Voice, iMessage, Telegram, Snapchat, FB Messenger. Contact names + message text. WhatsLiberation already extracts WhatsApp. |
| AI-assisted brain mining sessions | User-generated | **Planned (Phase 1+)** | Long conversations with LLM to surface subconscious associations, contextual memory from 2014 |
| Combo generation + re-ranking | Derived | **Planned (Phase 1+)** | Top solo words × connector phrases, ranked by user judgment |

### 2.1 — Document Discovery (CHOAM Integration)

Use the existing CHOAM catalog (`~/.choam/unified_registry.db`, 1.28M files, 2.56TB on AGENTMINI1 alone) to find documents by extension.

**Discovery query:**
```sql
SELECT path, filename, extension, size
FROM files
WHERE extension IN (
    'txt', 'pdf', 'doc', 'docx', 'rtf', 'odt',
    'csv', 'json', 'md', 'log', 'html', 'xml', 'plist',
    'eml', 'mbox', 'msg', 'pages', 'numbers', 'key'
)
AND size < 10000000  -- skip files > 10MB (likely not password docs)
ORDER BY extension, filename;
```

**Document Triage UI:**
- Browse documents indexed by CHOAM, grouped by extension and drive
- User marks each document as **"mine for passwords"** or **"ignore"**
- Store triage decisions in a new SQLite table so work isn't repeated:
  ```sql
  CREATE TABLE document_triage (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      choam_path  TEXT UNIQUE,       -- full path from CHOAM catalog
      filename    TEXT,
      extension   TEXT,
      size        INTEGER,
      decision    TEXT,              -- 'mine', 'ignore', 'pending'
      notes       TEXT,              -- user annotation
      decided_at  TEXT
  );
  ```
- **Prioritize:** password files, notes, config files, personal documents from 2014 era
- **Deprioritize:** code files, system logs, media metadata, application binaries
- Special attention: files named `password*`, `keys*`, `wallet*`, `backup*`, `seed*`, `secret*`

**OPEN QUESTIONS:**
- Where does the triage tool live? New project? Module in maskgenerator? Standalone web tool?
- How to handle the Seagate 6TB NTFS drive (read-only on macOS) — need to copy/reformat first per CHOAM roadmap Phase 1
- Does the user have password manager export files from 2014? (LastPass CSV, 1Password export, KeePass XML)
- Browser history/bookmarks from 2014 — do any backups contain these?

### 2.2 — Gmail/MBOX Mining

Google Takeout exports Gmail as `.mbox` files (standard RFC 4155 format). This is the richest text archive most people have.

**Prerequisites:**
- User must run Google Takeout first (Settings → Data & Privacy → Download your data → Select Gmail)
- For 20 years of mail, export may take hours or days to prepare
- Downloaded as one or more `.mbox` files (potentially multi-GB)

**Parsing stack (Kotlin):**
- Use Apache James MIME4J (`org.apache.james:apache-mime4j-core`) or JavaMail (`jakarta.mail:jakarta.mail-api`) — both Kotlin-compatible
- Parse MIME messages: extract subject, body (plain text and stripped HTML), attachment filenames
- Handle multipart messages, base64 encoding, quoted-printable

**Date-range filtering:**
- **Primary window:** June–September 2014 (Ethereum presale: July 22 – Sep 2, 2014)
- **Secondary window:** 2013–2015 (broader context around the purchase)
- **Tertiary:** scan all mail but weight 2014-era content much higher in scoring

**Extraction targets:**
- Email subjects containing crypto keywords (ethereum, bitcoin, ether, wallet, password, key, presale)
- Body text: tokenize, extract proper nouns, numbers, URLs, email addresses
- Attachment filenames — any `.json`, `.txt`, `.key`, `.wallet` files
- Sender/recipient addresses from ethereum.org, bitcoin forums, crypto exchanges
- Self-sent emails (common password storage pattern)

### 2.3 — Google Drive Mining

Google Takeout also exports Drive contents (Docs as PDF/DOCX, Sheets as CSV/XLSX, Slides as PPTX).

**Two approaches:**
1. **Google Takeout (batch):** Download everything, process locally. Simpler but large download.
2. **Google Drive API (selective):** Use `rclone` or `gdrive` CLI to sync only documents modified/created in 2013–2015 window. More targeted.

**Focus areas:**
- Documents modified or created in 2014 (check file metadata timestamps)
- Files in folders named "passwords", "keys", "crypto", "personal", "notes"
- Google Keep notes (exported as HTML in Takeout)
- Shared documents from that era

**Same extraction pipeline as MBOX:** tokenize → frequency analysis → candidate extraction → feed to Ranker.

### 2.4 — Local Document Extraction

Process documents from CHOAM-indexed drives that passed triage in 2.1.

**Text extraction stack (Kotlin — add as Gradle deps):**

| Format | Library | Gradle dependency |
|--------|---------|-------------------|
| PDF | Apache PDFBox | `org.apache.pdfbox:pdfbox:3.0.1` |
| Word .docx | Apache POI | `org.apache.poi:poi-ooxml:5.2.5` |
| Plain text | Direct read | Encoding detection via `juniversalchardet` |
| HTML | Jsoup | `org.jsoup:jsoup:1.17.2` |
| RTF | Apache POI | `org.apache.poi:poi-scratchpad:5.2.5` |
| CSV/TSV | kotlin-csv | `com.github.doyaaaaaken:kotlin-csv-jvm:1.9.3` |
| macOS .pages | Zip extraction | Pages files are ZIP archives containing XML |

**Cross-project reuse opportunities:**
- Reuse Ridulian's FTS5 infrastructure (`Database.kt:363-457`) for full-text indexing of extracted text
- Reuse Ridulian's `sanitizeFts5Query()` for safe FTS5 MATCH queries
- Reuse CHOAM's file enumeration and registry patterns

**Storage:** Extracted text stored in a dedicated SQLite DB:
```
~/ranker_data/archive_mining.db
```
Schema:
```sql
CREATE TABLE extracted_documents (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    source_path TEXT UNIQUE,      -- original file path
    source_type TEXT,             -- 'pdf', 'docx', 'txt', 'html', 'mbox', 'gdrive'
    title       TEXT,
    content     TEXT,             -- extracted plain text
    word_count  INTEGER,
    file_date   TEXT,             -- file modified date (for era weighting)
    extracted_at TEXT
);

CREATE VIRTUAL TABLE extracted_fts USING fts5(
    title, content, content=extracted_documents, content_rowid=id
);

CREATE TABLE extracted_words (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    word        TEXT,
    frequency   INTEGER,          -- count across all documents
    doc_count   INTEGER,          -- number of documents containing this word
    era_weight  REAL,             -- higher for 2014-era documents
    source_type TEXT,             -- which pipeline produced this
    is_proper_noun INTEGER DEFAULT 0,
    is_number   INTEGER DEFAULT 0
);
```

### 2.5 — Word Mining Pipeline

The final extraction and scoring stage that produces candidates for Ranker.

**Tokenization:**
- Split extracted text on whitespace + punctuation
- Normalize to lowercase for frequency counting (preserve original case as variant)
- Handle email addresses, URLs, and usernames as special tokens

**Filtering:**
- Remove common English stopwords (top 1000 words by frequency)
- Remove words shorter than 3 characters
- Remove pure numbers shorter than 3 digits (keep years like 2014, PINs, addresses)
- Remove HTML/XML artifacts, encoding noise

**Frequency analysis:**
- Count occurrences across all extracted documents
- Weight by document era: 2014 documents score 3x, 2013/2015 score 2x, all others 1x
- Compute TF-IDF to surface words that are distinctive (not just common)

**Special extraction:**
- **Proper nouns:** Capitalized words, especially names, places, brands
- **Email addresses & usernames:** Extract local part before @
- **Domain names:** Sites visited, services used
- **Numbers:** Standalone numbers, numbers adjacent to words (e.g., "dragon2014")
- **Phrases:** Common 2-word and 3-word sequences (bigrams, trigrams from text, not character trigrams)

**Output:**
- `ranker_export.json` (canonical interchange format) with `source = "archive_mining"`
- Each extracted word becomes a seed for Ranker with priority based on era weight + frequency
- Feed into Ranker for human judgment — the user's memory is the final filter
- All processing is local — **no cloud APIs for content analysis** (privacy constraint)

**Phase gates (build incrementally):**

| Gate | Deliverable | Value |
|------|-------------|-------|
| 2.1 complete | Browse & tag CHOAM documents | Know what exists before mining |
| 2.2 complete | Gmail words extracted | Richest personal text source |
| 2.3 complete | Google Drive words extracted | Complements email |
| 2.4 complete | Local document words extracted | Captures offline notes |
| 2.5 complete | Unified word corpus scored & exported | Full pipeline feeds Ranker |
| 2.6 complete | Image OCR words extracted | Handwriting, screenshots, notebooks |
| 2.7 complete | Book corpus words extracted | Every book read pre-2014 |
| 2.8 complete | Film/TV transcript words extracted | Dialogue, character names, catchphrases |
| 2.9 complete | Communications contacts + messages extracted | Names, nicknames, conversational words |

### 2.6 — Image OCR & Handwritten Notebook Mining

> **Goal:** Extract text from every image that contains writing — screenshots, photos of notebooks, whiteboards, sticky notes, handwritten lists. Passwords are often written down physically.

**Image discovery (via CHOAM):**
```sql
SELECT path, filename, size FROM files
WHERE extension IN ('jpg', 'jpeg', 'png', 'heic', 'tiff', 'bmp')
AND size > 50000  -- skip thumbnails
ORDER BY path;
```

**OCR stack options (all local, no cloud):**
- **Apple Vision framework** (Swift, on-device) — best for iOS/macOS, handles handwriting
- **Tesseract** via `tesseract-ocr` CLI or `SwiftyTesseract` — cross-platform, many language models
- **Ridulian's existing OCR pipeline** — already does frame analysis with LLM, may be reusable

**Priority targets:**
- Photos from 2013–2015 (check EXIF dates)
- Screenshots of browser windows, terminals, text editors
- Photos of physical notebooks, sticky notes, whiteboards
- Any image in folders named "passwords", "keys", "crypto", "notes", "personal"

**Physical notebooks (manual step):**
- Photograph every page of personal notebooks from the 2014 era
- Run OCR on all pages
- Handwriting recognition may need Apple Vision (better at cursive than Tesseract)
- Extract words even if OCR confidence is low — include them with lower weight

**Output:** Extracted words → `source = "ocr_image"` or `source = "ocr_notebook"` in Ranker DB

### 2.7 — Book Corpus Mining

> **Goal:** Extract unique words from every book read before or during 2014. Character names, place names, invented words, and memorable phrases are prime password material.

**Sources:**
- **Kindle library** — Amazon allows download of purchased books. Use Calibre to convert .azw/.mobi to txt/epub
- **EPUB files on drives** — search CHOAM: `extension IN ('epub', 'mobi', 'azw', 'azw3', 'fb2')`
- **PDF books on drives** — search CHOAM for large PDFs in book-like directories
- **Project Gutenberg** — free full text of any public domain book read before 2014
- **Personal reading list** — user recalls titles, download full texts

**Extraction:**
- EPUB: unzip, parse XHTML content files with Jsoup
- MOBI/AZW: convert via Calibre CLI (`ebook-convert book.mobi book.txt`)
- PDF: Apache PDFBox
- Tokenize all text, extract unique words, proper nouns, invented/fantasy words

**High-value targets:** Fantasy/sci-fi character names, place names from fiction, technical terms from non-fiction, foreign words from translated works

**Output:** Extracted words → `source = "book_corpus"` in Ranker DB

### 2.8 — Film & TV Transcript Mining

> **Goal:** Extract unique words from screenplays, subtitles, and transcripts of every film and TV show watched before 2014. Character names and memorable dialogue are common password roots.

**Sources:**
- **Local .srt/.sub files** — search CHOAM: `extension IN ('srt', 'sub', 'ass', 'ssa', 'vtt')`
- **Ridulian transcript corpus** — already has whisper-extracted transcripts on M4/PROMETHEUS
- **OpenSubtitles.org** — bulk subtitle downloads by IMDB ID
- **IMSDB.com / SimplyScripts** — full screenplays for major films
- **Personal watch history** — cross-reference with Cinemaphile's 80K+ movie catalog

**Extraction:**
- SRT/VTT: strip timestamps, extract dialogue text
- Screenplays: parse plain text, extract dialogue and character names
- Ridulian transcripts: already in SQLite FTS5, query for unique words

**High-value targets:** Character names (especially obscure/memorable ones), catchphrases, invented words (sci-fi/fantasy), place names from films, actor names from credits

**Cross-reference with Cinemaphile:** Use the existing movie catalog to build a viewing history timeline. Prioritize films watched in 2013–2014 window.

**Output:** Extracted words → `source = "film_transcript"` in Ranker DB

### 2.9 — Communications Mining (Contacts + Message Transcripts)

> **Goal:** Extract every contact name and message text from all communications platforms. People's names, nicknames, pet names, inside jokes, and frequently used words in conversation are prime password material.

**Platforms & extraction methods:**

| Platform | Data Source | Extraction Method |
|----------|-----------|-------------------|
| **WhatsApp** | WhatsLiberation project (`~/IdeaProjects/WhatsLiberation/`) | ADB export already built — extracts chat DBs from Android. Parse `msgstore.db` (SQLite) for message text + contact names |
| **WeChat** | Local backups or ADB pull | WeChat stores messages in EnMicroMsg.db (SQLite, encrypted with IMEI-derived key). Decrypt with known tools, extract text + contacts |
| **Signal** | Desktop: `~/Library/Application Support/Signal/sql/db.sqlite` | SQLite DB, encrypted with key from `config.json`. Decrypt and extract conversations |
| **Google Voice** | Google Takeout export | Exports as HTML files with call/SMS/voicemail transcripts. Parse HTML with Jsoup |
| **iMessage** | `~/Library/Messages/chat.db` | SQLite DB, accessible on macOS directly. Extract message text + contact handles |
| **SMS/MMS** | Android backup via ADB or Google Takeout | XML format (SMS Backup & Restore app) or Takeout HTML |
| **Telegram** | Desktop: `~/Library/Group Containers/*/Telegram/` or Takeout export | JSON export via Telegram settings → export chat history |
| **Snapchat** | Snapchat data download (account settings) | JSON export with message history |
| **Facebook Messenger** | Facebook data download | JSON export with full message history |
| **Email contacts** | Google Contacts export (vCard/CSV) | Names, nicknames, company names, email local parts |

**Extraction targets:**
- **Contact names** — first names, last names, nicknames, display names. Every person you've communicated with is a potential password word
- **Message text** — tokenize all messages, extract unique words. Weight by frequency and era (2013-2015 priority)
- **Group chat names** — often memorable/creative words
- **Shared links/media filenames** — URLs, file names shared in chats
- **Voicemail transcripts** — Google Voice auto-transcribes voicemails

**Cross-project reuse:**
- **WhatsLiberation** already has ADB-based WhatsApp extraction — reuse directly
- **Intelligram/ETLigram** has ADB infrastructure for pulling Android app data
- **Godfather** has Puppeteer automation if web exports need scripting

**Priority:**
- Contacts from ALL platforms — small dataset, huge value (names are top password candidates)
- Message text from 2013–2015 window first
- Then expand to full message history for frequency analysis

**Output:** Contact names → `source = "contacts"`, message words → `source = "messages_[platform]"` in Ranker DB

---

## Phase 3: Attack Infrastructure & Execution

> **Goal:** Build and validate the full attack pipeline BEFORE the real attempt. Create test wallets, choose tools, set up tracking, benchmark hardware. When ranking is done, the infrastructure is ready to go.

### 3.0 — Test Wallet Creation (DO THIS FIRST)

> **Critical:** Never test against the real wallet until the pipeline is validated end-to-end with a test wallet.

**Create a presale-format test wallet with a known password:**

```python
# Script: create_test_wallet.py
# Creates an Ethereum presale wallet JSON with known password
# for end-to-end pipeline validation
import hashlib, os, json
from Crypto.Cipher import AES

password = b"iloveDomino!1664"  # known test password
encseed = os.urandom(32)         # random seed

# PBKDF2-SHA256, 2000 rounds, password = salt (presale format)
derived = hashlib.pbkdf2_hmac('sha256', password, password, 2000, dklen=32)

# AES-256-CBC encrypt
iv = os.urandom(16)
cipher = AES.new(derived, AES.MODE_CBC, iv)
padded = encseed + bytes([16 - len(encseed) % 16] * (16 - len(encseed) % 16))
encrypted = iv + cipher.encrypt(padded)

# Backup verification: keccak256(seed + 0x02)[:16]
from Crypto.Hash import keccak
k = keccak.new(digest_bits=256)
k.update(encseed + b'\x02')
bkp = k.hexdigest()[:32]

wallet = {
    "encseed": encrypted.hex(),
    "ethaddr": hashlib.sha256(encseed).hexdigest()[:40],
    "bkp": bkp,
    "withpw": True,
    "withwallet": True
}
with open("test_presale_wallet.json", "w") as f:
    json.dump(wallet, f, indent=2)
print(f"Test wallet created. Password: {password.decode()}")
```

**Validation checklist:**
- [ ] Create test wallet with known password
- [ ] Extract hash with `ethereum2john.py`
- [ ] Crack with hashcat mode 16300 — confirm it finds the known password
- [ ] Crack with btcrecover — confirm token-based approach works
- [ ] Run full pipeline: Ranker export → Maskgenerator → hashcat → found
- [ ] Create 3 test wallets with different password styles (single word, combo, connector+word)

**Store at:** `~/ranker_data/test_wallets/`

### 3.1 — Tool Selection (DECIDED)

**Two tools, two strategies:**

| Tool | Role | When to use |
|------|------|-------------|
| **btcrecover** | Smart token-based combinatorial attack | **PRIMARY — use first.** Directly consumes ranked word list as tokens. Handles word combos + modifiers natively. Perfect for the Ranker pipeline output. |
| **hashcat** | Raw GPU brute-force mask attack | **SECONDARY — use for exhaustive sweep.** After btcrecover exhausts smart combos, hashcat burns through the remaining mask keyspace. |

**Why btcrecover first:**
- Token-based: you define `domino`, `love`, `i`, `1664` as tokens → it tries `iloveDomino1664`, `Domino!love`, `ILoveDomino`, etc.
- Directly maps to the Ranker pipeline output (ranked words = token priorities)
- Handles capitalization, number insertion, special char insertion automatically
- Supports `--typos` for common keystroke errors
- Supports `--max-tokens` to limit combo depth (1-3 words)
- **Python-based — runs on Apple Silicon** (no GPU needed for smart attacks)
- Install: `pip3 install btcrecover` or clone from `gurnec/btcrecover`

**Why hashcat second:**
- 10-100x faster than btcrecover for raw throughput
- Mode 16300 specifically optimized for ETH presale format
- Mask attack (`-a 3`) for systematic keyspace coverage
- **Requires NVIDIA GPU** — cloud rental (Vast.ai, RunPod, Lambda)

**NOT using John the Ripper** — hashcat is faster for GPU work, btcrecover is smarter for token work. JtR fills no gap.

### 3.2 — Wallet File & Hash Extraction

**Presale wallet encryption (mode 16300):**
- Algorithm: PBKDF2-SHA256, **2000 iterations**, password used as **both passphrase AND salt**
- Encryption: AES-256-CBC of the seed
- Verification: first 16 bytes of `keccak256(decrypted_seed + 0x02)` must match the `bkp` field
- This is hashcat **mode 16300** (Ethereum presale wallet), NOT mode 15600

**Presale wallet file format (JSON):**
```json
{
    "encseed": "<hex-encoded encrypted seed>",
    "ethaddr": "<ethereum address>",
    "bkp":     "<hex backup verification bytes>",
    "withpw":  true,
    "withwallet": true
}
```

**Hash extraction:**
- `ethereum2john.py` from John the Ripper repo (`magnumripper/JohnTheRipper`)
- Extracts hash in format consumable by both hashcat and btcrecover
- btcrecover can also consume the wallet JSON directly: `--wallet presale_wallet.json`

**ACTION ITEMS (user must resolve):**
- [ ] Locate the presale wallet JSON file (which machine? which drive? search CHOAM)
- [ ] Make 3+ backup copies on different drives immediately
- [ ] Extract hash with ethereum2john.py
- [ ] Verify on-chain via Etherscan that the ETH is still at the `ethaddr`
- [ ] Check for original purchase confirmation email (hints about password requirements)
- [ ] Check Wayback Machine for ethereum.org presale page — did it show password requirements?

### 3.3 — Hardware & Budget

All three machines are Apple Silicon — **no local GPU hashcat support.** btcrecover runs on CPU (fine for smart attacks). hashcat requires cloud GPU rental.

| Machine | Chip | btcrecover | hashcat |
|---------|------|-----------|---------|
| josephs-mac-mini | Apple Silicon | YES (CPU) | NO |
| vancouver-m4 | Apple M4 | YES (CPU) | NO |
| bali-mac-mini-old | Apple Silicon | YES (CPU) | NO |

**Cloud GPU for hashcat (when needed):**

| Provider | GPU | Cost/hr | Est. hash rate (mode 16300) |
|----------|-----|---------|----------------------------|
| Vast.ai | RTX 4090 | ~$0.40 | ~1.5M/s |
| RunPod | RTX 4090 | ~$0.50 | ~1.5M/s |
| Lambda Labs | A100 | ~$1.10 | ~2M/s |
| AWS p4d.24xlarge | 8×A100 | ~$32 | ~16M/s |

**Budget: $10K → ~10^14 total hashes** (see complexity analysis in Phase 1)

**Attack sequence (maximize ROI):**
1. **btcrecover token attack locally** — top 50 words × connectors × modifiers. FREE. Hours to days.
2. **btcrecover expanded** — top 500 words × combos. FREE. Days to weeks.
3. **hashcat high-priority masks on cloud** — maskgenerator Tier 1 output. ~$100-500.
4. **hashcat medium-priority** — Tier 2. ~$1K-5K.
5. **hashcat exhaustive** — Tier 3. Remaining budget.

### 3.4 — Attack Tracking System

> **Critical:** With multi-day attacks across multiple tools and machines, you MUST track what's been tested. Redundant attacks waste money and time.

**Attack tracker database:** `~/ranker_data/attack_tracker.db`

```sql
CREATE TABLE attack_runs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    run_name        TEXT UNIQUE,           -- e.g. "btc_top50_v1", "hc_tier1_vast_20260401"
    tool            TEXT,                  -- 'btcrecover' or 'hashcat'
    machine         TEXT,                  -- 'local', 'vast_4090_1', 'runpod_a100_1'
    attack_mode     TEXT,                  -- 'token', 'mask', 'dictionary', 'hybrid'
    input_file      TEXT,                  -- tokenlist or .hcmask file path
    wallet_file     TEXT,                  -- 'test_wallet_1.json' or 'real_presale.json'
    keyspace_est    INTEGER,              -- estimated passwords to try
    keyspace_done   INTEGER DEFAULT 0,    -- passwords actually tried (from hashcat status)
    hash_rate       REAL,                 -- observed hashes/sec
    started_at      TEXT,
    finished_at     TEXT,
    status          TEXT,                  -- 'running', 'completed', 'paused', 'found'
    result          TEXT,                  -- NULL or the found password
    notes           TEXT,
    cost_usd        REAL DEFAULT 0.0      -- cloud GPU cost for this run
);

CREATE TABLE attack_inputs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id          INTEGER REFERENCES attack_runs(id),
    input_type      TEXT,                  -- 'token', 'mask_line', 'dictionary'
    input_value     TEXT,                  -- the actual token/mask/dict entry
    priority        INTEGER                -- from Ranker export
);

CREATE TABLE tested_passwords (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    password_hash   TEXT UNIQUE,           -- SHA256 of the password (not the wallet hash)
    password_text   TEXT,                  -- the actual password tried (optional, for debugging)
    run_id          INTEGER REFERENCES attack_runs(id),
    tested_at       TEXT
);
-- Index for dedup checking
CREATE INDEX idx_tested_hash ON tested_passwords(password_hash);
```

**Deduplication strategy:**
- Before each run, hash all candidate passwords → check against `tested_passwords`
- Skip any already tested → only feed new candidates to hashcat/btcrecover
- After each run, insert all tested passwords into the table
- For mask attacks (billions of candidates), track at the mask-line level in `attack_inputs` rather than individual passwords

**Kotlin CLI for tracking** (new Gradle tasks in maskgenerator):
- `./gradlew attackStart --args='run_name tool machine input_file'` — register a new run
- `./gradlew attackStatus` — show all runs, progress, cost
- `./gradlew attackComplete --args='run_name [password]'` — mark run done
- `./gradlew attackDedup --args='input_file'` — filter input file against already-tested

**Alert on success:**
```bash
# Cron job on the machine running hashcat (check every 5 min):
*/5 * * * * grep -q "." /path/to/found.txt && \
  ssh josephmalone@100.78.37.56 "source ~/.nvm/nvm.sh && nvm use 24.13.0 && \
  clawdbot message send --channel whatsapp --target '+15109842762' \
  --message 'PASSWORD FOUND: check found.txt on [machine]'"
```

### 3.5 — btcrecover Setup & Token File Format

**Install:**
```bash
pip3 install btcrecover
# or clone for latest:
git clone https://github.com/gurnec/btcrecover.git
cd btcrecover && pip3 install -r requirements.txt
```

**Token file format** (generated from Ranker export):
```
# High priority words (one per line, btcrecover tries all combinations)
domino
love
ethereum
dragon
# Connector tokens (prefixed with + means "optional")
+i
+my
+the
+il
# Number tokens
+1664
+0901
+2014
+911
# Special char tokens
+!
+*
+#
+@
```

**Run command:**
```bash
python3 btcrecover.py \
  --wallet presale_wallet.json \
  --tokenlist ranked_tokens.txt \
  --max-tokens 4 \
  --typos 1 \
  --typos-capslock --typos-swap \
  --no-eta \
  --threads 8
```

**Maskgenerator integration:**
- New Gradle task: `./gradlew generateTokenFile` — converts Ranker export to btcrecover token format
- Priority tiers become token ordering (btcrecover tries earlier tokens first)
- Connector words injected automatically as optional tokens

### 3.6 — hashcat Setup & Execution

**Install on cloud GPU:**
```bash
# On Vast.ai / RunPod instance:
apt update && apt install -y hashcat
# Verify mode 16300:
hashcat -m 16300 -b  # benchmark
```

**Run with maskgenerator output:**
```bash
hashcat -m 16300 \
  -a 3 \
  presale_wallet.hash \
  --session=tier1_20260401 \
  -o found.txt \
  --potfile-path=ranker.potfile \
  tier1_masks.hcmask
```

**Session management:**
- `hashcat --restore --session=tier1_20260401` — resume after pause
- `hashcat --session=X -s SKIP -l LIMIT` — split keyspace across machines
- Always use `--session` and `--potfile-path` for tracking

**Potfile sync:**
```bash
# After each run, sync potfile back to local:
rsync -avz cloud_machine:/path/ranker.potfile ~/ranker_data/potfiles/
# Merge potfiles:
sort -u ~/ranker_data/potfiles/*.potfile > ~/ranker_data/potfiles/merged.potfile
```

### 3.7 — Phase 3 Milestones

| Milestone | Deliverable | Gate |
|-----------|-------------|------|
| 3.0 | Test wallet created + validated | Can crack test wallet with known password |
| 3.1 | btcrecover installed + working | Cracks test wallet via token attack |
| 3.2 | Hash extracted from real wallet | Real wallet located, backed up, hash ready |
| 3.3 | Cloud GPU benchmarked | Know exact hash rate and cost/hr |
| 3.4 | Attack tracker DB + CLI | Can register, track, dedup runs |
| 3.5 | Token file generator | Ranker export → btcrecover tokenlist automated |
| 3.6 | Maskgenerator → hashcat | .hcmask files validated against test wallet |
| 3.7 | Alert system | WhatsApp notification on password found |
| **3.8** | **REAL ATTACK BEGINS** | **All above gates passed** |

### 3.8 — Alternative Approaches (Keep in Mind)

- **Professional recovery services** — KeychainX, Dave Bitcoin, Wallet Recovery Services. Typical fee: 10-20% of recovered funds. Risk: sharing wallet file. Some accept hash-only.
- **pyethrecover / ethcracker** — simpler Python tools for quick spot-checks of high-confidence guesses
- **Environment recreation** — same computer, desk, music as July 2014. Wayback Machine the ethereum.org presale form for password requirements.
- **Hypnotherapy** — some recovery services offer memory recall sessions

## Platform Rationale

| Tool | Platform | Why |
|------|----------|-----|
| Ranker | iOS (SwiftUI) | Portable mnemonic sessions. Walking around, different environments trigger different memories. The phone is always with you. |
| Trigram Analyzer | Web (TypeScript) | Big screen, keyboard for typing candidates, easy UX iteration. Could upgrade to React or stay vanilla JS. |
| Maskgenerator | Kotlin/Gradle (+ Python) | CLI tool, runs on any machine with JVM, integrates with hashcat. Kotlin preferred per user scripting preference. |

## Known Issues

| Issue | Project | Severity | Notes |
|-------|---------|----------|-------|
| Merge conflict (words vs fullwords) | Ranker | CRITICAL | DatabaseManager.swift lines 22-32, WordSorterContentView.swift lines 1-7 |
| 90 dummy seed words | Ranker | HIGH | Replace with Mode 1 free association data |
| Fake transcript | Ranker | HIGH | Replace with iOS Speech framework |
| Simulator-only | Ranker | HIGH | fatalError() in RankerApp.swift init |
| saveToFile overwrites | Maskgenerator | HIGH | Only last seed group survives; main() at Parser.kt:405 knows this but replicates the Python bug |
| No CLI argument parsing | Maskgenerator | MEDIUM | main() exists at Parser.kt:405 but hardcodes file paths, no depth levels |
| containsLower() false positive | Maskgenerator | MEDIUM | Placeholder chars (u in ?u) match LOWER_LETTER_SET; containsNumber already handles this correctly by stripping ?1 |
| No candidate persistence | Trigram Analyzer | MEDIUM | One-shot use only |
| 11 unpushed commits | Maskgenerator | LOW | Ahead of origin/master |
| On non-master branch | Trigram Analyzer | LOW | On claude/code-review-docs-tests branch |
