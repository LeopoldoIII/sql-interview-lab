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

---

## 🎯 GraphQL Practice Challenge

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
