# 🚀 SQL & NoSQL Interview Practice Lab

A zero-setup, containerized sandbox environment powered by **Docker**, **PostgreSQL 16**, and **MongoDB 7.0**, pre-populated with realistic schemas and datasets to practice SQL interview questions from beginner to advanced levels.

---

## 🛠️ Prerequisites

Before getting started, make sure you have the following tools installed:

1. **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** (version 20+ and Docker Compose v2+).
2. **Code Editor** (VS Code / Any other IDE).
3. **Database Extension** (Recommended: **`PostgreSQL`** by *Microsoft* or **`Database Client`** by *cweijan*).

---

## ⚡ Quick Start

### 1. Clone & Start Containers
Run the following command in your terminal inside the project directory:

```bash
docker compose up -d
```

This will automatically pull and start:
* **PostgreSQL 16** container (`sql_interview_postgres`) running on port `5432`.
* **MongoDB 7.0** container (`nosql_interview_mongo`) running on port `27017`.
* **PGWeb GUI** container (`sql_interview_pgweb`) running on port `8081`.
* Automatically executes `sql_init/01_schema_and_data.sql` to populate initial datasets.

---

## 🌐 Web Database GUI (No Extension Required!)

Don't want to install any editor extensions? Simply open your web browser after running `docker compose up -d`:

👉 **[http://localhost:8081](http://localhost:8081)**

**pgweb** is automatically connected to your PostgreSQL database! You can view tables, run SQL queries, and export results directly from your web browser with zero configuration.

---

## 🐘 Connection Details

#### PostgreSQL (Relational Database)
* **Host:** `localhost` (or `127.0.0.1`)
* **Port:** `5432`
* **User:** `admin`
* **Password:** `adminpassword`
* **Database:** `interview_db`

#### 🍃 MongoDB (NoSQL Database)
* **Host:** `localhost` (or `127.0.0.1`)
* **Port:** `27017`
* **User:** `admin`
* **Password:** `adminpassword`
* **Database:** `interview_nosql`

---

## 📊 Database Schema (ERD Diagram)

The initial PostgreSQL database (`interview_db`) comes pre-seeded with 3 relational tables:

```mermaid
erDiagram
    DEPARTMENTS ||--o{ EMPLOYEES : "has many"
    EMPLOYEES ||--o{ SALES : "makes"
    EMPLOYEES ||--o{ EMPLOYEES : "manages"

    DEPARTMENTS {
        int department_id PK
        string department_name
    }

    EMPLOYEES {
        int employee_id PK
        string first_name
        string last_name
        int department_id FK
        decimal salary
        date hire_date
        int manager_id FK
    }

    SALES {
        int sale_id PK
        int employee_id FK
        decimal amount
        date sale_date
    }
```

### Note on Seed Data Edge Cases:
* **Department with 0 employees:** Contains a `'Marketing'` department without any assigned employees to test `LEFT JOIN` vs `INNER JOIN` edge cases.
* **Self-Referencing Manager:** `employees.manager_id` references `employees.employee_id` to practice `SELF JOIN` queries.

---

## 💻 Running Queries

### Option A: Via Web Browser (easiest)
Navigate to **[http://localhost:8081](http://localhost:8081)**.

### Option B: Via VS Code Extension
1. Install the **PostgreSQL** extension by *Microsoft*.
2. Add a new PostgreSQL connection using the credentials above.
3. Open any `.sql` file, select your query, and run it!

### Option C: Via Terminal CLI
```bash
# Connect to PostgreSQL CLI
docker exec -it sql_interview_postgres psql -U admin -d interview_db

# Or run a single query directly
docker exec -i sql_interview_postgres psql -U admin -d interview_db -c "SELECT * FROM employees;"
```

---

## 📚 Study Plan & Practice Challenges (Step-by-Step)

Follow this 5-day structured curriculum to master technical SQL interview questions.

---

### 📅 Day 1: Basic Filtering & Aggregations

#### Key Concepts & Execution Order:
In SQL, queries execute in this logical order:
1. `FROM` & `JOIN` -> 2. `WHERE` -> 3. `GROUP BY` -> 4. `HAVING` -> 5. `SELECT` -> 6. `ORDER BY` -> 7. `LIMIT`

> ⚠️ **Interview Trap:** `WHERE` filters rows *before* grouping, while `HAVING` filters groups *after* aggregation. You cannot use aggregate functions (`SUM`, `AVG`, `COUNT`) inside a `WHERE` clause.

#### 📝 Challenge 1.1: Department Salary Summary
> **Task:** Write a query to find the department ID, total number of employees, and average salary (rounded to 2 decimal places) for each department. Only include departments that have **more than 1 employee**, and order the results from highest to lowest average salary.

<details>
<summary>🔍 Click to view Solution 1.1</summary>

```sql
SELECT 
    department_id,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 1
ORDER BY avg_salary DESC;
```
</details>

---

### 📅 Day 2: Table Joins (`INNER`, `LEFT`, `RIGHT`, `FULL`, `SELF JOIN`)

#### Key Concepts:
* `INNER JOIN`: Returns rows where there is a match in both tables.
* `LEFT JOIN`: Returns all rows from the left table and matched rows from the right table (populates `NULL` when there is no match).
* `SELF JOIN`: Joining a table to itself to resolve hierarchical data (e.g., employee to manager).

> ⚠️ **Interview Trap (`COUNT(*)` vs `COUNT(col)`):** When doing a `LEFT JOIN` on a department with 0 employees (like `'Marketing'`), `COUNT(*)` counts the `NULL` row as `1` (incorrect), whereas `COUNT(e.employee_id)` ignores `NULL` and correctly returns `0`.

#### 📝 Challenge 2.1: Complete Department Roster (Handling 0 Employees)
> **Task:** List all department names and their total employee count. Ensure that departments with zero employees (e.g., Marketing) are included in the results with a count of `0`.

<details>
<summary>🔍 Click to view Solution 2.1</summary>

```sql
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS total_employees
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY total_employees DESC;
```
</details>

#### 📝 Challenge 2.2: Employee Manager Mapping (SELF JOIN)
> **Task:** List each employee's first name alongside their direct manager's first name. Include employees who do not have a manager (their manager name should display as `No Manager`).

<details>
<summary>🔍 Click to view Solution 2.2</summary>

```sql
SELECT 
    e.first_name AS employee_name,
    COALESCE(m.first_name, 'No Manager') AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;
```
</details>

---

### 📅 Day 3: Window Functions (`ROW_NUMBER`, `DENSE_RANK`, `LEAD/LAG`)

#### Key Concepts:
Unlike `GROUP BY`, Window Functions perform calculations across a set of table rows related to the current row **without collapsing the individual rows**.

* `ROW_NUMBER()`: Unique sequential integer per partition (1, 2, 3, 4).
* `RANK()`: Rank with gaps for ties (1, 2, 2, 4).
* `DENSE_RANK()`: Rank without gaps for ties (1, 2, 2, 3).
* `LAG(col, offset)` / `LEAD(col, offset)`: Access data from preceding or succeeding rows.

#### 📝 Challenge 3.1: Top 2 Highest Paid Employees per Department
> **Task:** Find the top 2 highest-earning employees in **each department**. If there are salary ties, use `DENSE_RANK()` so tied employees receive the same rank.

<details>
<summary>🔍 Click to view Solution 3.1</summary>

```sql
WITH RankedSalaries AS (
    SELECT 
        e.first_name,
        e.last_name,
        d.department_name,
        e.salary,
        DENSE_RANK() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS rnk
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
)
SELECT department_name, first_name, last_name, salary
FROM RankedSalaries
WHERE rnk <= 2;
```
</details>

---

### 📅 Day 4: Common Table Expressions (CTEs) & Subqueries

#### Key Concepts:
CTEs (`WITH cte_name AS (...)`) make complex subqueries readable and modular.

#### 📝 Challenge 4.1: Employees Outperforming Average Company Sales
> **Task:** Using a CTE, calculate total sales per employee. Then, return the employee names and total sales for employees whose total sales exceed the company-wide average sale amount.

<details>
<summary>🔍 Click to view Solution 4.1</summary>

```sql
WITH EmployeeSales AS (
    SELECT 
        employee_id,
        SUM(amount) AS total_sales
    FROM sales
    GROUP BY employee_id
)
SELECT 
    e.first_name, 
    e.last_name, 
    es.total_sales
FROM EmployeeSales es
JOIN employees e ON es.employee_id = e.employee_id
WHERE es.total_sales > (SELECT AVG(amount) FROM sales);
```
</details>

---

### 📅 Day 5: Classic Interview Puzzles & MongoDB NoSQL

#### 📝 Puzzle 5.1: Finding the N-th Highest Salary (2nd Highest)
> **Task:** Find the 2nd highest salary in the entire company.

<details>
<summary>🔍 Click to view Solution 5.1</summary>

```sql
-- Method 1: Using DENSE_RANK()
WITH Ranked AS (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
)
SELECT DISTINCT salary FROM Ranked WHERE rnk = 2;

-- Method 2: Simple OFFSET
SELECT DISTINCT salary 
FROM employees 
ORDER BY salary DESC 
OFFSET 1 LIMIT 1;
```
</details>

#### 🍃 MongoDB Practice (NoSQL)

You can run NoSQL queries using `mongosh` inside Docker:

```bash
docker exec -it nosql_interview_mongo mongosh -u admin -p adminpassword
```

#### MongoDB Aggregation Pipeline Example:
```javascript
use interview_nosql;

// Insert sample documents
db.sales.insertMany([
  { employee_id: 1, amount: 1500, category: "Tech" },
  { employee_id: 1, amount: 3200, category: "Tech" },
  { employee_id: 2, amount: 5000, category: "Services" }
]);

// Group and Sum Pipeline
db.sales.aggregate([
  { $match: { category: "Tech" } },
  { $group: { _id: "$employee_id", totalAmount: { $sum: "$amount" } } },
  { $sort: { totalAmount: -1 } }
]);
```
