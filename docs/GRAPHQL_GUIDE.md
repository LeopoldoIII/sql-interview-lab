# 🚀 Complete GraphQL Guide: Queries, Relations & Mutations

This guide accompanies the **PostGraphile** GraphQL engine container (`sql_interview_graphql`), which automatically inspects the PostgreSQL relational schema (`departments`, `employees`, `sales`) and exposes a high-performance GraphQL API.

---

## ⚡ Interactive Playground (GraphiQL)

* **Interactive in-browser IDE:** 👉 **[http://localhost:5000/graphiql](http://localhost:5000/graphiql)**
* **GraphQL HTTP Endpoint:** `http://localhost:5000/graphql`

GraphiQL features intelligent autocomplete (`Ctrl + Space` or `Cmd + Space`) and an interactive schema documentation explorer in the right sidebar (`Docs`).

---

## 🧭 Why GraphQL?

Compared to traditional REST endpoints:
* **Clients request exactly what they need:** Zero over-fetching or under-fetching.
* **Nested relational data in a single request:** Fetch departments, their employees, and corresponding sales transactions in one network roundtrip.

---

## 📌 Module 1: Basic Queries

### 1.1 Simple Employee Query
```graphql
query GetAllEmployees {
  allEmployees {
    nodes {
      employeeId
      firstName
      lastName
      salary
    }
  }
}
```

---

### 1.2 Nested Relationships (Department $\rightarrow$ Employees $\rightarrow$ Sales)
Derived automatically from PostgreSQL foreign key constraints:

```graphql
query DepartmentsWithEmployeesAndSales {
  allDepartments {
    nodes {
      departmentId
      departmentName
      employeesByDepartmentId {
        nodes {
          firstName
          salary
          salesByEmployeeId {
            nodes {
              amount
              saleDate
            }
          }
        }
      }
    }
  }
}
```

---

## 📌 Module 2: Filtering, Sorting & Pagination

### 2.1 Filtering with Arguments (`condition`)
```graphql
query FilterEmployees {
  allEmployees(condition: { departmentId: 1 }) {
    nodes {
      firstName
      salary
    }
  }
}
```

### 2.2 Sorting (`orderBy`)
```graphql
query TopPaidEmployees {
  allEmployees(orderBy: SALARY_DESC, first: 3) {
    nodes {
      firstName
      salary
    }
  }
}
```

### 2.3 Cursor-based Pagination (`Connections`)
```graphql
query PaginatedEmployees {
  allEmployees(first: 2) {
    totalCount
    pageInfo {
      hasNextPage
      hasPreviousPage
      endCursor
    }
    edges {
      cursor
      node {
        employeeId
        firstName
      }
    }
  }
}
```

---

## 📌 Module 3: Mutations (Insert, Update, Delete)

### 3.1 Inserting an Employee (`createEmployee`)
```graphql
mutation AddNewEmployee {
  createEmployee(
    input: {
      employee: {
        firstName: "Mateo"
        lastName: "Valdez"
        departmentId: 1
        salary: 89000.00
        hireDate: "2024-03-01"
      }
    }
  ) {
    employee {
      employeeId
      firstName
      salary
    }
  }
}
```

## 📌 Module 4: How GraphQL Handles Duplicates ($N+1$ Problem & Client Caching)

In technical interviews, a frequent trick question is: *"How do I query distinct rows or remove duplicate data in GraphQL?"*

> 💡 **Core Concept:** GraphQL is an API specification and transport layer, **not a database**. It has no native `DISTINCT` or `GROUP BY` keywords. Instead, duplicates are addressed across three distinct architectural layers:

```
+----------------------------------------------------------------------------------------------------+
|                                GRAPHQL DEDUPLICATION ARCHITECTURE                                  |
+--------------------------+-------------------------------+-----------------------------------------+
| Architectural Layer      | The Problem                   | Industry Standard Solution              |
+--------------------------+-------------------------------+-----------------------------------------+
| 1. Database Resolution   | $N+1$ duplicate SQL queries   | DataLoader (Batching & Caching)         |
| 2. Client-Side State     | Storing duplicate objects     | Apollo / Relay Normalized Cache         |
| 3. Mutations / Writes    | Retrying identical mutations  | clientMutationId / Idempotency tokens   |
+--------------------------+-------------------------------+-----------------------------------------+
```

---

### 4.1 The $N+1$ Problem: Deduplicating Repetitive Database Queries
When you query 50 employees and their associated department:

```graphql
query EmployeesWithDepartment {
  allEmployees {
    nodes {
      firstName
      departmentByDepartmentId {
        departmentName
      }
    }
  }
}
```

* **The Problem (Naive Execution):** The server runs 1 query for employees, plus **50 separate SQL queries** asking for department data—even if all 50 employees belong to just 2 departments!
* **The Solution: `DataLoader`**:
  * **Batching:** Collects all requested `departmentId` values across the request and executes a single batched query:  
    `SELECT * FROM departments WHERE department_id IN (1, 2);`
  * **Memoization Cache:** Within a single HTTP request lifecycle, once `department_id: 1` is resolved, subsequent requests for department 1 return the cached in-memory reference with zero extra database hits.

---

### 4.2 Client-Side Deduplication: Normalized Cache (Apollo Client / Relay)
When a GraphQL client receives responses from multiple queries, it avoids creating duplicate copies of the same entity in memory using **Normalized Caching**:

1. Every object is assigned an internal cache key:  
   `CacheKey = __typename + ":" + id` (e.g., `Employee:101`).
2. If Query A fetches `{ employeeId: 101, firstName: "Alice" }` and Query B later fetches `{ employeeId: 101, salary: 85000 }`, the client normalizer merges them into a **single unique in-memory entity**, completely eliminating duplicated state.

---

### 4.3 Mutation Idempotency (`clientMutationId`)
To prevent duplicated record creation when mobile or web clients experience intermittent connectivity:
* Mutations in specifications like Relay accept a unique `clientMutationId`.
* If a mutation is resent due to network timeout, the server recognizes the `clientMutationId` and returns the previously processed result instead of re-inserting the record.

---

## 🎯 GraphQL Practice Challenges

#### Challenge 1: Manager Hierarchy
> **Question:** Write a query in GraphiQL that returns each employee's first name along with the first and last name of their direct manager in a single nested field.

<details>
<summary>🔍 View Solution</summary>

```graphql
query EmployeesWithManagers {
  allEmployees {
    nodes {
      firstName
      employeeByManagerId {
        firstName
        lastName
      }
    }
  }
}
```
</details>

#### Challenge 2: Deep Relational Query (Avoiding Over-fetching)
> **Question:** Query department ID 1 (`Engineering`) along with all its employees and only their `salary` and `hireDate`, without requesting unneeded personal information.

<details>
<summary>🔍 View Solution</summary>

```graphql
query EngineeringPayrollDetails {
  departmentByDepartmentId(departmentId: 1) {
    departmentName
    employeesByDepartmentId {
      nodes {
        salary
        hireDate
      }
    }
  }
}
```
</details>

