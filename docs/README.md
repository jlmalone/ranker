# Ranker Database Documentation

**Version:** 1.0
**Last Updated:** 2025-11-15
**Status:** ✅ Complete

---

## Overview

This directory contains comprehensive documentation for the Ranker application's database architecture, schema, migrations, performance optimization, and integration patterns.

**Database System:** SQLite 3
**ORM Framework:** SQLite.swift 0.15.0+
**Platform:** iOS

---

## Documentation Index

### 📚 Core Documentation

#### [DATABASE_DOCUMENTATION.md](DATABASE_DOCUMENTATION.md)
**Comprehensive database schema documentation** covering all aspects of the database.

**Contents:**
- Complete schema documentation with ER diagrams
- Table definitions (all columns, types, constraints)
- Indexes and constraints
- Relationships and foreign keys
- **58+ sample queries** for common operations
- Migration strategy documentation
- Performance considerations
- Integration patterns
- Backup and recovery procedures

**When to use:** Primary reference for understanding the database structure and writing queries.

---

#### [ER_DIAGRAMS.md](ER_DIAGRAMS.md)
**Visual entity-relationship diagrams and data flow documentation.**

**Contents:**
- Current schema ER diagrams (Mermaid + ASCII)
- Detailed table structure visualizations
- Data type mappings (Swift ↔ SQLite)
- Future schema proposals with ER diagrams
  - Timestamps proposal
  - Categories proposal
  - Word associations proposal
  - Audio notes proposal
- Complete future schema visualization
- Data flow diagrams
- Index visualization
- Database statistics

**When to use:** Visual reference for understanding table relationships and data flows.

---

#### [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
**Complete migration system implementation guide with templates.**

**Contents:**
- Migration system overview
- **Migration templates** (ready to implement)
  - MigrationManager.swift (complete implementation)
  - Migrations.swift (5 example migrations)
- Step-by-step migration examples
  - v1→v2: Adding indexes
  - v2→v3: Adding timestamps
  - v3→v4: Adding categories
- Rollback procedures
- Testing migrations (unit & integration tests)
- Best practices and troubleshooting

**When to use:** When implementing schema changes or version upgrades.

---

#### [PERFORMANCE_GUIDE.md](PERFORMANCE_GUIDE.md)
**Database performance monitoring and optimization guide.**

**Contents:**
- Performance monitoring implementation
  - DatabasePerformanceLogger (complete code)
  - Real-time performance dashboard
- Query optimization strategies
  - Current query analysis
  - Optimization recommendations
  - Before/after comparisons
- Index optimization
  - Recommended indexes with priorities
  - Index monitoring
  - Overhead analysis
- Transaction optimization
- Cache strategies (3 different approaches)
- Profiling tools (Xcode Instruments, EXPLAIN, benchmarking)
- Performance benchmarks
- Scaling strategies (short/medium/long-term)
- **Quick wins summary** (30-min high-impact optimizations)

**When to use:** When optimizing database performance or troubleshooting slow queries.

---

## Quick Start Guide

### For New Developers

1. **Start here:** [DATABASE_DOCUMENTATION.md](DATABASE_DOCUMENTATION.md)
   - Understand the schema
   - Review sample queries
   - Learn integration patterns

2. **Visual learner?** [ER_DIAGRAMS.md](ER_DIAGRAMS.md)
   - See the schema visually
   - Understand data flows
   - Preview future architecture

3. **Making changes?** [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
   - Follow migration templates
   - Test thoroughly
   - Document your changes

4. **Performance issues?** [PERFORMANCE_GUIDE.md](PERFORMANCE_GUIDE.md)
   - Implement quick wins first
   - Add recommended indexes
   - Profile and monitor

---

## Current Schema Summary

### Tables

**`words`** - Main table for storing ranked words/strings

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INT64 | PK, AUTOINCREMENT | Unique identifier |
| `word` | STRING | UNIQUE, NOT NULL | Word/string being ranked |
| `rank` | DOUBLE | NOT NULL | User's ranking (0.0-1.0) |
| `notable` | BOOL | DEFAULT: false | Star/favorite flag |
| `reviewed` | BOOL | DEFAULT: false | Has been reviewed |

**Total Records:** ~27,575 (17,576 3-letter combos + 9,999 numbers)
**Database Size:** 2-3 MB

### Indexes

- ✅ PRIMARY KEY (`id`)
- ✅ UNIQUE (`word`)
- ⚠️ **Recommended but not yet implemented:**
  - `idx_words_reviewed` (reviewed)
  - `idx_words_notable` (notable)
  - `idx_words_reviewed_rank` (reviewed, rank)

---

## Quick Reference: Common Queries

### Get Random Unreviewed Words
```sql
SELECT * FROM words
WHERE reviewed = 0
ORDER BY RANDOM()
LIMIT 20;
```

### Update Word Rank
```sql
UPDATE words
SET rank = ?, notable = ?, reviewed = ?
WHERE word = ?;
```

### Count Progress
```sql
SELECT COUNT(*) FROM words WHERE reviewed = 1;  -- Reviewed
SELECT COUNT(*) FROM words WHERE reviewed = 0;  -- Unreviewed
```

### Get Top Ranked Words
```sql
SELECT * FROM words
WHERE reviewed = 1
ORDER BY rank DESC
LIMIT 50;
```

**For 50+ more queries, see:** [DATABASE_DOCUMENTATION.md](DATABASE_DOCUMENTATION.md#sample-queries)

---

## Success Criteria

✅ **Schema Documentation**
- [x] ER diagrams for all databases
- [x] Complete table definitions
- [x] All columns, types, constraints documented
- [x] Relationships documented (none currently exist)

✅ **Sample Queries**
- [x] 50+ example queries documented
- [x] Common operations covered
- [x] Advanced queries included
- [x] Maintenance queries included

✅ **Migration Documentation**
- [x] Migration strategy documented
- [x] Version history documented
- [x] Rollback procedures documented
- [x] Migration templates provided

✅ **Performance Documentation**
- [x] Index usage and rationale
- [x] Query optimization notes
- [x] Scaling considerations
- [x] Backup and recovery procedures

✅ **Integration Documentation**
- [x] How applications use the database
- [x] Common query patterns
- [x] Transaction boundaries
- [x] Concurrency handling

---

## Implementation Recommendations

### Priority 1: Quick Wins (Immediate)

**Time Required:** 30 minutes
**Impact:** 10-100x performance improvement

1. **Add Performance Indexes**
   ```sql
   CREATE INDEX idx_words_reviewed ON words(reviewed);
   CREATE INDEX idx_words_notable ON words(notable);
   ```

2. **Wrap Updates in Transactions**
   ```swift
   try db?.transaction {
       for word in words {
           updateWord(word)
       }
   }
   ```

3. **Enable WAL Mode**
   ```swift
   try db?.execute("PRAGMA journal_mode=WAL")
   ```

**Expected Results:**
- Fetch queries: 10-50ms → 1-5ms
- Batch updates: 100ms → 10ms
- Count queries: 5-20ms → <1ms

---

### Priority 2: Migration System (Next Sprint)

**Time Required:** 4-6 hours
**Impact:** Enables safe schema evolution

1. Implement `MigrationManager.swift` from [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md#template-1-basic-migration-manager)
2. Implement `Migrations.swift` with baseline migration
3. Add unit tests for migrations
4. Document in-app migration status

---

### Priority 3: Performance Monitoring (Future)

**Time Required:** 2-3 hours
**Impact:** Enables data-driven optimization

1. Implement `DatabasePerformanceLogger` from [PERFORMANCE_GUIDE.md](PERFORMANCE_GUIDE.md#template-databaseperformanceloggerswift)
2. Add performance dashboard view
3. Set up alerting for slow queries (>100ms)
4. Export performance logs for analysis

---

## File Structure

```
docs/
├── README.md                    # This file (index)
├── DATABASE_DOCUMENTATION.md    # Comprehensive schema docs
├── ER_DIAGRAMS.md              # Visual diagrams
├── MIGRATION_GUIDE.md          # Migration implementation
└── PERFORMANCE_GUIDE.md        # Performance optimization
```

---

## Contributing to Documentation

When updating the database or documentation:

1. **Schema Changes:**
   - Update [DATABASE_DOCUMENTATION.md](DATABASE_DOCUMENTATION.md) schema section
   - Update [ER_DIAGRAMS.md](ER_DIAGRAMS.md) diagrams
   - Create migration in [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
   - Increment version number

2. **New Queries:**
   - Add to [DATABASE_DOCUMENTATION.md](DATABASE_DOCUMENTATION.md#sample-queries)
   - Include explanation and use case
   - Test query performance

3. **Performance Changes:**
   - Document in [PERFORMANCE_GUIDE.md](PERFORMANCE_GUIDE.md)
   - Include before/after benchmarks
   - Update recommendations

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-15 | Initial comprehensive documentation | AI Assistant |
| - | - | - Database schema docs | - |
| - | - | - ER diagrams | - |
| - | - | - Migration guide | - |
| - | - | - Performance guide | - |
| - | - | - 58+ example queries | - |

---

## Maintenance

**Review Schedule:**
- **Monthly:** Check for outdated information
- **After schema changes:** Update all relevant docs
- **After major features:** Add new query examples
- **Quarterly:** Review and update performance benchmarks

**Next Review:** 2026-02-15

---

## Support

For questions or clarifications:

1. Check the specific documentation file
2. Review code comments in `DatabaseManager.swift`
3. Consult SQLite documentation: https://www.sqlite.org/docs.html
4. Review SQLite.swift docs: https://github.com/stephencelis/SQLite.swift

---

## License

This documentation is part of the Ranker project and follows the same license as the main application.

---

**Last Updated:** 2025-11-15
**Documentation Status:** ✅ Complete and ready for use
