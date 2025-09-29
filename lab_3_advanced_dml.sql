-- Part A: Database and Table Setup
-- 1. Create database and tables
DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;
\c advanced_lab;

-- Create employees table
DROP TABLE IF EXISTS employees CASCADE;
CREATE TABLE employees (
  emp_id SERIAL PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  department VARCHAR(50),
  salary INTEGER DEFAULT 30000,
  hire_date DATE DEFAULT CURRENT_DATE,
  status VARCHAR(20) DEFAULT 'Active'
);

-- Create departments table
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments (
  dept_id SERIAL PRIMARY KEY,
  dept_name VARCHAR(100) NOT NULL UNIQUE,
  budget INTEGER DEFAULT 50000,
  manager_id INTEGER -- references employees(emp_id) could be added after employees exist
);

-- Create projects table
DROP TABLE IF EXISTS projects CASCADE;
CREATE TABLE projects (
  project_id SERIAL PRIMARY KEY,
  project_name VARCHAR(150) NOT NULL,
  dept_id INTEGER REFERENCES departments(dept_id),
  start_date DATE,
  end_date DATE,
  budget INTEGER DEFAULT 0
);

-- Part B: Advanced INSERT Operations
-- 2. INSERT with column specification (specify subset of columns)
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (DEFAULT, 'Alice', 'Johnson', 'IT');

-- 3. INSERT with DEFAULT values (salary uses DEFAULT, status uses DEFAULT)
INSERT INTO employees (first_name, last_name, department)
VALUES ('Bob', 'Smith', 'Sales'); -- salary and status will use defaults

-- 4. INSERT multiple rows in single statement (3 departments)
INSERT INTO departments (dept_name, budget) VALUES
  ('IT', 120000),
  ('Sales', 90000),
  ('HR', 60000);

-- 5. INSERT with expressions (hire_date = current_date, salary = 50000 * 1.1)
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Carol', 'Lee', 'Marketing', CURRENT_DATE, CAST(50000 * 1.1 AS INTEGER));

-- 6. INSERT from SELECT (subquery) - create temporary table 'temp_employees'
DROP TABLE IF EXISTS temp_employees;
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- Part C: Complex UPDATE Operations
-- 7. UPDATE with arithmetic expressions: increase all salaries by 10%
-- Use:: salary = ROUND(salary * 1.10)
UPDATE employees
SET salary = CAST(ROUND(salary * 1.10) AS INTEGER);

-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < DATE '2020-01-01';

-- 9. UPDATE using CASE expression for department based on salary
UPDATE employees
SET department = CASE
  WHEN salary > 80000 THEN 'Management'
  WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
  ELSE 'Junior'
END;

-- 10. UPDATE with DEFAULT: set department to DEFAULT for employees where status = 'Inactive'
-- Note: departments column default is NULL (no explicit default). To illustrate, first alter table to set a default
ALTER TABLE employees ALTER COLUMN department SET DEFAULT 'Unassigned';

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery: increase department budget to be 20% higher than average salary of employees in that department
-- This updates departments.budget based on computed average salary from employees
UPDATE departments d
SET budget = CAST( (
    (SELECT COALESCE(AVG(e.salary), 0) FROM employees e WHERE e.department = d.dept_name) * 1.20
  ) AS INTEGER)
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department = d.dept_name);

-- 12. UPDATE multiple columns in single statement
UPDATE employees
SET salary = CAST(ROUND(salary * 1.15) AS INTEGER),
    status = 'Promoted'
WHERE department = 'Sales';

-- Part D: Advanced DELETE Operations
-- 13. DELETE with simple WHERE condition
DELETE FROM employees WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > DATE '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery: delete departments that are unused by employees
DELETE FROM departments
WHERE dept_id NOT IN (
  SELECT DISTINCT d.dept_id
  FROM departments d
  LEFT JOIN employees e ON e.department = d.dept_name
  WHERE e.department IS NOT NULL
);

-- NOTE: The above subquery uses dept_id; because employees store department name (dept_name), the simple mapping depends on name match.
-- Alternative reliable approach: delete departments where dept_name NOT IN (SELECT DISTINCT department FROM employees WHERE department IS NOT NULL)

-- safer version (uncomment if preferred):
-- DELETE FROM departments WHERE dept_name NOT IN (SELECT DISTINCT department FROM employees WHERE department IS NOT NULL);

-- 16. DELETE with RETURNING clause (Postgres) - delete projects where end_date < '2023-01-01' and return deleted rows
-- Ensure there are some projects to test
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
  ('Legacy Migration', 1, DATE '2021-01-01', DATE '2022-06-30', 40000),
  ('New Website', 1, DATE '2024-02-01', DATE '2024-10-01', 30000);

-- Delete old projects and return all deleted data
DELETE FROM projects
WHERE end_date < DATE '2023-01-01'
RETURNING *;

-- Part E: Operations with NULL Values
-- 17. INSERT with NULL values (salary NULL and department NULL)
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Dan', 'Nguyen', NULL, NULL);

-- 18. UPDATE NULL handling: set department = 'Unassigned' where department IS NULL
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions: delete employees where salary IS NULL OR department IS NULL
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- Part F: RETURNING Clause Operations
-- 20. INSERT with RETURNING: insert new employee and return auto-generated emp_id and full name
INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('Eve', 'Martinez', 'IT', 55000)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING: update salary for employees in 'IT' dept (increase by 5000) and return emp_id, old salary, new salary
-- To return old salary we use a CTE
WITH updated AS (
  SELECT emp_id, salary AS old_salary
  FROM employees
  WHERE department = 'IT'
)
UPDATE employees e
SET salary = salary + 5000
FROM updated u
WHERE e.emp_id = u.emp_id
RETURNING e.emp_id, u.old_salary, e.salary AS new_salary;

-- 22. DELETE with RETURNING all columns: delete employees where hire_date < '2020-01-01' and return deleted rows
DELETE FROM employees
WHERE hire_date < DATE '2020-01-01'
RETURNING *;

-- Part G: Advanced DML Patterns
-- 23. Conditional INSERT: only add employee if no employee with same first_name and last_name exists
INSERT INTO employees (first_name, last_name, department, salary)
SELECT 'Frank', 'O''Connor', 'Support', 32000
WHERE NOT EXISTS (
  SELECT 1 FROM employees WHERE first_name = 'Frank' AND last_name = 'O''Connor'
);

-- 24. UPDATE with JOIN logic using subqueries: increase salary by 10% if dept budget > 100000, else by 5%
-- We'll compute budgets per department and use it to update employees
WITH dept_budgets AS (
  SELECT dept_name, budget FROM departments
)
UPDATE employees e
SET salary = CAST(ROUND(e.salary * CASE WHEN db.budget > 100000 THEN 1.10 ELSE 1.05 END) AS INTEGER)
FROM dept_budgets db
WHERE e.department = db.dept_name;

-- 25. Bulk operations: Insert 5 employees in single statement, then update their salaries to be 10% higher in single UPDATE
INSERT INTO employees (first_name, last_name, department, salary) VALUES
  ('Gina', 'Torres', 'Sales', 40000),
  ('Hassan', 'Ali', 'Sales', 42000),
  ('Ilya', 'Kovalenko', 'Sales', 38000),
  ('Jamal', 'Rashid', 'Sales', 41000),
  ('Kara', 'Smith', 'Sales', 39500);

-- Update their salaries in one statement
UPDATE employees
SET salary = CAST(ROUND(salary * 1.10) AS INTEGER)
WHERE first_name IN ('Gina','Hassan','Ilya','Jamal','Kara') AND last_name IN ('Torres','Ali','Kovalenko','Rashid','Smith');

-- 26. Data migration simulation: create employee_archive, move all employees with status 'Inactive' then delete them from original table
DROP TABLE IF EXISTS employee_archive;
CREATE TABLE employee_archive AS TABLE employees WITH NO DATA;

-- Insert inactive employees into archive
INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

-- Delete them from original table
DELETE FROM employees WHERE status = 'Inactive';

-- 27. Complex business logic: Update project end_date +30 days for projects where budget > 50000 AND associated department has more than 3 employees
-- Step 1: find departments with more than 3 employees
WITH dept_counts AS (
  SELECT department AS dept_name, COUNT(*) AS emp_count
  FROM employees
  GROUP BY department
  HAVING COUNT(*) > 3
)
UPDATE projects p
SET end_date = (p.end_date + INTERVAL '30 day')::date
FROM departments d
JOIN dept_counts dc ON d.dept_name = dc.dept_name
WHERE p.dept_id = d.dept_id
  AND p.budget > 50000;

-- --------------------------
-- Sample data insertion (more) to test queries
-- Insert a few more employees with varying hire_date and salary
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
  ('Laura','Brown','IT',75000, DATE '2018-05-20','Active'),
  ('Mark','Green','IT',90000, DATE '2015-03-11','Active'),
  ('Nina','White','Sales',45000, DATE '2024-05-01','Active'),
  ('Oscar','Black','HR',35000, DATE '2023-06-15','Active');

-- Add manager_id relationships (optional): set departments.manager_id using existing employee ids
-- Example: set IT manager to employee with last_name 'Mark'
UPDATE departments SET manager_id = (
  SELECT emp_id FROM employees WHERE last_name = 'Green' LIMIT 1
) WHERE dept_name = 'IT';