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
SELECT * FROM employee
WHERE dept_id IS NULL 
;
INSERT INTO employee
VALUES  (8, 'Đuro', NULL, NULL, '2025-10-01', 10000000)

SELECT * FROM employee_project

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
-- J1
SELECT
    e.emp_name,
    p.proj_name,
    d.dept_name,
    ep.role,
    ep.hours
FROM employee_project ep
JOIN employee e   ON e.emp_id = ep.emp_id
JOIN project p    ON p.proj_id = ep.proj_id
LEFT JOIN department d ON d.dept_id = p.dept_id
ORDER BY p.proj_name, e.emp_name;

-- J2
SELECT
    e.emp_name,
    p.proj_name,
    ep.role,
    ep.hours
FROM employee e
LEFT JOIN employee_project ep ON ep.emp_id = e.emp_id
LEFT JOIN project p           ON p.proj_id = ep.proj_id
ORDER BY e.emp_name;

-- J3 (FULL OUTER JOIN example)
SELECT * FROM Project;

INSERT INTO Project
VALUES ( 5,'Data Engineering', 1, '2025-12-08', NULL)

SELECT
    e.emp_name,
    p.proj_name,
    ep.role,
    ep.hours
FROM employee_project ep
FULL JOIN employee e ON e.emp_id = ep.emp_id
FULL JOIN project  p ON p.proj_id = ep.proj_id
ORDER BY COALESCE(p.proj_name, 'No Project'), e.emp_name;

-- J4 (ANTI JOIN)
SELECT e.*
FROM employee e
JOIN department d ON d.dept_id = e.dept_id AND d.dept_name = 'IT'
LEFT JOIN employee_project ep ON ep.emp_id = e.emp_id
WHERE ep.emp_id IS NULL;

--  J5 (SELF JOIN)
SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employee e
LEFT JOIN employee m ON m.emp_id = e.manager_id
ORDER BY manager NULLS FIRST, employee;
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




--  S1
SELECT email FROM employee
UNION ALL 
SELECT email FROM candidate
UNION ALL
SELECT email FROM ex_employee
ORDER BY email;

-- S2
SELECT email, 'candidate'   AS source FROM candidate
UNION ALL
SELECT email, 'ex_employee' AS source FROM ex_employee
ORDER BY email, source;


SELECT x.email, COUNT(1) FROM (
SELECT email, 'candidate'   AS source FROM candidate
UNION ALL
SELECT email, 'ex_employee' AS source FROM ex_employee
) x
GROUP BY x.email
ORDER BY x.email

-- S3
SELECT email
FROM candidate
INTERSECT
SELECT email
FROM ex_employee;

-- S4
SELECT email
FROM candidate
EXCEPT
SELECT email
FROM ex_employee;
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

--  Q1
SELECT *
FROM employee
WHERE salary > (SELECT AVG(salary) FROM employee);

-- Q2
SELECT *
FROM (
    SELECT
        d.dept_name,
        COUNT(e.emp_id)      AS emp_count,
        AVG(e.salary)        AS avg_salary
    FROM department d
    LEFT JOIN employee e ON e.dept_id = d.dept_id
    GROUP BY d.dept_name
) AS dept_stats
WHERE avg_salary > 55000;

-- 2nd solution
SELECT
d.dept_name,
COUNT(e.emp_id)      AS emp_count,
AVG(e.salary)        AS avg_salary
FROM department d
LEFT JOIN employee e ON e.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING AVG(e.salary) > 55000;


-- Q3
SELECT
    e.emp_name,
    (
        SELECT COUNT(*)
        FROM employee_project ep
        WHERE ep.emp_id = e.emp_id
    ) AS project_count
FROM employee e
ORDER BY e.emp_name;

-- Q4 (correlated in WHERE)
SELECT e.emp_name
FROM employee e
WHERE (
    SELECT COUNT(*)
    FROM employee_project ep
    WHERE ep.emp_id = e.emp_id
) > 1;

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
-- SOURCE QUERY example for P1
SELECT
    d.dept_name,
    ep.role,
    SUM(ep.hours) AS total_hours
FROM employee_project ep
JOIN employee e   ON e.emp_id = ep.emp_id
JOIN department d ON d.dept_id = e.dept_id
GROUP BY d.dept_name, ep.role
ORDER BY d.dept_name, ep.role;

--  P1 -- not good because of ordering of categories !!!!
SELECT *
FROM crosstab(
    $$
    SELECT
        d.dept_name::text,
        ep.role::text,
        SUM(ep.hours)::int AS total_hours
    FROM employee_project ep
    JOIN employee e   ON e.emp_id = ep.emp_id
    JOIN department d ON d.dept_id = e.dept_id
    GROUP BY d.dept_name, ep.role
    ORDER BY d.dept_name, ep.role
    $$
) AS ct(
    dept_name      text,
    Lead_hours     int,
    Analyst_hours  int,
    Architect_hours int,
    Coordinator_hours int,
    Developer_hours int
);
-- safe solution to use 4 argument crosstab
SELECT *
FROM crosstab(
    $$
    SELECT
        d.dept_name::text,
        ep.role::text,
        SUM(ep.hours)::int AS total_hours
    FROM employee_project ep
    JOIN employee e   ON e.emp_id = ep.emp_id
    JOIN department d ON d.dept_id = e.dept_id
    GROUP BY d.dept_name, ep.role
    ORDER BY d.dept_name, ep.role
    $$,
    $$
    SELECT unnest(ARRAY['Lead','Analyst','Architect','Coordinator','Developer'])
    $$
) AS ct(
    dept_name          text,
    Lead_hours         int,
    Analyst_hours      int,
    Architect_hours    int,
    Coordinator_hours  int,
    Developer_hours    int
);

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
-- C1
WITH emp_hours AS (
    SELECT
        e.emp_id,
        e.emp_name,
        COALESCE(SUM(ep.hours),0) AS total_hours
    FROM employee e
    LEFT JOIN employee_project ep ON ep.emp_id = e.emp_id
    GROUP BY e.emp_id, e.emp_name
)
SELECT *
FROM emp_hours
WHERE total_hours > 200
ORDER BY total_hours DESC;

--  C2
WITH high_salary AS (
    SELECT emp_id, emp_name
    FROM employee
    WHERE salary > 60000
),
trained_sql AS (
    SELECT DISTINCT e.emp_id, e.emp_name
    FROM employee e
    JOIN employee_training et ON et.emp_id = e.emp_id
    JOIN training_course tc   ON tc.course_id = et.course_id
    WHERE tc.category = 'SQL'
)
SELECT hs.emp_name
FROM high_salary hs
JOIN trained_sql ts ON ts.emp_id = hs.emp_id;
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

SELECT * FROM employee
;
UPDATE employee
SET manager_id = 8
WHERE emp_id = 1

UPDATE employee
SET dept_id = 1
WHERE emp_id = 8


-- SAMPLE SOLUTION R1
WITH RECURSIVE org AS (
    -- anchor: department heads
    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        d.dept_name,
        0 AS level
    FROM employee e
    JOIN department d ON d.dept_id = e.dept_id
    WHERE e.manager_id IS NULL

    UNION ALL

    -- recursive: direct reports
    SELECT
        child.emp_id,
        child.emp_name,
        child.manager_id,
        d.dept_name,
        parent.level + 1 AS level
    FROM employee child
    JOIN org parent ON parent.emp_id = child.manager_id
    JOIN department d ON d.dept_id = child.dept_id
)
SELECT
    dept_name,
    emp_name,
    level
FROM org
ORDER BY dept_name, level, emp_name;

-- SAMPLE SOLUTION R2 (chain under Alice)
WITH RECURSIVE it_chain AS (
    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        0 AS level
    FROM employee e
    WHERE e.emp_name = 'Alice'

    UNION ALL

    SELECT
        child.emp_id,
        child.emp_name,
        child.manager_id,
        parent.level + 1 AS level
    FROM employee child
    JOIN it_chain parent ON parent.emp_id = child.manager_id
)
SELECT *
FROM it_chain
ORDER BY level, emp_name;

----------------------------------------------------------------------
-- END OF LAB SCRIPT
----------------------------------------------------------------------