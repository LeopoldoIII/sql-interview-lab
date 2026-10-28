---
name: mongodb-aggregation-mastery
description: >-
  Use this skill whenever creating, refactoring, or optimizing MongoDB 7.0 queries,
  Aggregation Framework pipelines, document projections, or ESR compound indexes
  in this project.
---

# MongoDB 7.0 & Aggregation Mastery

Follow this workflow whenever authoring or reviewing MongoDB queries in [`mongo_practice.js`](../../mongo_practice.js), [`mongo_init/01_init_nosql.js`](../../mongo_init/01_init_nosql.js), or [`docs/NOSQL_GUIDE.md`](../../docs/NOSQL_GUIDE.md).

> **Language Rule:** All JavaScript/Mongosh queries, field aliases, comments, and explanations MUST be written in **English**.

---

## 1. Step-by-Step MongoDB Query & Pipeline Workflow

1. **Choose `.find()` vs `.aggregate()`:**
   - Use `db.collection.find(filter, projection).sort(...)` for single-collection document retrieval and field projection.
   - Use `db.collection.aggregate([...])` for grouping (`$group`), cross-collection joins (`$lookup`), array unwinding (`$unwind`), multi-faceted analytics (`$facet`), or computed transformations (`$addFields` / `$set`).
2. **Optimize Pipeline Stage Sequence:**
   - **Stage 1 (`$match`):** Always filter as early as possible so MongoDB uses an index scan (`IXSCAN`) and minimizes documents entering the pipeline.
   - **Stage 2 (`$sort` / `$limit`):** Place `$sort` immediately after `$match` when an index supports the sort order, and coalesce `$sort` + `$limit` for top-K efficiency.
   - **Stage 3 (`$project` / `$unset`):** Strip unneeded heavy fields early if subsequent stages involve `$lookup` or `$unwind`.
   - **Stage 4 (`$lookup` / `$unwind` / `$group`):** Perform joins and aggregations on the reduced dataset.
3. **Design Indexes Using the ESR Rule:**
   - Whenever recommending an index, order keys by **E**quality $\rightarrow$ **S**ort $\rightarrow$ **R**ange.
4. **Verify Against `nosql_interview_mongo`:**
   - Run queries and inspect `.explain("executionStats")` via [`sandbox-query-runner`](../sandbox-query-runner/SKILL.md):
     ```bash
     bash .agents/skills/sandbox-query-runner/scripts/run_query.sh mongo "db.employees.find({ status: 'Active' }).explain('executionStats')"
     ```

---

## 2. Deep Reference Manual

For detailed patterns on the ESR indexing rule, sub-pipeline `$lookup`, array filtering (`$elemMatch` vs `$filter`), and `$facet` analytics, read:
- [MongoDB Pipeline & Indexing Patterns](./references/mongodb-pipeline-patterns.md)

