# PostGraphile v4 GraphQL Query & Mutation Patterns

## 1. Parameterized Queries with Cursor Pagination

Always combine explicit variable types (`$first: Int!`, `$after: Cursor`) with `pageInfo` for production-grade pagination:

```graphql
fragment EmployeeCoreFields on Employee {
  employeeId
  firstName
  lastName
  salary
  hireDate
}

# Variables: { "first": 5, "after": null }
query GetPaginatedEmployees($first: Int = 5, $after: Cursor) {
  allEmployees(first: $first, after: $after, orderBy: [SALARY_DESC, PRIMARY_KEY_ASC]) {
    totalCount
    pageInfo {
      hasNextPage
      endCursor
    }
    nodes {
      ...EmployeeCoreFields
      departmentByDepartmentId {
        departmentId
        departmentName
      }
    }
  }
}
```

---

## 2. Nested Relational Aggregation (`totalCount` Without Over-Fetching)

When an interview problem asks for department headcounts via GraphQL, request `totalCount` on the child connection without pulling all child `nodes`:

```graphql
query GetDepartmentHeadcounts {
  allDepartments(orderBy: DEPARTMENT_NAME_ASC) {
    nodes {
      departmentId
      departmentName
      employeesByDepartmentId {
        totalCount
      }
    }
  }
}
```

---

## 3. Parameterized Mutations with Cache-Ready Payloads

Always pass a typed `$input` variable rather than inline literals, and return the mutated entity along with its parent relationship:

```graphql
# Variables:
# {
#   "input": {
#     "employee": {
#       "firstName": "Ada",
#       "lastName": "Lovelace",
#       "departmentId": 1,
#       "salary": "115000.00",
#       "hireDate": "2024-03-01"
#     }
#   }
# }
mutation RegisterEmployee($input: CreateEmployeeInput!) {
  createEmployee(input: $input) {
    employee {
      employeeId
      firstName
      lastName
      salary
      departmentByDepartmentId {
        departmentId
        departmentName
      }
    }
  }
}
```

