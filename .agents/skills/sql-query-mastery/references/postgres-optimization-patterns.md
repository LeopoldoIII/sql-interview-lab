# PostgreSQL 16 Query Optimization & Interview Patterns

## 1. SARGable vs Non-SARGable Predicates

A predicate is **SARGable** (*Search Argument Able*) when the PostgreSQL query planner can use a B-Tree index to seek directly to matching rows rather than scanning every row.

```sql
-- ❌ Anti-Pattern (Non-SARGable: function wraps column, forces Seq Scan)
SELECT employee_id, first_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2023;

-- ✅ Best Practice (SARGable: half-open date range utilizes index on hire_date)
SELECT employee_id, first_name, hire_date
FROM employees
WHERE hire_date >= DATE '2023-01-01'
  AND hire_date <  DATE '2024-01-01';
```

```sql
-- ❌ Anti-Pattern (Arithmetic on column prevents index usage)
SELECT employee_id, first_name, salary
FROM employees
WHERE salary * 1.10 > 90000;

-- ✅ Best Practice (Isolate column on the left side)
SELECT employee_id, first_name, salary
FROM employees
WHERE salary > (90000 / 1.10);
```

---

## 2. NULL-Safe Anti-Joins (`NOT EXISTS` vs `NOT IN`)

If a subquery can return even a single `NULL` (such as `employees.manager_id`), `NOT IN` evaluates `x <> NULL` as `UNKNOWN`, causing the entire `WHERE` clause to return **0 rows**.

```sql
-- ❌ Anti-Pattern (Returns 0 rows because manager_id contains NULLs!)
SELECT e.employee_id, e.first_name
FROM employees e
WHERE e.employee_id NOT IN (
    SELECT m.manager_id FROM employees m
);

-- ✅ Best Practice 1: NOT EXISTS (NULL-safe, short-circuits on first match)
SELECT e.employee_id, e.first_name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM employees sub
    WHERE sub.manager_id = e.employee_id
);

-- ✅ Best Practice 2: LEFT JOIN + IS NULL
SELECT e.employee_id, e.first_name
FROM employees e
LEFT JOIN employees sub ON e.employee_id = sub.manager_id
WHERE sub.employee_id IS NULL;
```

---

## 3. Window Function Framing (`ROWS` vs `RANGE` Trap)

In PostgreSQL, when you specify `ORDER BY` inside `OVER (...)` for a running total (`SUM(amount) OVER (ORDER BY sale_date)`), the default frame is:
`RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.
If two rows share the same `sale_date` or `salary`, `RANGE` groups their values together on the same step!

```sql
-- ✅ Best Practice: Explicitly specify ROWS frame for deterministic running totals
SELECT
    sale_id,
    employee_id,
    sale_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY employee_id
        ORDER BY sale_date ASC, sale_id ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_employee_revenue
FROM sales;
```

---

## 4. PostgreSQL Native `FILTER (WHERE ...)` for Pivot & Conditional Aggregation

Instead of cluttered `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`, use the SQL-standard / PostgreSQL `FILTER` clause:

```sql
-- ✅ Best Practice: Clean conditional metrics in a single table scan
SELECT
    d.department_name,
    COUNT(e.employee_id) AS total_headcount,
    COUNT(e.employee_id) FILTER (WHERE e.salary >= 80000) AS high_earners_count,
    COALESCE(AVG(e.salary) FILTER (WHERE e.hire_date >= DATE '2022-01-01'), 0.00) AS recent_hires_avg_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
ORDER BY total_headcount DESC;
```

---

## 5. Recursive CTEs for Organizational Hierarchies

When traversing `employees.manager_id`, always include a depth counter and cycle prevention:

```sql
WITH RECURSIVE OrgChart AS (
    -- Anchor member: Top-level leaders (no manager)
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        1 AS hierarchy_level,
        e.first_name::TEXT AS reporting_path
    FROM employees e
    WHERE e.manager_id IS NULL

    UNION ALL

    -- Recursive member: Direct reports
    SELECT
        sub.employee_id,
        sub.first_name,
        sub.last_name,
        sub.manager_id,
        oc.hierarchy_level + 1,
        oc.reporting_path || ' -> ' || sub.first_name
    FROM employees sub
    INNER JOIN OrgChart oc ON sub.manager_id = oc.employee_id
    WHERE oc.hierarchy_level < 10
)
SELECT
    employee_id,
    first_name,
    last_name,
    hierarchy_level,
    reporting_path
FROM OrgChart
ORDER BY hierarchy_level, employee_id;
```

