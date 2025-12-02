/**********************************************************************
 ADVANCED SQL PRACTICE DATABASE (PostgreSQL)
 Topics: JOINS, SET OPERATORS, SUBQUERIES, PIVOT (crosstab), CTE, RECURSIVE CTE
**********************************************************************/

-- Create a separate database for the lab
CREATE DATABASE advanced_sql_lab;

----------------------------------------------------------------------
-- 1. SCHEMA & SAMPLE DATA
----------------------------------------------------------------------

-- Departments
CREATE TABLE department (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(100) NOT NULL
);

-- Employees (with manager hierarchy)
CREATE TABLE employee (
    emp_id      SERIAL PRIMARY KEY,
    emp_name    VARCHAR(100) NOT NULL,
    dept_id     INT REFERENCES department(dept_id),
    manager_id  INT REFERENCES employee(emp_id),
    hire_date   DATE NOT NULL,
    salary      NUMERIC(10,2) NOT NULL
);

-- Projects
CREATE TABLE project (
    proj_id     SERIAL PRIMARY KEY,
    proj_name   VARCHAR(100) NOT NULL,
    dept_id     INT REFERENCES department(dept_id),
    start_date  DATE NOT NULL,
    end_date    DATE
);

-- Which employees work on which projects
CREATE TABLE employee_project (
    emp_id      INT REFERENCES employee(emp_id),
    proj_id     INT REFERENCES project(proj_id),
    role        VARCHAR(50),
    hours       INT CHECK (hours >= 0),
    PRIMARY KEY (emp_id, proj_id)
);

-- Training courses
CREATE TABLE training_course (
    course_id   SERIAL PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    category    VARCHAR(50) NOT NULL   -- e.g. 'SQL', 'Python', 'Soft Skills'
);

-- Employee completions
CREATE TABLE employee_training (
    emp_id      INT REFERENCES employee(emp_id),
    course_id   INT REFERENCES training_course(course_id),
    completed_on DATE NOT NULL,
    score       INT CHECK (score BETWEEN 0 AND 100),
    PRIMARY KEY (emp_id, course_id)
);

-- For SET operator practice:
CREATE TABLE candidate (
    cand_id     SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE ex_employee (
    ex_emp_id   SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL
);

----------------------------------------------------------------------
-- INSERT SAMPLE DATA
----------------------------------------------------------------------

INSERT INTO department (dept_name) VALUES
('IT'),
('HR'),
('Finance');

-- Employees
INSERT INTO employee (emp_name, dept_id, manager_id, hire_date, salary) VALUES
('Alice', 1, NULL, '2018-01-10', 60000),  -- Head of IT
('Bob',   1, 1,    '2019-03-15', 45000),
('Carol', 1, 1,    '2020-07-01', 48000),
('Derek', 2, NULL, '2017-05-20', 65000),  -- Head of HR
('Eva',   2, 4,    '2021-02-10', 40000),
('Frank', 3, NULL, '2016-09-05', 70000),  -- Head of Finance
('Grace', 3, 6,    '2022-01-12', 42000);

-- Projects
INSERT INTO project (proj_name, dept_id, start_date, end_date) VALUES
('Website Redesign', 1, '2023-01-01', NULL),
('Data Warehouse',   1, '2023-04-01', NULL),
('Recruitment 2023', 2, '2023-02-01', '2023-10-01'),
('Salary Review',    3, '2023-03-01', NULL);

-- Employee–Project assignments
INSERT INTO employee_project (emp_id, proj_id, role, hours) VALUES
(1, 1, 'Lead',       200),
(2, 1, 'Developer',  150),
(3, 1, 'Developer',  120),
(1, 2, 'Architect',  80),
(3, 2, 'Developer',  160),
(4, 3, 'Lead',       100),
(5, 3, 'Coordinator',80),
(6, 4, 'Lead',       90),
(7, 4, 'Analyst',    70);

-- Training courses
INSERT INTO training_course (title, category) VALUES
('Advanced SQL', 'SQL'),
('Intro to Python', 'Python'),
('Effective Communication', 'Soft Skills'),
('Data Modeling', 'SQL');

-- Employee training completions
INSERT INTO employee_training (emp_id, course_id, completed_on, score) VALUES
(1, 1, '2023-02-10', 88),
(2, 1, '2023-02-15', 92),
(3, 1, '2023-02-20', 75),
(2, 2, '2023-03-05', 85),
(5, 3, '2023-04-01', 90),
(7, 4, '2023-05-10', 80),
(1, 4, '2023-05-15', 95);

-- Candidates and ex employees
INSERT INTO candidate (full_name, email) VALUES
('Ivy Cooper', 'ivy@example.com'),
('Jack Brown','jack@example.com'),
('Carol IT','carol.it@example.com');  -- similar name but not same email

INSERT INTO ex_employee (full_name, email) VALUES
('Old Alice', 'alice.old@example.com'),
('Retired Bob','bob.retired@example.com'),
('Jack Brown','jack@example.com');    -- same as candidate

----------------------------------------------------------------------
-- 2. TASKS: JOINS
----------------------------------------------------------------------

/*
TASK J1 
List all project assignments with:
employee name, project name, department name, role, and hours.
Sort by project then employee.

TASK J2 
Show all employees and the projects they work on (if any).
Employees without projects should still appear.

TASK J3 
Show all projects and employees on them, but also show projects
that currently have no employees.

TASK J4 
List employees in IT department who are NOT assigned to any project.

TASK J5 
Show each employee together with their manager name (if they have one).
*/

----------------------------------------------------------------------
-- 3. TASKS: SET OPERATORS (UNION / UNION ALL / INTERSECT / EXCEPT)
----------------------------------------------------------------------

/*
TASK S1
Get a list of all DISTINCT emails that belong to:
  - current employees
  - candidates
  - ex-employees

TASK S2 
Show all emails from candidates and ex-employees,
including duplicates, and let students count how many
times each email appears.

TASK S3 
Find people (by email) who are BOTH in candidates AND ex-employees.

TASK S4 
Find candidate emails that are NOT present in ex-employees.
*/

-- To have emails for employees:
ALTER TABLE employee ADD COLUMN email VARCHAR(100);
UPDATE employee SET email = LOWER(emp_name) || '@company.com';

----------------------------------------------------------------------
-- 4. TASKS: SUBQUERIES & CORRELATED SUBQUERIES
----------------------------------------------------------------------

/*
TASK Q1 (subquery in WHERE)
Find employees whose salary is ABOVE the average salary in the company.

TASK Q2 (subquery in FROM)
For each department, calculate:
 - number of employees
 - average salary
Then, in outer query, show only departments with avg salary > 55000.

TASK Q3 (subquery in SELECT)
For each employee, show their name and
the number of projects they are assigned to (as a scalar subquery).

TASK Q4 (CORRELATED SUBQUERY)
Find employees who work on MORE than one project.
*/


----------------------------------------------------------------------
-- 5. TASKS: PIVOT / CROSSTAB (PostgreSQL tablefunc)
----------------------------------------------------------------------

-- Enable extension (once per DB)
CREATE EXTENSION IF NOT EXISTS tablefunc;

/*
TASK P1
Build a pivot table that shows, for each department,
the total HOURS spent on projects in 2023 by ROLE,
with columns: dept_name, Lead_hours, Developer_hours, Analyst_hours.

Hint: you must:
 - write a source query returning (dept_name, role, total_hours)
 - use crosstab(source_query) and define output columns.
*/

----------------------------------------------------------------------
-- 6. TASKS: CTEs (non-recursive)
----------------------------------------------------------------------

/*
TASK C1
Using a CTE, first calculate total project hours per employee
(emp_id, emp_name, total_hours). In the main query, show only
employees with total_hours > 200.

TASK C2
Build two CTEs:
 - high_salary: employees with salary > 60,000
 - trained_sql: employees who completed any course in 'SQL' category
Then select employees who are BOTH high_salary and trained in SQL.
*/

----------------------------------------------------------------------
-- 7. TASKS: RECURSIVE CTE (hierarchy)
----------------------------------------------------------------------

/*
TASK R1
Using a RECURSIVE CTE on employee(manager_id), produce
an "org chart" starting from each department head (manager_id IS NULL).
Show: dept_name, emp_name, manager_name, level (0 for head, 1 for direct reports, etc).

TASK R2
Using a RECURSIVE CTE, for a single department head (e.g. Alice in IT),
list all people in their management chain (all levels below them).
*/



----------------------------------------------------------------------
-- END OF LAB SCRIPT
----------------------------------------------------------------------
