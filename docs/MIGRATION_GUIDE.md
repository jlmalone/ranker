# Database Migration Guide

**Version:** 1.0
**Last Updated:** 2025-11-15
**Database:** SQLite 3
**Application:** Ranker iOS App

---

## Table of Contents

1. [Migration System Overview](#migration-system-overview)
2. [Migration Templates](#migration-templates)
3. [Step-by-Step Migration Examples](#step-by-step-migration-examples)
4. [Rollback Procedures](#rollback-procedures)
5. [Testing Migrations](#testing-migrations)
6. [Best Practices](#best-practices)

---

## Migration System Overview

### Current State

**Status:** ⚠️ No formal migration system implemented

The application currently uses a simple initialization approach:
- Database created on first launch
- Schema created with `CREATE TABLE IF NOT EXISTS`
- Data populated once (checked via UserDefaults)
- No version tracking
- No migration history

### Recommended Migration System

Implement a version-based migration system with:
- ✅ Version tracking in database
- ✅ Ordered migration files
- ✅ Automatic backup before migrations
- ✅ Rollback capability
- ✅ Migration history logging

---

## Migration Templates

### Template 1: Basic Migration Manager

Create this file: `Ranker/MigrationManager.swift`

```swift
import Foundation
import SQLite

class MigrationManager {
    private var db: Connection?
    private let migrations: [Migration]

    // MARK: - Migration Model

    struct Migration {
        let version: Int
        let description: String
        let migrate: (Connection) throws -> Void
        let rollback: ((Connection) throws -> Void)?

        init(version: Int,
             description: String,
             migrate: @escaping (Connection) throws -> Void,
             rollback: ((Connection) throws -> Void)? = nil) {
            self.version = version
            self.description = description
            self.migrate = migrate
            self.rollback = rollback
        }
    }

    // MARK: - Initialization

    init(database: Connection) {
        self.db = database
        self.migrations = MigrationManager.allMigrations()
        setupMigrationTracking()
    }

    // MARK: - Migration Tracking Table

    private func setupMigrationTracking() {
        let createSQL = """
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            description TEXT NOT NULL,
            applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """

        do {
            try db?.execute(createSQL)
        } catch {
            print("Failed to create migration tracking table: \(error)")
        }
    }

    // MARK: - Current Version

    private func currentVersion() -> Int {
        do {
            let query = "SELECT MAX(version) FROM schema_migrations"
            if let version = try db?.scalar(query) as? Int64 {
                return Int(version)
            }
        } catch {
            print("Failed to get current version: \(error)")
        }
        return 0
    }

    // MARK: - Run Migrations

    func migrate() throws {
        let current = currentVersion()
        print("Current database version: \(current)")

        let pending = migrations.filter { $0.version > current }.sorted { $0.version < $1.version }

        if pending.isEmpty {
            print("Database is up to date")
            return
        }

        print("Found \(pending.count) pending migrations")

        for migration in pending {
            print("Applying migration \(migration.version): \(migration.description)")

            // Backup before migration
            try backupDatabase()

            // Run migration in transaction
            try db?.transaction {
                try migration.migrate(db!)

                // Record migration
                let insert = """
                INSERT INTO schema_migrations (version, description)
                VALUES (\(migration.version), '\(migration.description)');
                """
                try db?.execute(insert)
            }

            print("✅ Migration \(migration.version) completed successfully")
        }
    }

    // MARK: - Rollback

    func rollback(to targetVersion: Int) throws {
        let current = currentVersion()

        guard targetVersion < current else {
            print("Target version \(targetVersion) is not less than current version \(current)")
            return
        }

        let toRollback = migrations
            .filter { $0.version > targetVersion && $0.version <= current }
            .sorted { $0.version > $1.version }

        for migration in toRollback {
            guard let rollbackFn = migration.rollback else {
                throw MigrationError.rollbackNotSupported(version: migration.version)
            }

            print("Rolling back migration \(migration.version): \(migration.description)")

            try db?.transaction {
                try rollbackFn(db!)

                // Remove migration record
                let delete = "DELETE FROM schema_migrations WHERE version = \(migration.version);"
                try db?.execute(delete)
            }

            print("✅ Rollback of migration \(migration.version) completed")
        }
    }

    // MARK: - Backup

    private func backupDatabase() throws {
        guard let dbPath = db?.description.components(separatedBy: " ").last?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"")) else {
            throw MigrationError.backupFailed
        }

        let fileManager = FileManager.default
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let backupPath = dbPath.replacingOccurrences(
            of: ".sqlite3",
            with: "_backup_\(timestamp).sqlite3"
        )

        try fileManager.copyItem(atPath: dbPath, toPath: backupPath)
        print("📦 Backup created: \(backupPath)")
    }

    // MARK: - Migration Definitions

    static func allMigrations() -> [Migration] {
        return [
            createMigration1(),
            createMigration2(),
            createMigration3(),
            // Add more migrations here
        ]
    }
}

// MARK: - Errors

enum MigrationError: Error {
    case rollbackNotSupported(version: Int)
    case backupFailed
}
```

---

### Template 2: Migration Definition File

Create this file: `Ranker/Migrations.swift`

```swift
import Foundation
import SQLite

extension MigrationManager {

    // MARK: - Migration 1: Initial Schema (Baseline)

    static func createMigration1() -> Migration {
        return Migration(
            version: 1,
            description: "Initial schema - words table"
        ) { db in
            // This represents the current schema as v1
            let createTable = """
            CREATE TABLE IF NOT EXISTS words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word TEXT UNIQUE NOT NULL,
                rank REAL NOT NULL,
                notable INTEGER NOT NULL DEFAULT 0,
                reviewed INTEGER NOT NULL DEFAULT 0
            );
            """
            try db.execute(createTable)
        } rollback: { db in
            try db.execute("DROP TABLE IF EXISTS words;")
        }
    }

    // MARK: - Migration 2: Add Indexes

    static func createMigration2() -> Migration {
        return Migration(
            version: 2,
            description: "Add performance indexes"
        ) { db in
            try db.execute("CREATE INDEX IF NOT EXISTS idx_words_reviewed ON words(reviewed);")
            try db.execute("CREATE INDEX IF NOT EXISTS idx_words_notable ON words(notable);")
            try db.execute("CREATE INDEX IF NOT EXISTS idx_words_reviewed_rank ON words(reviewed, rank DESC);")
        } rollback: { db in
            try db.execute("DROP INDEX IF EXISTS idx_words_reviewed;")
            try db.execute("DROP INDEX IF EXISTS idx_words_notable;")
            try db.execute("DROP INDEX IF EXISTS idx_words_reviewed_rank;")
        }
    }

    // MARK: - Migration 3: Add Timestamps

    static func createMigration3() -> Migration {
        return Migration(
            version: 3,
            description: "Add timestamp columns"
        ) { db in
            // Add columns
            try db.execute("ALTER TABLE words ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;")
            try db.execute("ALTER TABLE words ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP;")

            // Create trigger to auto-update timestamp
            let trigger = """
            CREATE TRIGGER IF NOT EXISTS update_words_timestamp
            AFTER UPDATE ON words
            FOR EACH ROW
            BEGIN
                UPDATE words SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
            END;
            """
            try db.execute(trigger)
        } rollback: { db in
            // Note: SQLite doesn't support DROP COLUMN before version 3.35.0
            // For older versions, you'd need to recreate the table
            try db.execute("DROP TRIGGER IF EXISTS update_words_timestamp;")

            // Recreate table without timestamp columns
            try db.execute("ALTER TABLE words RENAME TO words_old;")

            try db.execute("""
            CREATE TABLE words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word TEXT UNIQUE NOT NULL,
                rank REAL NOT NULL,
                notable INTEGER NOT NULL DEFAULT 0,
                reviewed INTEGER NOT NULL DEFAULT 0
            );
            """)

            try db.execute("""
            INSERT INTO words (id, word, rank, notable, reviewed)
            SELECT id, word, rank, notable, reviewed FROM words_old;
            """)

            try db.execute("DROP TABLE words_old;")
        }
    }

    // MARK: - Migration 4: Add Categories

    static func createMigration4() -> Migration {
        return Migration(
            version: 4,
            description: "Add categories table and relationship"
        ) { db in
            // Create categories table
            try db.execute("""
            CREATE TABLE categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                description TEXT
            );
            """)

            // Add category_id to words
            try db.execute("ALTER TABLE words ADD COLUMN category_id INTEGER REFERENCES categories(id);")

            // Create index
            try db.execute("CREATE INDEX idx_words_category ON words(category_id);")

            // Insert default categories
            try db.execute("""
            INSERT INTO categories (name, description) VALUES
                ('3-letter', 'All 3-letter combinations'),
                ('numbers', 'Numbers 1-9999'),
                ('custom', 'User-added words');
            """)

            // Update existing words with categories
            try db.execute("""
            UPDATE words SET category_id = (
                SELECT id FROM categories WHERE name = '3-letter'
            ) WHERE LENGTH(word) = 3 AND word GLOB '[a-z]*';
            """)

            try db.execute("""
            UPDATE words SET category_id = (
                SELECT id FROM categories WHERE name = 'numbers'
            ) WHERE word GLOB '[0-9]*';
            """)
        } rollback: { db in
            // Remove category_id from words
            try db.execute("ALTER TABLE words RENAME TO words_old;")

            try db.execute("""
            CREATE TABLE words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word TEXT UNIQUE NOT NULL,
                rank REAL NOT NULL,
                notable INTEGER NOT NULL DEFAULT 0,
                reviewed INTEGER NOT NULL DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            """)

            try db.execute("""
            INSERT INTO words (id, word, rank, notable, reviewed, created_at, updated_at)
            SELECT id, word, rank, notable, reviewed, created_at, updated_at FROM words_old;
            """)

            try db.execute("DROP TABLE words_old;")
            try db.execute("DROP TABLE categories;")
            try db.execute("DROP INDEX IF EXISTS idx_words_category;")
        }
    }

    // MARK: - Migration 5: Add Word Associations

    static func createMigration5() -> Migration {
        return Migration(
            version: 5,
            description: "Add word associations table"
        ) { db in
            try db.execute("""
            CREATE TABLE word_associations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
                associated_word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
                association_type TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(word_id, associated_word_id, association_type)
            );
            """)

            try db.execute("CREATE INDEX idx_associations_word_id ON word_associations(word_id);")
            try db.execute("CREATE INDEX idx_associations_associated_word_id ON word_associations(associated_word_id);")
        } rollback: { db in
            try db.execute("DROP TABLE word_associations;")
        }
    }
}
```

---

## Step-by-Step Migration Examples

### Example 1: Adding Indexes (v1 → v2)

#### Before Migration (v1)

```
Database Version: 1

Table: words
  - id (PK)
  - word (UNIQUE)
  - rank
  - notable
  - reviewed

Indexes:
  - PRIMARY KEY (id)
  - UNIQUE (word)
```

#### Migration Steps

1. **Update DatabaseManager.swift**

```swift
class DatabaseManager {
    private var migrationManager: MigrationManager?

    init() {
        setupDatabase()
        migrationManager = MigrationManager(database: db!)

        // Run migrations
        do {
            try migrationManager?.migrate()
        } catch {
            print("Migration failed: \(error)")
        }

        createWordsTable()  // Now safe (CREATE IF NOT EXISTS)
        populateInitialDataIfNeeded()
    }
}
```

2. **Run Migration**

The migration system will automatically:
- Detect current version (1)
- Find pending migrations (2)
- Create backup
- Execute migration 2
- Record in schema_migrations table

3. **Verify Migration**

```sql
-- Check current version
SELECT MAX(version) FROM schema_migrations;
-- Returns: 2

-- Verify indexes created
PRAGMA index_list(words);
-- Shows: idx_words_reviewed, idx_words_notable, idx_words_reviewed_rank

-- Check migration history
SELECT * FROM schema_migrations;
-- Returns:
-- 1 | Initial schema - words table | 2024-04-11 10:00:00
-- 2 | Add performance indexes      | 2024-04-15 14:30:00
```

#### After Migration (v2)

```
Database Version: 2

Table: words (unchanged schema)
  - id (PK)
  - word (UNIQUE)
  - rank
  - notable
  - reviewed

Indexes:
  - PRIMARY KEY (id)
  - UNIQUE (word)
  - idx_words_reviewed (NEW)
  - idx_words_notable (NEW)
  - idx_words_reviewed_rank (NEW)
```

---

### Example 2: Adding Timestamp Columns (v2 → v3)

#### Migration Steps

1. **Migration runs automatically** on app launch

2. **SQL executed:**

```sql
-- Add columns
ALTER TABLE words ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE words ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP;

-- Create trigger
CREATE TRIGGER update_words_timestamp
AFTER UPDATE ON words
FOR EACH ROW
BEGIN
    UPDATE words SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
```

3. **Verify:**

```sql
PRAGMA table_info(words);
-- Now shows 7 columns (added created_at, updated_at)

SELECT * FROM sqlite_master WHERE type='trigger';
-- Shows: update_words_timestamp
```

4. **Test auto-update:**

```sql
UPDATE words SET rank = 0.8 WHERE word = 'abc';
SELECT word, rank, updated_at FROM words WHERE word = 'abc';
-- updated_at should be current timestamp
```

---

### Example 3: Adding Categories (v3 → v4)

#### Before Migration

```
words table:
  - No category_id column

categories table:
  - Does not exist
```

#### Migration Process

1. **Create categories table**
2. **Add category_id column to words**
3. **Populate default categories**
4. **Categorize existing words**

#### SQL Executed

```sql
-- Step 1
CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT
);

-- Step 2
ALTER TABLE words ADD COLUMN category_id INTEGER REFERENCES categories(id);
CREATE INDEX idx_words_category ON words(category_id);

-- Step 3
INSERT INTO categories (name, description) VALUES
    ('3-letter', 'All 3-letter combinations'),
    ('numbers', 'Numbers 1-9999'),
    ('custom', 'User-added words');

-- Step 4: Categorize existing words
UPDATE words SET category_id = (
    SELECT id FROM categories WHERE name = '3-letter'
) WHERE LENGTH(word) = 3 AND word GLOB '[a-z]*';

UPDATE words SET category_id = (
    SELECT id FROM categories WHERE name = 'numbers'
) WHERE word GLOB '[0-9]*';
```

#### After Migration

```
Database Version: 4

Table: words
  - id
  - word
  - rank
  - notable
  - reviewed
  - created_at
  - updated_at
  - category_id (FK → categories)

Table: categories (NEW)
  - id (PK)
  - name (UNIQUE)
  - description

Data in categories:
  1 | 3-letter | All 3-letter combinations
  2 | numbers  | Numbers 1-9999
  3 | custom   | User-added words

Words categorized:
  - 17,576 words → category_id = 1
  - 9,999 words → category_id = 2
```

---

## Rollback Procedures

### Manual Rollback

#### Option 1: Restore from Backup

```swift
func restoreFromBackup(backupPath: String) throws {
    let fileManager = FileManager.default
    let currentPath = databasePath()!

    // Remove current database
    try fileManager.removeItem(atPath: currentPath)

    // Copy backup to current location
    try fileManager.copyItem(atPath: backupPath, toPath: currentPath)

    // Reconnect
    setupDatabase()
    print("Database restored from backup: \(backupPath)")
}

// Usage:
try restoreFromBackup(backupPath: "/path/to/db_backup_20240415_143000.sqlite3")
```

#### Option 2: Use Migration Rollback

```swift
// In AppDelegate or initialization code
do {
    let migrationManager = MigrationManager(database: db!)

    // Rollback to version 2 (from version 4)
    try migrationManager.rollback(to: 2)
} catch {
    print("Rollback failed: \(error)")
}
```

### Rollback Example: v4 → v3

```swift
// Rolling back Migration 4 (categories)
// This will:
// 1. Remove category_id from words (recreate table)
// 2. Drop categories table
// 3. Delete migration record

try migrationManager.rollback(to: 3)

// Verify:
let version = db.scalar("SELECT MAX(version) FROM schema_migrations")
print(version)  // Should be 3
```

---

## Testing Migrations

### Unit Testing Template

Create file: `RankerTests/MigrationTests.swift`

```swift
import XCTest
import SQLite
@testable import Ranker

class MigrationTests: XCTestCase {

    var testDB: Connection!
    var migrationManager: MigrationManager!

    override func setUp() {
        super.setUp()

        // Create in-memory database for testing
        testDB = try! Connection(.inMemory)
        migrationManager = MigrationManager(database: testDB)
    }

    override func tearDown() {
        testDB = nil
        migrationManager = nil
        super.tearDown()
    }

    // MARK: - Test Migration 1

    func testMigration1CreatesWordsTable() throws {
        // Run migration
        try migrationManager.migrate()

        // Verify table exists
        let tableExists = try testDB.scalar(
            "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='words'"
        ) as! Int64

        XCTAssertEqual(tableExists, 1, "words table should exist")

        // Verify schema
        let columns = try testDB.prepare("PRAGMA table_info(words)")
        let columnNames = columns.map { $0[1] as! String }

        XCTAssertTrue(columnNames.contains("id"))
        XCTAssertTrue(columnNames.contains("word"))
        XCTAssertTrue(columnNames.contains("rank"))
        XCTAssertTrue(columnNames.contains("notable"))
        XCTAssertTrue(columnNames.contains("reviewed"))
    }

    // MARK: - Test Migration 2

    func testMigration2CreatesIndexes() throws {
        try migrationManager.migrate()

        // Check indexes
        let indexes = try testDB.prepare("PRAGMA index_list(words)")
        let indexNames = indexes.map { $0[1] as! String }

        XCTAssertTrue(indexNames.contains("idx_words_reviewed"))
        XCTAssertTrue(indexNames.contains("idx_words_notable"))
    }

    // MARK: - Test Migration 3

    func testMigration3AddsTimestamps() throws {
        try migrationManager.migrate()

        // Insert test word
        try testDB.run("""
        INSERT INTO words (word, rank, notable, reviewed)
        VALUES ('test', 0.5, 0, 0)
        """)

        // Verify timestamps are set
        let result = try testDB.pluck("SELECT created_at, updated_at FROM words WHERE word='test'")
        XCTAssertNotNil(result?[0])  // created_at
        XCTAssertNotNil(result?[1])  // updated_at
    }

    // MARK: - Test Rollback

    func testRollbackMigration() throws {
        // Run all migrations
        try migrationManager.migrate()

        let versionBefore = try testDB.scalar("SELECT MAX(version) FROM schema_migrations") as! Int64
        XCTAssertGreaterThan(versionBefore, 1)

        // Rollback to version 1
        try migrationManager.rollback(to: 1)

        let versionAfter = try testDB.scalar("SELECT MAX(version) FROM schema_migrations") as! Int64
        XCTAssertEqual(versionAfter, 1)

        // Verify indexes removed
        let indexes = try testDB.prepare("PRAGMA index_list(words)")
        let indexNames = indexes.map { $0[1] as! String }
        XCTAssertFalse(indexNames.contains("idx_words_reviewed"))
    }

    // MARK: - Test Idempotency

    func testMigrationsAreIdempotent() throws {
        // Run migrations twice
        try migrationManager.migrate()
        try migrationManager.migrate()

        // Should only have each version once
        let migrationCount = try testDB.scalar(
            "SELECT COUNT(*) FROM schema_migrations"
        ) as! Int64

        let maxVersion = try testDB.scalar(
            "SELECT MAX(version) FROM schema_migrations"
        ) as! Int64

        XCTAssertEqual(migrationCount, maxVersion)
    }
}
```

---

### Integration Testing

```swift
class MigrationIntegrationTests: XCTestCase {

    func testMigrationWithRealData() throws {
        // Create test database
        let testDBPath = NSTemporaryDirectory() + "test_db.sqlite3"
        let testDB = try Connection(testDBPath)

        let manager = MigrationManager(database: testDB)

        // Populate with sample data
        try testDB.run("""
        INSERT INTO words (word, rank, notable, reviewed) VALUES
            ('abc', 0.7, 1, 1),
            ('xyz', 0.3, 0, 1),
            ('123', 0.5, 0, 0);
        """)

        // Run migration 3 (add timestamps)
        try manager.migrate()

        // Verify data preserved
        let count = try testDB.scalar("SELECT COUNT(*) FROM words") as! Int64
        XCTAssertEqual(count, 3)

        // Verify timestamps added
        let word = try testDB.pluck("SELECT * FROM words WHERE word='abc'")
        XCTAssertNotNil(word)

        // Cleanup
        try FileManager.default.removeItem(atPath: testDBPath)
    }
}
```

---

## Best Practices

### 1. Always Create Backups

```swift
// Before running any migration
private func runMigration(_ migration: Migration) throws {
    // Backup first!
    try backupDatabase()

    // Then migrate
    try migration.migrate(db!)
}
```

### 2. Use Transactions

```swift
// Wrap migrations in transactions
try db?.transaction {
    try migration.migrate(db!)
    try recordMigration(version: migration.version)
}
// If any step fails, entire migration rolls back
```

### 3. Test on Simulator First

```
Development Flow:
1. Write migration code
2. Test on iOS Simulator
3. Verify with DB Browser
4. Test rollback
5. Run unit tests
6. Deploy to TestFlight
7. Production release
```

### 4. Version Numbering

```
Use sequential integers:
  v1: Initial schema
  v2: Add indexes
  v3: Add timestamps
  v4: Add categories
  v5: Add associations

DO NOT skip versions or use dates
```

### 5. Document Every Migration

```swift
Migration(
    version: 4,
    description: "Add categories table and relationship"  // ← Clear description
) { db in
    // Include comments explaining WHY
    // Create categories table to organize words by type
    // This enables filtering and grouping in the UI
    try db.execute(createCategoriesSQL)
}
```

### 6. Handle SQLite Limitations

```swift
// SQLite doesn't support DROP COLUMN (before 3.35.0)
// Instead, recreate the table:

// Step 1: Rename old table
try db.execute("ALTER TABLE words RENAME TO words_old;")

// Step 2: Create new table with desired schema
try db.execute("CREATE TABLE words (...);")

// Step 3: Copy data
try db.execute("INSERT INTO words SELECT ... FROM words_old;")

// Step 4: Drop old table
try db.execute("DROP TABLE words_old;")
```

### 7. Provide Rollback for Every Migration

```swift
// ✅ GOOD: Includes rollback
Migration(version: 2, description: "...") { db in
    try db.execute("CREATE INDEX ...")
} rollback: { db in
    try db.execute("DROP INDEX ...")
}

// ❌ BAD: No rollback
Migration(version: 2, description: "...") { db in
    try db.execute("CREATE INDEX ...")
}
```

### 8. Test Data Preservation

```swift
// Before migration: Insert test data
// Run migration
// After migration: Verify data still exists and is correct
```

---

## Migration Checklist

### Before Migration

- [ ] Read migration code carefully
- [ ] Understand what will change
- [ ] Backup current database
- [ ] Test migration on simulator
- [ ] Verify rollback procedure works
- [ ] Run unit tests
- [ ] Check disk space (backups take space)

### During Migration

- [ ] Monitor migration logs
- [ ] Check for errors
- [ ] Verify version number increases
- [ ] Confirm schema changes applied

### After Migration

- [ ] Verify app functionality
- [ ] Check data integrity
- [ ] Test queries performance
- [ ] Confirm indexes created
- [ ] Keep backup for 7-30 days

---

## Troubleshooting

### Migration Fails Midway

```swift
// Transaction ensures atomicity
// If migration fails, database remains at previous version
// Check logs for error message
// Restore from backup if needed
```

### Rollback Not Available

```swift
// If migration doesn't have rollback:
if migration.rollback == nil {
    // Only option: Restore from backup
    try restoreFromBackup(backupPath)
}
```

### Data Loss During Migration

```swift
// Prevention:
1. Always backup before migration
2. Use transactions
3. Test thoroughly on simulator
4. Never modify migration code after it's released
```

---

## References

- SQLite ALTER TABLE: https://www.sqlite.org/lang_altertable.html
- SQLite Transactions: https://www.sqlite.org/lang_transaction.html
- Migration Best Practices: https://www.sqlite.org/schematab.html

---

**Document Version:** 1.0
**Last Updated:** 2025-11-15
**Related Documents:**
- [DATABASE_DOCUMENTATION.md](DATABASE_DOCUMENTATION.md)
- [PERFORMANCE_GUIDE.md](PERFORMANCE_GUIDE.md)
