---
name: sql-query-mastery
description: >-
  Use this skill whenever creating, refactoring, optimizing, or explaining SQL
  queries for PostgreSQL 16 in this project. Provides idiomatic query construction
  patterns, SARGability rules, CTE and Window Function best practices, NULL-safe
  anti-joins, and edge-case verification checklists against interview_db.
---

# PostgreSQL 16 & SQL Query Mastery

Follow this workflow whenever authoring, reviewing, or optimizing SQL queries in [`sql_practice.sql`](../../sql_practice.sql), [`sql_init/01_schema_and_data.sql`](../../sql_init/01_schema_and_data.sql), or [`docs/SQL_GUIDE.md`](../../docs/SQL_GUIDE.md).

> **Language Rule:** All SQL queries, CTE names, aliases, comments, and explanations MUST be written in **English**.

---

## 1. Step-by-Step Query Construction Workflow

1. **Understand the Grain & Target Entities:**
   - Identify what a single row in the final result represents (e.g., one row per `department`, one row per `employee`, or one row per `sale`).
2. **Check Built-In `interview_db` Edge Cases:**
   - **Zero-Child Groups:** Department `'Marketing'` (`department_id = 5`) has `0` employees. Does the query require `LEFT JOIN` + `COUNT(e.employee_id)` instead of `INNER JOIN` or `COUNT(*)`?
   - **Tied Rankings:** Department `2` (`'Data & Analytics'`) has two employees tied at `75000.00`. Should ties share the same rank without gaps (`DENSE_RANK()`), share with gaps (`RANK()`), or be broken deterministically (`ROW_NUMBER() OVER (... ORDER BY salary DESC, hire_date ASC, employee_id ASC)`)?
   - **Nullable Self-References:** Root managers have `manager_id IS NULL`. Ensure hierarchy queries use `LEFT JOIN` and `COALESCE`, and anti-joins use `NOT EXISTS` (never `NOT IN`).
   - **Zero Sales:** Several employees have no rows in `sales`. Wrap revenue aggregations with `COALESCE(SUM(s.amount), 0.00)`.
3. **Structure with CTEs (`WITH` Clauses):**
   - Break complex logic into readable, single-responsibility CTEs named in `PascalCase` or `snake_case` (e.g., `WITH RankedSalaries AS (...), DepartmentTotals AS (...)`).
   - Avoid deeply nested inline subqueries in `FROM` or `WHERE`.
4. **Enforce SARGability & PostgreSQL 16 Idioms:**
   - Keep indexed columns unmodified on the left-hand side of comparisons.
   - Use `COUNT(*) FILTER (WHERE <condition>)` or `SUM(amount) FILTER (WHERE <condition>)` for clean conditional aggregation instead of verbose `CASE WHEN` blocks.
   - Use `LATERAL` joins when correlated top-N per group or row-by-row set-returning calculations are cleaner than window functions.
5. **Verify Execution & Plan:**
   - Run the query against `sql_interview_postgres` using the [`sandbox-query-runner`](../sandbox-query-runner/SKILL.md) script:
     ```bash
     bash .agents/skills/sandbox-query-runner/scripts/run_query.sh sql "SELECT ..."
     bash .agents/skills/sandbox-query-runner/scripts/run_query.sh sql-explain "SELECT ..."
     ```

---

## 2. Deep Reference Manual

For detailed code templates comparing anti-joins, window function frames (`ROWS` vs `RANGE`), recursive CTEs, and index optimization in PostgreSQL 16, read:
- [PostgreSQL Optimization Patterns](./references/postgres-optimization-patterns.md)

