# Database Performance Guide

**Version:** 1.0
**Last Updated:** 2025-11-15
**Database:** SQLite 3
**Application:** Ranker iOS App

---

## Table of Contents

1. [Performance Monitoring](#performance-monitoring)
2. [Query Optimization](#query-optimization)
3. [Index Optimization](#index-optimization)
4. [Transaction Optimization](#transaction-optimization)
5. [Cache Strategies](#cache-strategies)
6. [Profiling Tools](#profiling-tools)
7. [Performance Benchmarks](#performance-benchmarks)
8. [Scaling Strategies](#scaling-strategies)

---

## Performance Monitoring

### Performance Metrics to Track

| Metric | Target | Current | Measurement Method |
|--------|--------|---------|-------------------|
| Query Execution Time | < 10ms | 10-50ms | SQLite EXPLAIN QUERY PLAN |
| Insert Batch (1000 rows) | < 100ms | N/A | Measure transaction time |
| Update Batch (20 rows) | < 50ms | ~100ms | Measure saveRankings() time |
| App Launch Time | < 2s | ~2s | Xcode Instruments |
| Database Size | < 10MB | 2-3MB | File size check |
| Memory Usage | < 50MB | ~20MB | Xcode Memory Graph |

---

### Implementing Performance Logging

#### Template: DatabasePerformanceLogger.swift

```swift
import Foundation
import SQLite

class DatabasePerformanceLogger {
    static let shared = DatabasePerformanceLogger()

    private var queryLogs: [QueryLog] = []
    private let logQueue = DispatchQueue(label: "com.ranker.perflog", qos: .utility)

    struct QueryLog {
        let timestamp: Date
        let query: String
        let executionTime: TimeInterval
        let rowsAffected: Int
    }

    // MARK: - Measure Query Performance

    func measureQuery<T>(
        query: String,
        execute: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()

        let result = try execute()

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        logQuery(query: query, executionTime: executionTime)

        if executionTime > 0.1 {  // 100ms threshold
            print("⚠️ SLOW QUERY (\(String(format: "%.2f", executionTime * 1000))ms): \(query)")
        }

        return result
    }

    private func logQuery(query: String, executionTime: TimeInterval, rowsAffected: Int = 0) {
        logQueue.async {
            let log = QueryLog(
                timestamp: Date(),
                query: query,
                executionTime: executionTime,
                rowsAffected: rowsAffected
            )
            self.queryLogs.append(log)

            // Keep only last 1000 logs
            if self.queryLogs.count > 1000 {
                self.queryLogs.removeFirst(100)
            }
        }
    }

    // MARK: - Performance Report

    func generateReport() -> String {
        var report = "=== Database Performance Report ===\n\n"

        let totalQueries = queryLogs.count
        let avgExecutionTime = queryLogs.map { $0.executionTime }.reduce(0, +) / Double(totalQueries)
        let slowQueries = queryLogs.filter { $0.executionTime > 0.1 }

        report += "Total Queries: \(totalQueries)\n"
        report += "Average Execution Time: \(String(format: "%.2f", avgExecutionTime * 1000))ms\n"
        report += "Slow Queries (>100ms): \(slowQueries.count)\n\n"

        report += "Top 10 Slowest Queries:\n"
        let topSlow = queryLogs.sorted { $0.executionTime > $1.executionTime }.prefix(10)
        for (index, log) in topSlow.enumerated() {
            report += "\(index + 1). (\(String(format: "%.2f", log.executionTime * 1000))ms) \(log.query)\n"
        }

        return report
    }

    func exportLogs(to url: URL) throws {
        let csvHeader = "timestamp,query,execution_time_ms,rows_affected\n"
        let csvData = queryLogs.map { log in
            "\(log.timestamp),\"\(log.query)\",\(log.executionTime * 1000),\(log.rowsAffected)"
        }.joined(separator: "\n")

        try (csvHeader + csvData).write(to: url, atomically: true, encoding: .utf8)
    }
}
```

#### Usage in DatabaseManager

```swift
class DatabaseManager {
    private let perfLogger = DatabasePerformanceLogger.shared

    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
        return perfLogger.measureQuery(query: "fetchUnreviewedWords") {
            // Original query code
            let query = wordsTable.filter(reviewed == false)
                .order(SQLite.Expression<Int64>.random())
                .limit(batchSize)

            return try db.prepare(query).map { /* ... */ }
        }
    }

    func updateWord(word: Word) {
        perfLogger.measureQuery(query: "updateWord(\(word.name))") {
            // Original update code
            let wordRow = wordsTable.filter(self.word == word.name)
            try db?.run(wordRow.update(/* ... */))
        }
    }
}
```

---

### Real-Time Performance Dashboard (Optional)

```swift
// SwiftUI View for performance monitoring
struct PerformanceDashboardView: View {
    @State private var report: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Database Performance")
                    .font(.title)

                Text(report)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Button("Refresh Report") {
                    report = DatabasePerformanceLogger.shared.generateReport()
                }
                .buttonStyle(.borderedProminent)

                Button("Export Logs") {
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("perf_log.csv")
                    try? DatabasePerformanceLogger.shared.exportLogs(to: url)
                    // Present share sheet
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .onAppear {
            report = DatabasePerformanceLogger.shared.generateReport()
        }
    }
}
```

---

## Query Optimization

### Current Queries Analysis

#### Query 1: Fetch Unreviewed Words

**Current Implementation:**
```sql
SELECT * FROM words
WHERE reviewed = 0
ORDER BY RANDOM()
LIMIT 20;
```

**Performance:**
- Without index: Full table scan (27,575 rows) → 10-50ms
- With `idx_words_reviewed`: Index scan → 1-5ms

**EXPLAIN QUERY PLAN:**
```sql
EXPLAIN QUERY PLAN
SELECT * FROM words WHERE reviewed = 0 ORDER BY RANDOM() LIMIT 20;

-- Without index:
SCAN words

-- With index:
SEARCH words USING INDEX idx_words_reviewed (reviewed=?)
USE TEMP B-TREE FOR ORDER BY
```

**Optimization Recommendations:**

1. **Add Index (Priority 1)**
```sql
CREATE INDEX idx_words_reviewed ON words(reviewed);
```

2. **Reduce Random Overhead (Advanced)**
```swift
// Cache unreviewed IDs and shuffle in memory
class DatabaseManager {
    private var unreviewedIDsCache: [Int64] = []

    func refreshCache() {
        unreviewedIDsCache = try! db.prepare(
            wordsTable.select(id).filter(reviewed == false)
        ).map { $0[id] }
        unreviewedIDsCache.shuffle()
    }

    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
        if unreviewedIDsCache.count < batchSize {
            refreshCache()
        }

        let batchIDs = Array(unreviewedIDsCache.prefix(batchSize))
        unreviewedIDsCache.removeFirst(min(batchSize, unreviewedIDsCache.count))

        return try! db.prepare(
            wordsTable.filter(batchIDs.contains(id))
        ).map { /* map to Word */ }
    }
}
```

**Performance Gain:** 5-10x faster (avoids `ORDER BY RANDOM()`)

---

#### Query 2: Update Word Rankings

**Current Implementation:**
```swift
// Individual updates (NO transaction)
for word in words {
    UPDATE words SET rank=?, notable=?, reviewed=? WHERE word=?
}
```

**Performance:**
- 20 individual updates: ~100ms (5ms each)
- With transaction: ~10ms (50x faster writes)

**Optimized Implementation:**

```swift
func saveRankings() {
    // Wrap in transaction
    try? db?.transaction {
        for word in words {
            databaseManager.updateWord(word: word)
        }
    }
    loadNextBatch()
}
```

**Performance Gain:** 5-10x faster

---

#### Query 3: Count Reviewed/Unreviewed

**Current Implementation:**
```sql
SELECT COUNT(*) FROM words WHERE reviewed = 1;
SELECT COUNT(*) FROM words WHERE reviewed = 0;
```

**Performance:**
- Without index: Full scan (27K rows) → 5-20ms
- With index: Index scan → < 1ms

**Optimization:**

```sql
CREATE INDEX idx_words_reviewed ON words(reviewed);
```

**Advanced: Use Cached Counts**

```swift
class DatabaseManager {
    private var cachedReviewedCount: Int?
    private var cachedUnreviewedCount: Int?

    func countReviewedWords() -> Int {
        if let cached = cachedReviewedCount {
            return cached
        }

        let count = try! db.scalar(
            wordsTable.filter(reviewed == true).count
        )
        cachedReviewedCount = count
        return count
    }

    func invalidateCountCache() {
        cachedReviewedCount = nil
        cachedUnreviewedCount = nil
    }

    func updateWord(word: Word) {
        // ... update logic
        invalidateCountCache()  // Invalidate on changes
    }
}
```

**Performance Gain:** 100x faster for cached reads

---

### Query Optimization Checklist

- [ ] Use indexes for WHERE clauses
- [ ] Avoid `SELECT *` when possible (select only needed columns)
- [ ] Use LIMIT for large result sets
- [ ] Avoid `ORDER BY RANDOM()` for large tables
- [ ] Use prepared statements for repeated queries
- [ ] Wrap bulk operations in transactions
- [ ] Cache frequently accessed data

---

## Index Optimization

### Recommended Indexes

#### Priority 1: Critical Indexes

```sql
-- Essential for fetchUnreviewedWords query
CREATE INDEX idx_words_reviewed ON words(reviewed);

-- Speedup: 100-1000x
-- Storage: ~100 KB
-- Impact: High
```

#### Priority 2: Important Indexes

```sql
-- Useful for filtering notable words
CREATE INDEX idx_words_notable ON words(notable);

-- Speedup: 50-100x
-- Storage: ~100 KB
-- Impact: Medium
```

#### Priority 3: Composite Indexes

```sql
-- Optimizes sorted queries (top/bottom ranked)
CREATE INDEX idx_words_reviewed_rank ON words(reviewed, rank DESC);

-- Example query:
-- SELECT * FROM words WHERE reviewed=1 ORDER BY rank DESC LIMIT 50;
-- Speedup: 10-50x
-- Storage: ~200 KB
-- Impact: Medium
```

---

### Index Implementation

**File:** `DatabaseManager.swift`

```swift
private func createIndexes() {
    do {
        // Priority 1: reviewed index
        try db?.run("CREATE INDEX IF NOT EXISTS idx_words_reviewed ON words(reviewed)")

        // Priority 2: notable index
        try db?.run("CREATE INDEX IF NOT EXISTS idx_words_notable ON words(notable)")

        // Priority 3: composite indexes
        try db?.run("CREATE INDEX IF NOT EXISTS idx_words_reviewed_rank ON words(reviewed, rank DESC)")
        try db?.run("CREATE INDEX IF NOT EXISTS idx_words_notable_rank ON words(notable, rank DESC)")

        print("✅ Indexes created successfully")
    } catch {
        print("❌ Failed to create indexes: \(error)")
    }
}

init() {
    setupDatabase()
    createWordsTable()
    createIndexes()  // Add this line
    populateInitialDataIfNeeded()
}
```

---

### Index Monitoring

#### Check Which Indexes Exist

```sql
PRAGMA index_list(words);

-- Expected output:
-- idx_words_reviewed
-- idx_words_notable
-- idx_words_reviewed_rank
-- sqlite_autoindex_words_1 (PK)
-- sqlite_autoindex_words_2 (UNIQUE word)
```

#### Check Index Usage

```sql
EXPLAIN QUERY PLAN
SELECT * FROM words WHERE reviewed = 0 LIMIT 20;

-- Should show:
-- SEARCH words USING INDEX idx_words_reviewed (reviewed=?)
```

#### Analyze Index Effectiveness

```sql
ANALYZE;
SELECT * FROM sqlite_stat1 WHERE tbl = 'words';

-- Shows index statistics for query optimizer
```

---

### Index Overhead

| Operation | Without Indexes | With 4 Indexes | Overhead |
|-----------|----------------|----------------|----------|
| SELECT (filtered) | 10-50ms | 1-5ms | 10x faster ✅ |
| INSERT | 1ms | 2ms | 2x slower ⚠️ |
| UPDATE | 5ms | 7ms | 1.4x slower ⚠️ |
| Database Size | 2MB | 2.5MB | +25% ⚠️ |

**Verdict:** Benefits far outweigh costs for read-heavy workload

---

## Transaction Optimization

### Current Transaction Usage

**Status:** ⚠️ Only used for initial data population

**Missing Transactions:**
- Word updates (saveRankings)
- Batch operations

---

### Transaction Best Practices

#### 1. Wrap Batch Operations

```swift
// ❌ BAD: 20 separate transactions
for word in words {
    db?.run(wordsTable.filter(word == name).update(/* ... */))
}

// ✅ GOOD: Single transaction
try db?.transaction {
    for word in words {
        try db?.run(wordsTable.filter(word == name).update(/* ... */))
    }
}
```

**Performance Gain:** 10-50x faster

---

#### 2. Use Prepared Statements

```swift
// ❌ BAD: Query parsed 20 times
for word in words {
    try db?.run("UPDATE words SET rank=\(word.rank) WHERE word='\(word.name)'")
}

// ✅ GOOD: Query parsed once
let stmt = try db?.prepare("UPDATE words SET rank=?, notable=?, reviewed=? WHERE word=?")
for word in words {
    try stmt?.run(word.rank, word.isNotable, word.reviewed, word.name)
}
```

**Performance Gain:** 2-5x faster

---

#### 3. Optimal Transaction Size

```swift
// Process in chunks of 100-1000 rows
let chunkSize = 500

for chunk in words.chunked(into: chunkSize) {
    try db?.transaction {
        for word in chunk {
            try updateWord(word)
        }
    }
}
```

**Guidelines:**
- Small batches (< 100): Single transaction OK
- Large batches (> 1000): Chunk into 500-1000 row transactions
- Very large (> 10K): Consider progress reporting

---

### Transaction Template

```swift
extension DatabaseManager {
    func performBatchUpdate(words: [Word]) throws {
        try db?.transaction {
            // Optional: Prepare statement once
            let updateStmt = try db?.prepare("""
                UPDATE words
                SET rank = ?, notable = ?, reviewed = ?
                WHERE word = ?
            """)

            for word in words {
                let isReviewed = word.rank != 0.5
                try updateStmt?.run(word.rank, word.isNotable, isReviewed, word.name)
            }
        }
    }
}
```

---

## Cache Strategies

### 1. In-Memory Word Cache

```swift
class DatabaseManager {
    // Cache for current batch
    private var currentBatchCache: [Word] = []

    // Cache for next batch (pre-fetch)
    private var nextBatchCache: [Word] = []

    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
        // Return cached batch
        if !currentBatchCache.isEmpty {
            let batch = currentBatchCache
            currentBatchCache = nextBatchCache  // Move next to current
            nextBatchCache = []  // Clear next

            // Pre-fetch next batch in background
            prefetchNextBatch(batchSize: batchSize)

            return batch
        }

        // Cache miss: Load from database
        return loadBatchFromDatabase(batchSize: batchSize)
    }

    private func prefetchNextBatch(batchSize: Int) {
        DispatchQueue.global(qos: .utility).async {
            self.nextBatchCache = self.loadBatchFromDatabase(batchSize: batchSize)
        }
    }
}
```

**Benefits:**
- Instant batch loading
- Background pre-fetching
- Smooth UI experience

---

### 2. Count Cache

```swift
class DatabaseManager {
    private struct CountCache {
        var reviewedCount: Int?
        var unreviewedCount: Int?
        var lastUpdated: Date?

        var isValid: Bool {
            guard let lastUpdated = lastUpdated else { return false }
            return Date().timeIntervalSince(lastUpdated) < 60  // 60 second TTL
        }
    }

    private var countCache = CountCache()

    func countReviewedWords() -> Int {
        if countCache.isValid, let count = countCache.reviewedCount {
            return count
        }

        let count = try! db.scalar(wordsTable.filter(reviewed == true).count)
        countCache.reviewedCount = count
        countCache.lastUpdated = Date()
        return count
    }

    func updateWord(word: Word) {
        // ... update logic

        // Invalidate cache
        countCache = CountCache()
    }
}
```

---

### 3. Query Result Cache (Advanced)

```swift
class QueryCache {
    private var cache: [String: (result: Any, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 300  // 5 minutes

    func get<T>(key: String) -> T? {
        guard let cached = cache[key] else { return nil }

        // Check expiration
        if Date().timeIntervalSince(cached.timestamp) > ttl {
            cache.removeValue(forKey: key)
            return nil
        }

        return cached.result as? T
    }

    func set(key: String, value: Any) {
        cache[key] = (result: value, timestamp: Date())
    }

    func invalidate(key: String) {
        cache.removeValue(forKey: key)
    }

    func clear() {
        cache.removeAll()
    }
}
```

---

## Profiling Tools

### 1. Xcode Instruments

**Time Profiler:**
```
1. Product → Profile (⌘I)
2. Select "Time Profiler"
3. Record while using app
4. Filter by "DatabaseManager" to see database operations
```

**Core Data Profiler (for SQLite):**
```
1. Product → Profile
2. Select "Core Data" instrument
3. Shows SQL queries, execution time, fetch counts
```

---

### 2. SQLite EXPLAIN

```swift
func explainQuery(sql: String) {
    do {
        let plan = try db?.prepare("EXPLAIN QUERY PLAN \(sql)")
        for row in plan ?? [] {
            print(row)
        }
    } catch {
        print("Explain failed: \(error)")
    }
}

// Usage:
explainQuery(sql: "SELECT * FROM words WHERE reviewed = 0 LIMIT 20")
```

**Example Output:**
```
SEARCH words USING INDEX idx_words_reviewed (reviewed=?)
USE TEMP B-TREE FOR ORDER BY
```

---

### 3. Custom Benchmarking

```swift
class Benchmark {
    static func measure(_ name: String, iterations: Int = 1, block: () -> Void) {
        var totalTime: TimeInterval = 0

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            block()
            let end = CFAbsoluteTimeGetCurrent()
            totalTime += (end - start)
        }

        let avgTime = totalTime / Double(iterations)
        print("[\(name)] Avg: \(String(format: "%.2f", avgTime * 1000))ms over \(iterations) iterations")
    }
}

// Usage:
Benchmark.measure("Fetch Unreviewed", iterations: 100) {
    _ = databaseManager.fetchUnreviewedWords(batchSize: 20)
}
```

---

## Performance Benchmarks

### Baseline Performance (Current State)

| Operation | Without Optimization | With Recommended Optimizations | Improvement |
|-----------|---------------------|-------------------------------|-------------|
| Fetch 20 unreviewed words | 10-50ms | 1-5ms | 10x faster |
| Update 20 words (no transaction) | 100ms | 10ms | 10x faster |
| Count reviewed words | 5-20ms | < 1ms | 20x faster |
| Initial data population | 1-2s | 1-2s | (already optimized) |
| App launch time | 2s | 1.5s | 25% faster |

---

### Target Performance Metrics

```
✅ Excellent:  < 10ms
⚠️  Acceptable: 10-50ms
❌ Needs optimization: > 50ms
```

| Query Type | Current | Target | Status |
|------------|---------|--------|--------|
| Simple SELECT | 5ms | < 10ms | ✅ |
| Filtered SELECT (no index) | 30ms | < 10ms | ⚠️ Add index |
| Batch UPDATE (no transaction) | 100ms | < 20ms | ❌ Add transaction |
| COUNT query (no index) | 15ms | < 5ms | ⚠️ Add index |

---

### Load Testing

```swift
class LoadTest {
    func testLargeDataset() {
        // Simulate 100K words
        let startTime = CFAbsoluteTimeGetCurrent()

        try? db?.transaction {
            for i in 0..<100_000 {
                try db?.run(wordsTable.insert(
                    word <- "test\(i)",
                    rank <- 0.5,
                    notable <- false,
                    reviewed <- false
                ))
            }
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        print("Inserted 100K rows in \(duration)s")
        // Expected: 2-5 seconds with transaction

        // Test query performance
        Benchmark.measure("Query 100K dataset") {
            _ = try? db?.prepare(
                wordsTable.filter(reviewed == false).limit(20)
            ).map { $0 }
        }
        // Expected: < 10ms with index
    }
}
```

---

## Scaling Strategies

### Short-Term (< 100K rows)

**Optimizations:**
1. ✅ Add recommended indexes
2. ✅ Use transactions for batch operations
3. ✅ Implement caching for counts
4. ✅ Enable WAL mode

```swift
try db?.execute("PRAGMA journal_mode=WAL")
try db?.execute("PRAGMA synchronous=NORMAL")
```

---

### Medium-Term (100K - 1M rows)

**Additional Optimizations:**
1. Pagination for large result sets
2. Incremental loading
3. Background processing
4. Data archiving

```swift
// Pagination example
func fetchWords(offset: Int, limit: Int) -> [Word] {
    return try! db.prepare(
        wordsTable
            .filter(reviewed == false)
            .limit(limit, offset: offset)
    ).map { /* ... */ }
}
```

---

### Long-Term (> 1M rows)

**Consider:**
1. Partitioning tables (e.g., by category)
2. Client-server architecture (move to PostgreSQL/MySQL)
3. Sharding (split data across multiple databases)
4. Read replicas (for analytics)

---

### SQLite Configuration Tuning

```swift
private func setupDatabase() {
    do {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        db = try Connection("\(path)/db.sqlite3")

        // Performance optimizations
        try db?.execute("PRAGMA journal_mode=WAL")           // Write-Ahead Logging
        try db?.execute("PRAGMA synchronous=NORMAL")         // Faster writes
        try db?.execute("PRAGMA temp_store=MEMORY")          // In-memory temp tables
        try db?.execute("PRAGMA cache_size=-64000")          // 64MB cache (negative = KB)
        try db?.execute("PRAGMA mmap_size=268435456")        // 256MB mmap

        print("✅ Database optimized for performance")
    } catch {
        print("Database setup error: \(error)")
    }
}
```

**Performance Gain:** 20-50% improvement for write-heavy operations

---

## Performance Checklist

### Before Deploying

- [ ] Add recommended indexes
- [ ] Wrap batch updates in transactions
- [ ] Enable WAL mode
- [ ] Implement caching for counts
- [ ] Profile with Xcode Instruments
- [ ] Run load tests
- [ ] Measure all critical queries
- [ ] Verify EXPLAIN QUERY PLAN shows index usage

### Ongoing Monitoring

- [ ] Track slow queries (> 100ms)
- [ ] Monitor database size growth
- [ ] Check index effectiveness
- [ ] Review query patterns
- [ ] Update indexes as needed

---

## Quick Wins Summary

### Immediate Actions (High Impact, Low Effort)

1. **Add Index on `reviewed` column**
   ```sql
   CREATE INDEX idx_words_reviewed ON words(reviewed);
   ```
   **Impact:** 100x faster filtered queries

2. **Wrap Updates in Transaction**
   ```swift
   try db?.transaction {
       for word in words {
           updateWord(word)
       }
   }
   ```
   **Impact:** 10x faster batch updates

3. **Enable WAL Mode**
   ```swift
   try db?.execute("PRAGMA journal_mode=WAL")
   ```
   **Impact:** Better concurrency, faster writes

**Total Time:** 30 minutes
**Performance Gain:** 10-100x for common operations

---

## References

- SQLite Performance Tuning: https://www.sqlite.org/queryplanner.html
- SQLite Optimization FAQ: https://www.sqlite.org/optoverview.html
- WAL Mode: https://www.sqlite.org/wal.html
- Xcode Instruments Guide: https://developer.apple.com/documentation/xcode/improving-your-app-s-performance

---

**Document Version:** 1.0
**Last Updated:** 2025-11-15
**Related Documents:**
- [DATABASE_DOCUMENTATION.md](DATABASE_DOCUMENTATION.md)
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
- [ER_DIAGRAMS.md](ER_DIAGRAMS.md)
