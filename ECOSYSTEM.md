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

## Phase 2: Digital Archive Mining

> **Goal:** Mine 20 years of digital history — Gmail, Google Drive, local documents across multiple drives — to surface forgotten words, phrases, and patterns from the 2014 era. Feed everything into Ranker for human judgment.

**Key constraint:** This is a massive pipeline. Each sub-phase has clear gates so it can be built incrementally. The Document Triage UI (2.1) is the minimum viable starting point — even before text extraction works, being able to browse and tag documents from CHOAM's catalog has standalone value.

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

---

## Phase 3: Hashcat Execution

> **Goal:** Run hashcat against the presale wallet using masks generated by the pipeline. This phase has many unknowns — they are captured here as explicit open questions for the user to work through before execution.

### 3.1 — Wallet File & Hash Extraction

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

**Hash extraction tool:**
- `ethereum2john.py` from John the Ripper repository (`magnumripper/JohnTheRipper` on GitHub)
- Extracts the hash in a format hashcat can consume
- Alternative: manual extraction — the `encseed` and `bkp` fields contain everything hashcat needs

**OPEN QUESTIONS:**
- Where is the presale wallet JSON file stored? Which machine? Which drive?
- Has the hash already been extracted with ethereum2john?
- Is there a backup copy of the wallet file? (If only one copy exists, make backups immediately)
- What Ethereum address does the presale correspond to? (Can verify on-chain via Etherscan that the presale allocation exists and the ETH is still there)
- Was the wallet created directly on ethereum.org or through a third-party tool?
- Does the user have the original purchase confirmation email? (May contain hints)

### 3.2 — Hardware & Performance

Hashcat mode 16300 benchmarks show ~**200,000 passwords/second** on a decent discrete GPU (NVIDIA RTX 3080-class). Apple Silicon (M-series) has **no hashcat GPU support** — it falls back to CPU, which is orders of magnitude slower.

**OPEN QUESTIONS:**
- What GPU(s) are currently available across the machine inventory?
  - josephs-mac-mini — Apple Silicon? → No hashcat GPU support
  - vancouver-m4 — Apple Silicon M4? → No hashcat GPU support
  - bali-mac-mini-old — what chip?
- **Cloud GPU options** (if no local discrete GPU):
  - AWS p3.2xlarge (V100, ~$3/hr) or p4d.24xlarge (A100, ~$32/hr)
  - Vast.ai — community GPU rental, often $0.20–$1.00/hr for consumer GPUs
  - RunPod — serverless GPU, pay-per-second
  - Lambda Labs — dedicated GPU instances
  - What is the budget for cloud GPU time?
- **Keyspace calculation:**
  - What is the total keyspace from maskgenerator output? (Sum of all .hcmask line keyspaces)
  - At 200k/s, how many hours/days to exhaust the full keyspace?
  - Is the keyspace manageable (< 1 week) or astronomical (> 1 year)?
- **Attack mode comparison:**
  - Is dictionary + rules attack (`-a 0 -r`) faster than mask attack (`-a 3`) for this use case?
  - Dictionary candidates: rockyou.txt, Have I Been Pwned password lists, leaked password databases
  - Rules: best64.rule, dive.rule, OneRuleToRuleThemAll — apply transformations to dictionary words
  - Hybrid attacks: dictionary + mask (`-a 6` or `-a 7`) — combine known words with unknown suffixes

### 3.3 — Execution Strategy

**OPEN QUESTIONS:**
- Run locally vs cloud vs hybrid?
  - Local: free but slow (CPU-only on current machines)
  - Cloud: fast but costs money, requires setup
  - Hybrid: dictionary attacks locally, mask attacks on cloud GPU
- How to split `.hcmask` files across multiple machines?
  - By file? (each machine gets different priority tier)
  - By keyspace range? (`--skip` and `--limit` flags)
  - By mask pattern? (group similar masks together)
- Session naming convention for `--restore`:
  - Suggestion: `{machine}_{priority}_{date}` (e.g., `cloud_high_20260315`)
  - Sessions allow pausing and resuming long-running attacks
- How to sequence attacks for maximum ROI?
  1. Dictionary attacks first (fast, covers common passwords)
  2. High-priority masks second (user's best guesses, full permutation depth)
  3. Medium-priority masks third
  4. Low-priority masks last (broad exploration)
- Should we run a quick benchmark first? `hashcat -m 16300 -b` gives the hash rate for this mode on the available hardware

### 3.4 — .pot File & Progress Tracking

Hashcat writes found passwords to `hashcat.potfile` (default location: `~/.local/share/hashcat/hashcat.potfile` or working directory).

The Attack Tracker database (from maskgenerator P4) records which masks have been generated and which runs have been attempted.

**OPEN QUESTIONS:**
- Central `.pot` file location — where should the canonical potfile live?
  - Sync via CHOAM/rsync across machines?
  - Git repo (private) for version control?
  - Simple rsync cron job?
- How to aggregate results from multiple machines running in parallel?
  - Each machine has its own potfile — need merge strategy
  - `hashcat --potfile-path` flag to specify a custom location
- Progress dashboard:
  - The `attackStatus` Gradle task (maskgenerator P4) covers mask tracking
  - But what about cross-machine orchestration? Which machine is running what?
  - Simple: shared Google Sheet or text file with status updates
  - Advanced: small web dashboard reading from attack_tracker.db
- Alert mechanism when password is found:
  - hashcat prints to stdout on success — but if running unattended?
  - Cron job checking potfile for new entries → Clawdbot WhatsApp notification
  - `hashcat --outfile=found.txt` + fswatch/inotifywait → trigger alert

### 3.5 — Alternative Approaches

Before committing to full hashcat mask attacks, consider these alternatives — some may be faster for this specific use case.

**OPEN QUESTIONS:**
- Has the user tried **pyethrecover** or **ethcracker**?
  - Simpler Python tools specifically for Ethereum wallet recovery
  - Slower than hashcat but easier to set up and script
  - Good for testing a small number of high-confidence guesses quickly
- Is **btcrecover** an option?
  - Supports Ethereum presale wallets with password "hints"
  - Token-based approach: define password components and let it try combinations
  - Example: `btcrecover --wallet wallet.json --tokenlist tokens.txt`
  - May be ideal for the "memory excavation" approach where the user has fragments, not exact passwords
- **Professional recovery services** — cost/trust tradeoff:
  - KeychainX — specializes in crypto wallet recovery
  - Dave Bitcoin (Dave Wallet Recovery Services)
  - Wallet Recovery Services (walletrecoveryservices.com)
  - Typical model: percentage of recovered funds (10-20%) or flat fee
  - Trust issue: you're giving them your wallet file and hash
  - Some accept "hash only" (not the wallet file itself) to reduce risk
- **Smart brute force:**
  - If Ranker + archive mining narrows to ~100 high-confidence seed words × ~10 password patterns, the keyspace might be small enough for exhaustive search
  - At 200k/s, a keyspace of 10M takes ~50 seconds
  - At 200k/s, a keyspace of 1B takes ~83 minutes
  - The entire point of the RANKER pipeline is to make the keyspace small enough that brute force is practical
- **Memory techniques beyond software:**
  - Hypnotherapy for memory recall (some recovery services offer this)
  - Systematic environment recreation: same computer, same desk, same music as 2014
  - Dream journaling: passwords sometimes surface in dreams when actively thinking about them
  - The password was created on a web form at ethereum.org — can Wayback Machine show the exact form? Did it have password requirements (min length, special chars)?

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
