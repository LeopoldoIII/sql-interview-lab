# Query Creation & Optimization Standards

When authoring, refactoring, or explaining queries in this repository, enforce these cross-technology standards:

## 1. Universal Query Anatomy
Every new practice query or interview solution added to the repository must include:
- **Problem Statement Header:** Clear comment stating the business question and interview difficulty level.
- **Complexity & Pattern Tag:** Identify the core pattern used (e.g., `Window Function: DENSE_RANK`, `Anti-Join: NOT EXISTS`, `Aggregation Pipeline: $lookup + $unwind`, `Sorted Set Leaderboard: O(log N)`).
- **Edge-Case Coverage:** Explicitly note how the query handles `NULL` values, empty groups (e.g., `'Marketing'` department), or ties (e.g., Department 2 salaries).

## 2. Engine-Specific Checklist
- **PostgreSQL 16:**
  - Never use `SELECT *` in solutions.
  - Always use explicit `JOIN` clauses and concise table aliases.
  - Use SARGable predicates in `WHERE` and `JOIN` conditions.
  - Prefer `NOT EXISTS` over `NOT IN` for nullable columns.
  - Use `COUNT(pk_column)` instead of `COUNT(*)` on `LEFT JOIN` queries.
- **MongoDB 7.0:**
  - Place `$match` and `$sort` at the start of `.aggregate([])` pipelines.
  - Follow the **ESR (Equality, Sort, Range)** rule when proposing compound indexes.
  - Project only required fields (`_id: 0` when `_id` is not needed).
- **Redis 7:**
  - Use `<entity>:<id>:<attribute>` colon-separated key naming.
  - Always specify TTL (`EX` / `PX`) for cache, session, and lock keys.
  - Never use `KEYS *`; use `SCAN` or dedicated Set/Sorted Set indexes.
- **GraphQL (PostGraphile):**
  - Always name operations (`query OperationName`, `mutation OperationName`).
  - Always use `$variables` for dynamic inputs; never interpolate strings.
  - Always paginate or bound collections (`first: N`) and reuse fields with `fragment`.

