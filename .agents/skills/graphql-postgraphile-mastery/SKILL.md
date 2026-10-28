---
name: graphql-postgraphile-mastery
description: >-
  Use this skill whenever creating, refactoring, or validating GraphQL queries,
  fragments, variables, directives, or mutations for PostGraphile v4 in this project.
---

# GraphQL & PostGraphile v4 Mastery

Follow this workflow whenever authoring or reviewing GraphQL operations in [`graphql_practice.graphql`](../../graphql_practice.graphql) or [`docs/GRAPHQL_GUIDE.md`](../../docs/GRAPHQL_GUIDE.md).

> **Language Rule:** All GraphQL operation names, fragments, variable names, comments, and explanations MUST be written in **English**.

---

## 1. Step-by-Step GraphQL Query Construction Workflow

1. **Name Every Operation Explicitly:**
   - Use `query <PascalCaseName>` or `mutation <PascalCaseName>`. Never write anonymous operations.
2. **Parameterize All Dynamic Inputs via `$variables`:**
   - Declare typed variables in the operation header (e.g., `query GetDepartmentById($deptId: Int!)`) and provide a companion JSON variables example in comments.
3. **Select Minimal Fields & Extract Reusable Fragments:**
   - Avoid requesting unnecessary nested connections.
   - Define `fragment <Name> on <Type>` for repeated entity shapes.
4. **Bound Collections & Choose `nodes` vs `edges`:**
   - Always pass `first: <Int>` on plural connections (`allEmployees(first: 10, orderBy: SALARY_DESC)`) unless intentionally enumerating a small lookup table like `allDepartments`.
   - Include `pageInfo { hasNextPage endCursor }` and `totalCount` when building paginated views.
5. **Verify Against `sql_interview_graphql`:**
   - Execute operations directly against `http://localhost:5000/graphql` via [`sandbox-query-runner`](../sandbox-query-runner/SKILL.md):
     ```bash
     bash .agents/skills/sandbox-query-runner/scripts/run_query.sh graphql 'query GetDepts { allDepartments { nodes { departmentId departmentName } } }'
     ```

---

## 2. Deep Reference Manual

For PostGraphile connection patterns, cursor pagination, and mutation payload design, read:
- [PostGraphile Query & Mutation Patterns](./references/postgraphile-query-patterns.md)

