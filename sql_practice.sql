-- ============================================================================
-- 🚀 SQL Interview Lab - Interactive Practice Script
-- ============================================================================
-- This script contains runnable exercises organized by progressive modules.
-- You can execute each block directly in PGWeb (http://localhost:8081)
-- or via the PostgreSQL CLI:
-- docker exec -it sql_interview_postgres psql -U admin -d interview_db
-- ============================================================================

-- ============================================================================
-- 📌 MODULE 1: FUNDAMENTALS & FILTERING (SELECT, WHERE, ORDER BY, LIMIT)
-- ============================================================================

-- 1.1 Initial table inspection
SELECT * FROM departments;
SELECT * FROM employees;
SELECT * FROM sales;

-- 1.2 Comparison operators (Salaries > 80,000)
SELECT first_name, last_name, salary 
FROM employees 
WHERE salary > 80000;

-- 1.3 Range and membership filters (BETWEEN, IN)
SELECT first_name, department_id, hire_date 
FROM employees 
WHERE department_id IN (1, 2)
  AND hire_date BETWEEN '2021-01-01' AND '2022-12-31';

-- 1.4 Strict null handling (IS NULL)
SELECT first_name, last_name 
FROM employees 
WHERE manager_id IS NULL;

-- 1.5 Ordering and pagination (Top 3 highest salaries)
SELECT first_name, last_name, salary 
FROM employees 
ORDER BY salary DESC 
LIMIT 3;

-- 1.6 Conditional expressions in SELECT (CASE WHEN)
SELECT 
    first_name,
    salary,
    CASE 
        WHEN salary >= 85000 THEN 'High Tier'
        WHEN salary >= 70000 THEN 'Mid Tier'
        ELSE 'Entry Tier'
    END AS salary_bracket
FROM employees;


-- ============================================================================
-- 📌 MODULE 2: AGGREGATIONS, GROUPING & EXECUTION ORDER
-- ============================================================================

-- 2.1 Global payroll summary statistics
SELECT 
    COUNT(*) AS total_employees,
    ROUND(AVG(salary), 2) AS average_salary,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    SUM(salary) AS total_payroll
FROM employees;

-- 2.2 Grouping by department with post-aggregation filter (HAVING)
SELECT 
    department_id,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 1
ORDER BY avg_salary DESC;

-- 2.3 Accumulated sales revenue per employee
SELECT 
    employee_id,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_revenue,
    ROUND(AVG(amount), 2) AS avg_ticket
FROM sales
GROUP BY employee_id
HAVING SUM(amount) > 3000
ORDER BY total_revenue DESC;


-- ============================================================================
-- 📌 MODULE 3: RELATIONSHIPS AND JOINS
-- ============================================================================

-- 3.1 Table Aliases & INNER JOIN: Using aliases (e, d) for clean syntax and column disambiguation
-- Without aliases (verbose):
-- SELECT employees.first_name, employees.last_name, departments.department_name FROM employees INNER JOIN departments ON employees.department_id = departments.department_id;
-- With aliases (idiomatic):
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

-- 3.2 LEFT JOIN: All departments with associated employees (Marketing appears with NULL)
SELECT 
    d.department_name,
    e.first_name,
    e.last_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id;

-- 3.3 LEFT JOIN with Aggregation: Demonstrating the COUNT(*) vs COUNT(col) trap
-- Notice department 'Marketing' (ID 5) has 0 employees:
SELECT 
    d.department_name,
    COUNT(*) AS erroneous_star_count,          -- Returns 1 (counts the NULL row)
    COUNT(e.employee_id) AS correct_id_count    -- Returns 0 (ignores NULL values)
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name;

-- 3.4 SELF JOIN: Employee to direct Manager hierarchy
SELECT 
    e.first_name AS employee,
    COALESCE(m.first_name, 'No Manager') AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- 3.5 SELF JOIN: Unique pairs of employees in the same department (e1.id < e2.id)
SELECT 
    e1.first_name AS employee_1,
    e2.first_name AS employee_2,
    e1.department_id
FROM employees e1
INNER JOIN employees e2 
    ON e1.department_id = e2.department_id
   AND e1.employee_id < e2.employee_id;

-- 3.6 CROSS JOIN: Cartesian product (every employee crossed with every department)
SELECT 
    e.first_name, 
    d.department_name
FROM employees e
CROSS JOIN departments d;

-- 3.7 Full report: Employees and their total sales (with COALESCE for zero sales)
SELECT 
    e.first_name || ' ' || e.last_name AS employee,
    d.department_name,
    COALESCE(SUM(s.amount), 0.00) AS total_sales
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
LEFT JOIN sales s ON e.employee_id = s.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name
ORDER BY total_sales DESC;


-- ============================================================================
-- 📌 MODULE 4: ADVANCED INTERVIEW TECHNIQUES
-- ============================================================================

-- 4.1 Window Functions: ROW_NUMBER vs RANK vs DENSE_RANK
SELECT 
    first_name,
    department_id,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS row_num,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk,
    DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dense_rnk
FROM employees;

-- 4.2 Top 2 highest salaries per department (using CTE)
WITH RankedSalaries AS (
    SELECT 
        e.first_name,
        e.last_name,
        d.department_name,
        e.salary,
        DENSE_RANK() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS ranking
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
)
SELECT department_name, first_name, last_name, salary, ranking
FROM RankedSalaries
WHERE ranking <= 2
ORDER BY department_name, ranking;

-- 4.3 CTE: Employees earning more than their department's average
WITH DeptAverages AS (
    SELECT 
        department_id,
        AVG(salary) AS dept_avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT 
    e.first_name,
    e.salary,
    ROUND(d.dept_avg_salary, 2) AS dept_avg
FROM employees e
JOIN DeptAverages d ON e.department_id = d.department_id
WHERE e.salary > d.dept_avg_salary;


-- ============================================================================
-- 📌 MODULE 5: CLASSIC INTERVIEW PUZZLES
-- ============================================================================

-- 5.1 Finding the 2nd highest salary (DENSE_RANK method)
WITH RankedSalaries AS (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
)
SELECT DISTINCT salary 
FROM RankedSalaries 
WHERE rnk = 2;

-- 5.2 Finding the 2nd highest salary (OFFSET method)
SELECT DISTINCT salary 
FROM employees 
ORDER BY salary DESC 
OFFSET 1 LIMIT 1;

-- 5.3 Anti-Join: Finding departments with 0 employees (LEFT JOIN + IS NULL)
SELECT d.department_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.employee_id IS NULL;

-- 5.4 Anti-Join: Finding departments with 0 employees (NOT EXISTS)
SELECT d.department_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.department_id = d.department_id
);

-- 5.5 Deduplication: Lookup Tables (Detect duplicates by normalized department_name)
SELECT 
    LOWER(TRIM(department_name)) AS normalized_name,
    COUNT(*) AS total_occurrences,
    ARRAY_AGG(department_id) AS conflicting_ids
FROM departments
GROUP BY LOWER(TRIM(department_name))
HAVING COUNT(*) > 1;

-- 5.6 Deduplication: Entity Tables (Find duplicates using ROW_NUMBER)
WITH RankedEmployees AS (
    SELECT 
        employee_id,
        first_name,
        last_name,
        department_id,
        salary,
        hire_date,
        ROW_NUMBER() OVER (
            PARTITION BY department_id, salary 
            ORDER BY hire_date ASC, employee_id ASC
        ) AS duplicate_rank
    FROM employees
)
SELECT 
    employee_id,
    first_name,
    last_name,
    department_id,
    salary,
    CASE 
        WHEN duplicate_rank = 1 THEN 'KEEP (Original)'
        ELSE 'DELETE (Duplicate)'
    END AS action_plan
FROM RankedEmployees
ORDER BY department_id, salary, duplicate_rank;

-- 5.7 Deduplication: Transactional Tables (Detect duplicate sales transactions)
SELECT 
    employee_id,
    sale_date,
    amount,
    COUNT(*) AS duplicate_count
FROM sales
GROUP BY employee_id, sale_date, amount
HAVING COUNT(*) > 1;

