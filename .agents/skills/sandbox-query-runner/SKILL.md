---
name: sandbox-query-runner
description: >-
  Use this skill to check container health, start Docker Compose profiles
  (sql, nosql, redis, graphql, all), and execute or benchmark live queries
  against PostgreSQL 16, MongoDB 7.0, Redis 7, and PostGraphile GraphQL.
---

# Sandbox Query Runner & Container Orchestration

Use this skill whenever you need to test, benchmark (`EXPLAIN ANALYZE` / `.explain("executionStats")`), or verify queries against the live Docker containers defined in [`docker-compose.yml`](../../docker-compose.yml).

> **Language Rule:** All CLI outputs, error summaries, and explanations MUST be written in **English**.

---

## 1. Quick Execution via Helper Script

Use the bundled helper script [`scripts/run_query.sh`](./scripts/run_query.sh) to check status or run queries across any engine:

```bash
# 1. Check running container status
bash .agents/skills/sandbox-query-runner/scripts/run_query.sh status

# 2. Execute a PostgreSQL query
bash .agents/skills/sandbox-query-runner/scripts/run_query.sh sql "SELECT d.department_name, COUNT(e.employee_id) AS headcount FROM departments d LEFT JOIN employees e ON d.department_id = e.department_id GROUP BY d.department_id, d.department_name ORDER BY headcount DESC;"

# 3. Run PostgreSQL EXPLAIN (ANALYZE, BUFFERS)
bash .agents/skills/sandbox-query-runner/scripts/run_query.sh sql-explain "SELECT * FROM employees WHERE salary > 80000;"

# 4. Execute a MongoDB query or aggregation pipeline
bash .agents/skills/sandbox-query-runner/scripts/run_query.sh mongo "db.employees.aggregate([{ \$match: { status: 'Active' } }, { \$group: { _id: '\$department', avgSalary: { \$avg: '\$salary' } } }])"

# 5. Execute a Redis command
bash .agents/skills/sandbox-query-runner/scripts/run_query.sh redis "ZREVRANGE sales_leaderboard 0 -1 WITHSCORES"

# 6. Execute a GraphQL query (with optional JSON variables as 3rd argument)
bash .agents/skills/sandbox-query-runner/scripts/run_query.sh graphql 'query GetDepts { allDepartments { nodes { departmentId departmentName } } }' '{}'
```

---

## 2. Managing Docker Compose Profiles

If a target container is not running, start only the required profile:
- **SQL (PostgreSQL + PGWeb):** `docker compose --profile sql up -d`
- **NoSQL (MongoDB + Redis):** `docker compose --profile nosql up -d`
- **Redis (Redis + RedisInsight):** `docker compose --profile redis up -d`
- **GraphQL (PostgreSQL + PostGraphile):** `docker compose --profile graphql up -d`
- **All Services:** `docker compose --profile all up -d`

