-- ========================================================
-- SQL Interview Prep Lab - Schema & Seed Data
-- ========================================================

-- 1. Departments Table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

-- 2. Employees Table
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department_id INT REFERENCES departments(department_id),
    salary DECIMAL(10, 2) NOT NULL,
    hire_date DATE NOT NULL,
    manager_id INT REFERENCES employees(employee_id)
);

-- 3. Sales Table
CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    amount DECIMAL(10, 2) NOT NULL,
    sale_date DATE NOT NULL
);

-- Seed Data: Departments (Includes 'Marketing' with 0 employees to test LEFT JOIN edge cases)
INSERT INTO departments (department_name) VALUES
('Engineering'),
('Data & Analytics'),
('Sales'),
('Human Resources'),
('Marketing');

-- Seed Data: Employees
INSERT INTO employees (first_name, last_name, department_id, salary, hire_date, manager_id) VALUES
('Carlos', 'Mendoza', 1, 95000.00, '2021-03-15', NULL),
('Ana', 'Gómez', 1, 82000.00, '2022-01-10', 1),
('Luis', 'Torres', 2, 88000.00, '2020-11-01', NULL),
('María', 'Rodríguez', 2, 75000.00, '2023-02-01', 3),
('Javier', 'López', 2, 75000.00, '2023-05-15', 3),
('Sofia', 'Martínez', 3, 65000.00, '2022-06-20', NULL),
('Diego', 'Hernández', 3, 62000.00, '2023-08-10', 6),
('Laura', 'Díaz', 4, 58000.00, '2019-04-12', NULL);

-- Seed Data: Sales
INSERT INTO sales (employee_id, amount, sale_date) VALUES
(6, 1500.00, '2024-01-05'),
(6, 3200.00, '2024-01-15'),
(7, 2100.00, '2024-01-20'),
(6, 4500.00, '2024-02-02'),
(7, 1800.00, '2024-02-14'),
(3, 5000.00, '2024-02-28');
