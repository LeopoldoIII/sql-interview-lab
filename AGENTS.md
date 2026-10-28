# AGENTS.md — Database & SQL Interview Practice Lab

This file defines the global workspace rules, architectural standards, query engineering best practices, specialized agents, and skills for the **Database & SQL Interview Practice Lab**.

---

## 🌐 1. Strict English-Only Policy (Mandatory)

- **Always Respond and Write in English:** Regardless of the language used by the user during any interaction (e.g., Spanish, Portuguese, French), **all** outputs MUST be written strictly in **English**.
- **Scope of Enforcement:**
  - All natural language responses and explanations in chat.
  - All SQL, MongoDB (MQL), Redis, and GraphQL queries, aliases, CTE names, and identifiers.
  - All inline code comments, documentation (`README.md`, `docs/*.md`), commit messages, and test cases.
  - All database schema objects (tables, columns, collections, fields, Redis keys, GraphQL types) and seed data descriptions.

---

## 🏗️ 2. Project Architecture & Sandbox Environment

This repository is a multi-engine containerized database sandbox orchestrated via [`docker-compose.yml`](docker-compose.yml):

| Engine | Version | Container Name | Port / Web GUI | Database / Schema | Init & Practice Files |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** | `16-alpine` | `sql_interview_postgres` | `5432` / PGWeb: `http://localhost:8081` | `interview_db` (`public`) | [`sql_init/01_schema_and_data.sql`](sql_init/01_schema_and_data.sql), [`sql_practice.sql`](sql_practice.sql), [`docs/SQL_GUIDE.md`](docs/SQL_GUIDE.md) |
| **MongoDB** | `7.0` | `nosql_interview_mongo` | `27017` | `interview_nosql` | [`mongo_init/01_init_nosql.js`](mongo_init/01_init_nosql.js), [`mongo_practice.js`](mongo_practice.js), [`docs/NOSQL_GUIDE.md`](docs/NOSQL_GUIDE.md) |
| **Redis** | `7-alpine` | `cache_interview_redis` | `6379` / RedisInsight: `http://localhost:5540` | Keyspace `0` | [`redis_init/01_init.redis`](redis_init/01_init.redis), [`redis_practice.redis`](redis_practice.redis), [`docs/REDIS_GUIDE.md`](docs/REDIS_GUIDE.md) |
| **PostGraphile** | `v4` | `sql_interview_graphql` | `http://localhost:5000/graphiql` | Inspects `interview_db` | [`graphql_practice.graphql`](graphql_practice.graphql), [`docs/GRAPHQL_GUIDE.md`](docs/GRAPHQL_GUIDE.md) |

### Built-In Schema Edge Cases (Always Account for These)
1. **PostgreSQL (`interview_db`)**:
   - `departments`: Department `'Marketing'` (`department_id = 5`) has **0 employees** (tests `LEFT JOIN`, `COUNT(e.employee_id)` vs `COUNT(*)`, and `NOT EXISTS` anti-joins).
   - `employees`: Department `2` (`'Data & Analytics'`) has **tied salaries** (`75000.00` for María Rodríguez and Javier López) to test `ROW_NUMBER()` vs `RANK()` vs `DENSE_RANK()`.
   - `employees`: Top-level leaders have `manager_id IS NULL` (tests hierarchical self-joins, `COALESCE`, and `NOT IN` NULL traps).
   - `sales`: Not all employees have sales records (tests `LEFT JOIN` + `COALESCE(SUM(s.amount), 0.00)`).
2. **MongoDB (`interview_nosql`)**:
   - Collections: `employees` (with `skills` array and nested `address` object), `projects` (referencing `lead_employee_id`), and `activity_logs`.

---

## ⚡ 3. Golden Rules for Creating Optimal Queries

### A. PostgreSQL 16 (Relational SQL)
1. **Explicit Column Projection:** Never use `SELECT *` in production or solution queries; project only required columns with meaningful aliases.
2. **Explicit Table Aliases & Joins:** Always use short, semantic table aliases (`e` for `employees`, `d` for `departments`, `s` for `sales`) and explicit `INNER JOIN` / `LEFT JOIN` syntax (never comma joins).
3. **SARGable Predicates:** Keep indexed columns clean on the left side of comparison operators. Avoid wrapping columns in functions inside `WHERE` clauses (e.g., use `hire_date >= '2022-01-01' AND hire_date < '2023-01-01'` instead of `EXTRACT(YEAR FROM hire_date) = 2022`).
4. **CTEs vs Subqueries:** Prefer Common Table Expressions (`WITH ... AS`) in `PascalCase` or `snake_case` for multi-step logic, readability, and recursive hierarchy traversal.
5. **NULL-Safe Anti-Joins & Counts:**
   - Prefer `NOT EXISTS` or `LEFT JOIN ... WHERE right_table.pk IS NULL` over `NOT IN` (since `NOT IN` returns zero rows if the subquery contains any `NULL`).
   - In `LEFT JOIN` aggregations, always use `COUNT(child.pk)` instead of `COUNT(*)` and wrap sums with `COALESCE(SUM(col), 0)`.
6. **Window Functions for Ranking & Top-N:** Default to `DENSE_RANK()` when asked for "Top N salaries" unless specific tie-skipping (`RANK()`) or arbitrary tie-breaking (`ROW_NUMBER()`) is requested.
7. **Execution Plan Verification:** Validate complex queries with `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` to inspect Seq Scans vs Index Scans, join algorithms (Hash Join, Nested Loop, Merge Join), and sort costs.

### B. MongoDB 7.0 (NoSQL & Aggregation Framework)
1. **Pipeline Stage Ordering:** Push `$match` and `$sort` to the **earliest** possible stage in `db.collection.aggregate([...])` so MongoDB can leverage indexes and reduce document volume before `$unwind`, `$lookup`, or `$group`.
2. **ESR Indexing Rule:** Design compound indexes following the **Equality -> Sort -> Range (ESR)** order.
3. **Projection Discipline:** Restrict returned fields via projections (`{ _id: 0, field: 1 }`) or `$project` / `$unset` to minimize wire payload and aim for covered queries.
4. **Safe Array & Subdocument Operations:** Use dot notation (`"address.city"`) for embedded documents, `$elemMatch` for multi-condition array filtering, and `$addToSet` for idempotent array updates.
5. **Avoid Unbounded `$unwind` When Possible:** If filtering or aggregating an array inside a single document suffices, prefer array expressions (`$filter`, `$size`, `$sum`) before resorting to `$unwind` + `$group`.
6. **Performance Verification:** Append `.explain("executionStats")` to inspect `totalDocsExamined` vs `totalKeysExamined` and verify `IXSCAN` over `COLLSCAN`.

### C. Redis 7 (In-Memory Data Structures & Caching)
1. **Hierarchical Key Naming:** Always use colon-delimited namespaces: `<domain>:<entity_id>:<attribute>` (e.g., `employee:101:profile`, `user:101:session`, `leaderboard:sales:monthly`).
2. **Mandatory TTL Policy:** Every ephemeral cache key, session token, or idempotency lock MUST include an expiration (`SET key val EX seconds` or `SET key val NX EX seconds`).
3. **Right Data Structure for Time Complexity:**
   - **Strings (`SET`/`GET`/`INCR`):** $O(1)$ counters, sessions, distributed locks (`SET ... NX EX`).
   - **Hashes (`HSET`/`HGET`/`HINCRBY`):** $O(1)$ field-level access on structured entities without serializing/deserializing full JSON blobs.
   - **Lists (`LPUSH`/`RPOP`/`BLPOP`):** $O(1)$ FIFO/LIFO task queues and bounded recent-activity buffers (`LTRIM`).
   - **Sets (`SADD`/`SISMEMBER`/`SINTER`):** $O(1)$ membership checks and set intersections (e.g., shared skills).
   - **Sorted Sets (`ZADD`/`ZREVRANGE`/`ZREVRANK`):** $O(\log N)$ real-time leaderboards and sliding-window rate limiters.
   - **HyperLogLog (`PFADD`/`PFCOUNT`):** $O(1)$ probabilistic cardinality estimation in 12 KB memory.
4. **Production Safety:** Never run blocking $O(N)$ commands like `KEYS *` or `FLUSHALL` in production patterns; always demonstrate `SCAN` cursor iteration or scoped key patterns, and use `UNLINK` for non-blocking deletion of large keys.

### D. GraphQL (PostGraphile v4)
1. **Named Operations Only:** Every query and mutation must have an explicit PascalCase operation name (e.g., `query GetDepartmentsWithEmployees`, `mutation CreateNewEmployee`). Never write anonymous `{ ... }` queries.
2. **Strict Variable Parameterization:** Never interpolate dynamic arguments into the GraphQL query string. Declare typed operation variables (`query GetDepartmentById($deptId: Int!)`) and pass a separate JSON variables payload.
3. **Minimal Field Selection & Fragments:** Request only the exact fields needed. Extract repeated field sets into reusable `fragment Name on Type { ... }` blocks.
4. **Connection Best Practices:** Prefer `nodes { ... }` for simple list traversal in PostGraphile, and `edges { cursor node { ... } } pageInfo { hasNextPage endCursor }` when implementing cursor-based pagination. Always bound list queries with `first: N`.

---

## 🤖 4. Specialized Agents & Skills Directory

### Custom Agents (`.agents/agents/`)
- [`sql-postgres-architect`](.agents/agents/sql-postgres-architect.md): PostgreSQL 16 query optimization, CTEs, window functions, indexing, and `EXPLAIN ANALYZE` specialist.
- [`mongodb-nosql-specialist`](.agents/agents/mongodb-nosql-specialist.md): MongoDB 7.0 aggregation pipeline architect, ESR indexing, and document modeling specialist.
- [`redis-cache-engineer`](.agents/agents/redis-cache-engineer.md): Redis 7 data structure selection, keyspace design, caching patterns, and Big-O complexity specialist.
- [`graphql-api-specialist`](.agents/agents/graphql-api-specialist.md): PostGraphile v4 GraphQL query, fragment, pagination, and mutation specialist.
- [`interview-coach-reviewer`](.agents/agents/interview-coach-reviewer.md): Technical database interviewer that reviews queries for edge cases, complexity, and interview traps.

### Workspace Skills (`.agents/skills/`)
- [`sql-query-mastery`](.agents/skills/sql-query-mastery/SKILL.md): Best practices, query templates, edge-case checklists, and optimization patterns for PostgreSQL 16.
- [`mongodb-aggregation-mastery`](.agents/skills/mongodb-aggregation-mastery/SKILL.md): Best practices, aggregation pipeline design, ESR indexing, and explain plans for MongoDB 7.0.
- [`redis-data-structures-mastery`](.agents/skills/redis-data-structures-mastery/SKILL.md): Redis 7 data structures, caching strategies, atomic patterns, and complexity tradeoffs.
- [`graphql-postgraphile-mastery`](.agents/skills/graphql-postgraphile-mastery/SKILL.md): Idiomatic GraphQL query construction, fragments, variables, and mutations for PostGraphile.
- [`sandbox-query-runner`](.agents/skills/sandbox-query-runner/SKILL.md): Container lifecycle management and automated query execution/benchmarking across PostgreSQL, MongoDB, Redis, and GraphQL.

