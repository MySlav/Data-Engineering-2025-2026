/**********************************************************************
 ADVANCED SQL – PART 4 & 5 LAB
 Topics:
   - Window functions (aggregate / ranking / value)
   - GROUP BY extensions (ROLLUP, CUBE, GROUPING SETS)
   - Execution plans & basic query optimization
**********************************************************************/

-- 0. CREATE SEPARATE PRACTICE DATABASE
CREATE DATABASE advanced_sql_lab_2;


----------------------------------------------------------------------
-- 1. SCHEMA & SAMPLE DATA
----------------------------------------------------------------------

-- Simple sales set-up:
--   employees selling in regions over time.

CREATE TABLE employee (
    emp_id    SERIAL PRIMARY KEY,
    emp_name  VARCHAR(100) NOT NULL,
    region    VARCHAR(50)  NOT NULL
);

CREATE TABLE sale (
    sale_id    SERIAL PRIMARY KEY,
    emp_id     INT REFERENCES employee(emp_id),
    sale_date  DATE NOT NULL,
    amount     NUMERIC(10,2) NOT NULL
);

-- A more aggregated table for GROUP BY extensions:
CREATE TABLE sales_by_year (
    region    VARCHAR(50) NOT NULL,
    year      INT NOT NULL,
    amount    NUMERIC(12,2) NOT NULL
);

-- Insert employees
INSERT INTO employee (emp_name, region) VALUES
('Alice', 'North'),
('Bob',   'North'),
('Carol', 'South'),
('Derek', 'South'),
('Eva',   'West');

-- Insert sales (multiple months, years, regions)
INSERT INTO sale (emp_id, sale_date, amount) VALUES
(1, '2023-01-10', 500.00),
(1, '2023-02-15', 700.00),
(1, '2023-03-05', 300.00),
(2, '2023-01-20', 400.00),
(2, '2023-02-25', 600.00),
(2, '2023-03-18', 900.00),
(3, '2023-01-12', 200.00),
(3, '2023-02-05', 300.00),
(3, '2023-03-25', 500.00),
(4, '2023-01-30', 1000.00),
(4, '2023-02-10', 800.00),
(5, '2023-02-14', 450.00),
(5, '2023-03-01', 550.00),

-- some 2024 data
(1, '2024-01-11', 650.00),
(2, '2024-01-22', 750.00),
(3, '2024-01-10', 300.00),
(4, '2024-01-19', 900.00),
(5, '2024-01-05', 400.00);

-- Pre-aggregated yearly data for GROUP BY extensions
INSERT INTO sales_by_year (region, year, amount) VALUES
('North', 2023, 3500.00),
('South', 2023, 2800.00),
('West',  2023, 1000.00),
('North', 2024, 1400.00),
('South', 2024, 1200.00),
('West',  2024,  400.00);

----------------------------------------------------------------------
-- 2. WINDOW FUNCTIONS – AGGREGATE
----------------------------------------------------------------------

/*
TOPIC: Aggregate WINDOW functions (SUM, AVG, COUNT, etc. OVER ...)
They let you keep all rows and add aggregates "on the side".

TASK WF1:
For each sale row, show:
  emp_name, sale_date, amount,
  total sales per employee (over ALL time),
  and total sales per employee per year.

(Use SUM(amount) as a window function, partitioning by emp / emp+year.)
*/

-- SAMPLE SOLUTION WF1
SELECT
    e.emp_name,
    s.sale_date,
    s.amount,
    -- total sales per employee across all years
    SUM(s.amount) OVER (
        PARTITION BY s.emp_id
    ) AS total_sales_employee,
    -- total sales per employee per year
    SUM(s.amount) OVER (
        PARTITION BY s.emp_id, EXTRACT(YEAR FROM s.sale_date)
    ) AS total_sales_emp_year
FROM sale s
JOIN employee e ON e.emp_id = s.emp_id
ORDER BY e.emp_name, s.sale_date;


/*
TASK WF2:
Show a "running total" of sales per employee by date.
Columns:
  emp_name, sale_date, amount, running_total

(Use SUM(amount) OVER (PARTITION BY emp_id ORDER BY sale_date).)
*/

-- SAMPLE SOLUTION WF2
SELECT
    e.emp_name,
    s.sale_date,
    s.amount,
    SUM(s.amount) OVER (
        PARTITION BY s.emp_id
        ORDER BY s.sale_date
    ) AS running_total
FROM sale s
JOIN employee e ON e.emp_id = s.emp_id
ORDER BY e.emp_name, s.sale_date;

----------------------------------------------------------------------
-- 3. WINDOW FUNCTIONS – RANKING
----------------------------------------------------------------------

/*
TOPIC: Ranking WINDOW functions (ROW_NUMBER, RANK, DENSE_RANK, NTILE)

TASK R1:
For each year, rank employees by their total yearly sales (highest first).
Show:
  year, emp_name, total_amount, row_number, rank, dense_rank.

Hint:
  - First aggregate sales per emp+year in a subquery or CTE.
  - Then apply window ranking functions PARTITION BY year.
*/

-- SAMPLE SOLUTION R1
WITH yearly_sales AS (
    SELECT
        EXTRACT(YEAR FROM s.sale_date)::int AS year,
        e.emp_id,
        e.emp_name,
        SUM(s.amount) AS total_amount
    FROM sale s
    JOIN employee e ON e.emp_id = s.emp_id
    GROUP BY EXTRACT(YEAR FROM s.sale_date), e.emp_id, e.emp_name
)
SELECT
    year,
    emp_name,
    total_amount,
    ROW_NUMBER()  OVER (PARTITION BY year ORDER BY total_amount DESC) AS rn,
    RANK()        OVER (PARTITION BY year ORDER BY total_amount DESC) AS rnk,
    DENSE_RANK()  OVER (PARTITION BY year ORDER BY total_amount DESC) AS dense_rnk
FROM yearly_sales
ORDER BY year, rnk;

/*
TASK R2 (NTILE):
Within each year, divide employees into 2 groups (top half / bottom half)
based on total yearly sales using NTILE(2).
Show: year, emp_name, total_amount, group_2.
*/

-- SAMPLE SOLUTION R2
WITH yearly_sales AS (
    SELECT
        EXTRACT(YEAR FROM s.sale_date)::int AS year,
        e.emp_id,
        e.emp_name,
        SUM(s.amount) AS total_amount
    FROM sale s
    JOIN employee e ON e.emp_id = s.emp_id
    GROUP BY EXTRACT(YEAR FROM s.sale_date), e.emp_id, e.emp_name
)
SELECT
    year,
    emp_name,
    total_amount,
    NTILE(2) OVER (PARTITION BY year ORDER BY total_amount DESC) AS group_2
FROM yearly_sales
ORDER BY year, group_2, total_amount DESC;

----------------------------------------------------------------------
-- 4. WINDOW FUNCTIONS – VALUE (LAG / LEAD / FIRST_VALUE / LAST_VALUE)
----------------------------------------------------------------------

/*
TOPIC: Value WINDOW functions (LAG, LEAD, FIRST_VALUE, LAST_VALUE)

TASK V1:
For each employee, per sale_date in ascending order, show:
  emp_name, sale_date, amount,
  previous_amount (LAG),
  next_amount (LEAD),
  diff_from_prev (amount - previous_amount).

First row per employee will have previous_amount = NULL.

TASK V2:
For each employee, show each sale and also:
  first_sale_amount_for_emp (FIRST_VALUE),
  last_sale_amount_for_emp  (LAST_VALUE).

Be careful with ORDER BY in the window!
*/

-- SAMPLE SOLUTION V1
SELECT
    e.emp_name,
    s.sale_date,
    s.amount,
    LAG(s.amount)  OVER (
        PARTITION BY s.emp_id
        ORDER BY s.sale_date
    ) AS previous_amount,
    LEAD(s.amount) OVER (
        PARTITION BY s.emp_id
        ORDER BY s.sale_date
    ) AS next_amount,
    s.amount
      - LAG(s.amount) OVER (
            PARTITION BY s.emp_id
            ORDER BY s.sale_date
        ) AS diff_from_prev
FROM sale s
JOIN employee e ON e.emp_id = s.emp_id
ORDER BY e.emp_name, s.sale_date;

-- SAMPLE SOLUTION V2
SELECT
    e.emp_name,
    s.sale_date,
    s.amount,
    FIRST_VALUE(s.amount) OVER (
        PARTITION BY s.emp_id
        ORDER BY s.sale_date
    ) AS first_sale_amount_for_emp,
    LAST_VALUE(s.amount) OVER (
        PARTITION BY s.emp_id
        ORDER BY s.sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_sale_amount_for_emp
FROM sale s
JOIN employee e ON e.emp_id = s.emp_id
ORDER BY e.emp_name, s.sale_date;

----------------------------------------------------------------------
-- 5. GROUP BY EXTENSIONS – ROLLUP, CUBE, GROUPING SETS
----------------------------------------------------------------------

/*
TOPIC: GROUP BY extensions: ROLLUP, CUBE, GROUPING SETS

We use the table sales_by_year(region, year, amount).

TASK G1 – ROLLUP:
Produce a report of total sales:
  columns: region, year, total_amount
with:
  - rows for (region, year)
  - subtotals per region
  - a grand total

Use:
  GROUP BY ROLLUP (region, year).

TASK G2 – GROUPING SETS:
From sales_by_year, produce:
  - totals by (region, year)
  - totals by (year) only
  - grand total
in ONE query using GROUPING SETS.
*/

-- SAMPLE SOLUTION G1 (ROLLUP)
SELECT
    region,
    year,
    SUM(amount) AS total_amount
FROM sales_by_year
GROUP BY ROLLUP (region, year)
ORDER BY region NULLS LAST, year NULLS LAST;

-- SAMPLE SOLUTION G2 (GROUPING SETS)
SELECT
    region,
    year,
    SUM(amount) AS total_amount
FROM sales_by_year
GROUP BY GROUPING SETS (
    (region, year),  -- detailed
    (year),          -- subtotals by year
    ()               -- grand total
)
ORDER BY
    region NULLS LAST,
    year   NULLS LAST;

-- (Optional extra for CUBE, if you want another example for students)
-- Example only (no explicit task):
-- CUBE(region, year) → (region, year), (region), (year), ().
SELECT
    region,
    year,
    SUM(amount) AS total_amount
FROM sales_by_year
GROUP BY CUBE (region, year)
ORDER BY
    region NULLS LAST,
    year   NULLS LAST;

----------------------------------------------------------------------
-- 6. EXECUTION PLAN (EXPLAIN) – TASKS
----------------------------------------------------------------------
-- PREPARATION
SELECT * FROM sale;

INSERT INTO sale (emp_id, sale_date, amount)
SELECT
    e.emp_id,
    -- random-ish date between 2022-01-01 and 2024-12-31 (~3 years)
    DATE '2022-01-01' + (trunc(random() * 1095))::int AS sale_date,
    -- amount between 50 and 1050
    (50 + random() * 1000)::numeric(10,2) AS amount
FROM employee e
CROSS JOIN generate_series(1, 10000) g;

-- Update stats so planner has good estimates
ANALYZE sale;

-- See distribution
SELECT emp_id, COUNT(*) AS rows_per_emp
FROM sale
GROUP BY emp_id
ORDER BY emp_id;

SELECT * FROM sale

/*
TOPIC: SQL execution plan (EXPLAIN / EXPLAIN ANALYZE)

Here we give them queries to run EXPLAIN on.
They run this themselves and interpret the output.

TASK E1:
1) Run this query:

   EXPLAIN ANALYZE
   SELECT *
   FROM sale
   WHERE emp_id = 1
     AND sale_date >= DATE '2023-01-01';

2) Note whether PostgreSQL uses a Seq Scan or Index Scan on sale.

3) Create this index:

   CREATE INDEX idx_sale_emp_date
       ON sale (emp_id, sale_date);

4) Run EXPLAIN ANALYZE again on the same SELECT and
   observe how the plan changes (cost, node type, rows).

*/

-- For convenience, here is the index and the query mentioned in the task:
CREATE INDEX idx_sale_emp_date ON sale (emp_id, sale_date);

EXPLAIN ANALYZE
SELECT *
FROM sale
WHERE emp_id = 1
 AND sale_date >= DATE '2023-01-01';
	 
--DROP INDEX idx_sale_emp_date 
----------------------------------------------------------------------
-- 7. BASIC QUERY OPTIMIZATION – TASKS & EXAMPLES
----------------------------------------------------------------------
/*
TOPIC: Optimizing SQL queries – good practices:
  - Use indexes effectively
  - Avoid SELECT *
  - Optimize JOINs
  - Use UNION ALL instead of UNION when duplicates are impossible / not important
  - Use EXISTS instead of IN with subqueries
  - Avoid unnecessary DISTINCT

Below we add some extra tables + data to better demonstrate these points,
and then show "bad" vs "better" query examples.
*/

----------------------------------------------------------------------
-- 7.0 EXTRA SCHEMA & DATA FOR OPTIMIZATION DEMOS
----------------------------------------------------------------------

-- Customers buying things in the same regions as employees
CREATE TABLE customer (
    customer_id   SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    region        VARCHAR(50)  NOT NULL
);

-- Products
CREATE TABLE product (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(50)  NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL
);

-- Orders (one per customer + date)
CREATE TABLE cust_order (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(customer_id),
    order_date  DATE NOT NULL
);

-- Order items (products per order)
CREATE TABLE order_item (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT REFERENCES cust_order(order_id),
    product_id    INT REFERENCES product(product_id),
    quantity      INT NOT NULL,
    line_amount   NUMERIC(12,2) NOT NULL
);

-- Basic indexes used by the optimizer
CREATE INDEX idx_cust_order_customer_date
    ON cust_order (customer_id, order_date);

CREATE INDEX idx_order_item_order
    ON order_item (order_id);

CREATE INDEX idx_order_item_product
    ON order_item (product_id);

CREATE INDEX idx_customer_region
    ON customer (region);

----------------------------------------------------------------------
-- 7.0.1 INSERT SAMPLE DATA
----------------------------------------------------------------------

-- Insert some customers
INSERT INTO customer (customer_name, region)
VALUES
('Acme Corp',          'North'),
('Globex Ltd',         'North'),
('Initech',            'South'),
('Umbrella Co',        'South'),
('Wayne Enterprises',  'West'),
('Stark Industries',   'West');

-- Add more synthetic customers
INSERT INTO customer (customer_name, region)
SELECT
    'Customer ' || g,
    CASE
        WHEN g % 3 = 1 THEN 'North'
        WHEN g % 3 = 2 THEN 'South'
        ELSE 'West'
    END
FROM generate_series(1, 60) g;

-- Insert some products
INSERT INTO product (product_name, category, unit_price)
VALUES
('Laptop Basic',      'Electronics',  800.00),
('Laptop Pro',        'Electronics', 1200.00),
('Monitor 24"',       'Electronics',  200.00),
('Office Chair',      'Furniture',    150.00),
('Desk',              'Furniture',    300.00),
('Phone Standard',    'Electronics',  500.00),
('Phone Plus',        'Electronics',  900.00),
('Headphones',        'Accessories',  120.00),
('Keyboard',          'Accessories',   60.00),
('Mouse',             'Accessories',   40.00);

-- A bit more variety
INSERT INTO product (product_name, category, unit_price)
SELECT
    'Product ' || g,
    CASE
        WHEN g % 3 = 0 THEN 'Electronics'
        WHEN g % 3 = 1 THEN 'Furniture'
        ELSE 'Accessories'
    END,
    (50 + (g * 5))::numeric(10,2)
FROM generate_series(1, 20) g;

-- Insert orders (spread across 2023–2024)
INSERT INTO cust_order (customer_id, order_date)
SELECT
    (1 + (random() * (SELECT MAX(customer_id) - 1 FROM customer))::int) AS customer_id,
    DATE '2023-01-01' + (trunc(random() * 730))::int  -- ~2 years
FROM generate_series(1, 3000) g;

-- Insert order items (1–3 items per order)
INSERT INTO order_item (order_id, product_id, quantity, line_amount)
SELECT
    o.order_id,
    (1 + (random() * (SELECT MAX(product_id) - 1 FROM product))::int) AS product_id,
    qty,
    (qty * (50 + random() * 500))::numeric(12,2) AS line_amount
FROM cust_order o
CROSS JOIN LATERAL generate_series(1,
    1 + (random() * 2)::int   -- 1 to 3 items per order
) AS g(qty);

-- Update statistics so the planner has reasonable estimates
ANALYZE customer;
ANALYZE product;
ANALYZE cust_order;
ANALYZE order_item;


SELECT * FROM customer;
SELECT * FROM product;
SELECT * FROM cust_order;
SELECT * FROM order_item;


----------------------------------------------------------------------
-- 7.1 AVOID SELECT * (ONLY FETCH WHAT YOU NEED)
----------------------------------------------------------------------

/*
TASK O1:
You want to show TOP 10 customers (name + region + total order amount in 2023).

"Bad" version:
  - SELECT * on multiple joined tables → lots of unnecessary columns.
"Better" version:
  - Only select columns actually needed for the report.
  - Still a simple query, but less data to transfer.

Run both with EXPLAIN ANALYZE and compare:
  - row size (width)
  - total bytes / I/O (total_bytes ≈ actual rows * width; IO - buffers)
  - overall execution time on your machine.
*/

-- BAD VERSION: SELECT * over multiple joins
EXPLAIN ANALYZE
SELECT
    *
FROM customer c
JOIN cust_order o
    ON o.customer_id = c.customer_id
JOIN order_item oi
    ON oi.order_id = o.order_id
WHERE
    o.order_date >= DATE '2023-01-01'
    AND o.order_date <  DATE '2024-01-01'
GROUP BY
    c.customer_id, c.customer_name, c.region, o.order_id, oi.order_item_id
ORDER BY
    SUM(oi.line_amount) DESC
LIMIT 10;

-- BETTER VERSION: select only needed columns
EXPLAIN ANALYZE
SELECT
    c.customer_name,
    c.region,
    SUM(oi.line_amount) AS total_amount_2023
FROM customer c
JOIN cust_order o
    ON o.customer_id = c.customer_id
JOIN order_item oi
    ON oi.order_id = o.order_id
WHERE
    o.order_date >= DATE '2023-01-01'
    AND o.order_date <  DATE '2024-01-01'
GROUP BY
    c.customer_id, c.customer_name, c.region
ORDER BY
    total_amount_2023 DESC
LIMIT 10;

----------------------------------------------------------------------
-- 7.2 OPTIMIZING JOINS & FILTERS (FILTER EARLY)
----------------------------------------------------------------------

/*
TASK O2:
Find total sales per region for orders in 2023.

"Bad" version:
  - Joins everything first, then filters at the end.
  - Less clear where filters apply.
"Better" version:
  - Filter early in subquery / CTE.
  - Make it obvious which subset of data is processed.

The optimizer is usually good at pushing predicates,
but these patterns are still a good habit (and easier to read).
*/

-- BAD VERSION: filter late
--EXPLAIN ANALYZE
SELECT
    c.region,
    SUM(oi.line_amount) AS total_amount_2023
FROM customer c
JOIN cust_order o
    ON o.customer_id = c.customer_id
JOIN order_item oi
    ON oi.order_id = o.order_id
WHERE
    o.order_date >= DATE '2023-01-01'
    AND o.order_date <  DATE '2024-01-01'
GROUP BY
    c.region
ORDER BY
    c.region;

-- BETTER VERSION: filter orders first in a CTE / subquery
--EXPLAIN ANALYZE
WITH orders_2023 AS (
    SELECT *
    FROM cust_order
    WHERE order_date >= DATE '2023-01-01'
      AND order_date <  DATE '2024-01-01'
)
SELECT
    c.region,
    SUM(oi.line_amount) AS total_amount_2023
FROM orders_2023 o
JOIN customer c
    ON c.customer_id = o.customer_id
JOIN order_item oi
    ON oi.order_id = o.order_id
GROUP BY
    c.region
ORDER BY
    c.region;

----------------------------------------------------------------------
-- 7.3 UNION vs UNION ALL
----------------------------------------------------------------------

/*
TASK O3:
We want a list of regions that had:
  - any employee sale in 2023 (from sale/employee), and
  - any customer order in 2023 (from customer/cust_order).

Assume:
  - regions in employee and customer are the same naming scheme,
  - duplicates are OK and not needed to be removed.

Compare:
  - UNION (removes duplicates → needs sort or hash),
  - UNION ALL (no duplicate removal).

When you KNOW the two sets are disjoint OR you don't care about duplicates,
prefer UNION ALL.
*/

-- Get regions with employee sales in 2023
EXPLAIN ANALYZE
WITH emp_regions AS (
    SELECT DISTINCT e.region
    FROM sale s
    JOIN employee e ON e.emp_id = s.emp_id
    WHERE s.sale_date >= DATE '2023-01-01'
      AND s.sale_date <  DATE '2024-01-01'
),
-- Get regions with customer orders in 2023
cust_regions AS (
    SELECT DISTINCT c.region
    FROM cust_order o
    JOIN customer c ON c.customer_id = o.customer_id
    WHERE o.order_date >= DATE '2023-01-01'
      AND o.order_date <  DATE '2024-01-01'
)

-- BAD VERSION: UNION (does duplicate elimination)
SELECT region FROM emp_regions
UNION
SELECT region FROM cust_regions;

-- BETTER VERSION: UNION ALL (if duplicates do not matter)
EXPLAIN ANALYZE
WITH emp_regions AS (
    SELECT DISTINCT e.region
    FROM sale s
    JOIN employee e ON e.emp_id = s.emp_id
    WHERE s.sale_date >= DATE '2023-01-01'
      AND s.sale_date <  DATE '2024-01-01'
),
-- Get regions with customer orders in 2023
cust_regions AS (
    SELECT DISTINCT c.region
    FROM cust_order o
    JOIN customer c ON c.customer_id = o.customer_id
    WHERE o.order_date >= DATE '2023-01-01'
      AND o.order_date <  DATE '2024-01-01'
)
SELECT region FROM emp_regions
UNION ALL
SELECT region FROM cust_regions;

----------------------------------------------------------------------
-- 7.4 EXISTS vs IN
----------------------------------------------------------------------

-- Add 100k more orders, heavier on 2024 to hit your EXISTS vs IN queries
INSERT INTO cust_order (customer_id, order_date)
SELECT
    (1 + (random() * (SELECT MAX(customer_id) - 1 FROM customer))::int) AS customer_id,
    DATE '2024-01-01' + (trunc(random() * 365))::int  -- all in 2024
FROM generate_series(1, 100000) g;

-- Add items for those new orders
INSERT INTO order_item (order_id, product_id, quantity, line_amount)
SELECT
    o.order_id,
    (1 + (random() * (SELECT MAX(product_id) - 1 FROM product))::int) AS product_id,
    qty,
    (qty * (50 + random() * 500))::numeric(12,2) AS line_amount
FROM cust_order o
JOIN LATERAL generate_series(
    1,
    1 + (random() * 2)::int    -- 1–3 items per order
) AS g(qty)
    ON TRUE
WHERE o.order_id > (
    SELECT COALESCE(MAX(order_id) - 100000, 0)
    FROM cust_order
);

ANALYZE cust_order;
ANALYZE order_item;

/*
TASK O4:
Find customers who have placed at least one order in 2024.

"Bad" version:
  - Uses IN with a subquery returning many rows.
"Better" version:
  - Uses EXISTS – stops scanning as soon as one match is found.
  - Often more efficient and more expressive for "at least one" logic.

Run EXPLAIN ANALYZE and compare.
*/

-- BAD VERSION: IN subquery
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.customer_name,
    c.region
FROM customer c
WHERE c.customer_id IN (
    SELECT o.customer_id
    FROM cust_order o
    WHERE o.order_date >= DATE '2024-01-01'
      AND o.order_date <  DATE '2025-01-01'
);

-- BETTER VERSION: EXISTS
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.customer_name,
    c.region
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM cust_order o
    WHERE o.customer_id = c.customer_id
      AND o.order_date >= DATE '2024-01-01'
      AND o.order_date <  DATE '2025-01-01'
);

-- PROBABLY YOU WON'T SEE A DIFFERENCE
-- PostgreSQL shows the same or very similar execution plan
/*
Reason:
- The planner often rewrites `IN (subquery)` into a *semi join* internally
  (a join that only checks whether at least one matching row exists),
  which is the same logical operation that `EXISTS` expresses.
- Because of that, both queries use the same Nested Loop Semi Join node,
  have (almost) the same estimated cost, and produce the same result set.

So in this case, `IN` and `EXISTS` are equivalent in both result and plan.
We still prefer `EXISTS` stylistically for "at least one matching row"
because it makes the intent clearer, avoids subtle NULL-related issues in
other patterns, and not all RDBMS optimizers are as smart as PostgreSQL's. :)
*/

----------------------------------------------------------------------
-- 7.5 AVOID UNNECESSARY DISTINCT
----------------------------------------------------------------------

/*
TASK O5:
Count how many customers per region have placed at least one order.

"Bad" version:
  - Joins orders and customers, then uses COUNT(DISTINCT ...)
    to undo duplicates created by the join.
"Better" versions:
  - Use EXISTS or GROUP BY in a subquery to pre-aggregate,
    then count without DISTINCT.

Again: run EXPLAIN ANALYZE and compare the plans & cost estimates.
*/

-- BAD VERSION: COUNT(DISTINCT) on joined table
EXPLAIN ANALYZE
SELECT
    c.region,
    COUNT(DISTINCT c.customer_id) AS customers_with_orders
FROM customer c
JOIN cust_order o
    ON o.customer_id = c.customer_id
GROUP BY
    c.region
ORDER BY
    c.region;

-- BETTER VERSION 1: subquery with GROUP BY
EXPLAIN ANALYZE
WITH customers_with_orders AS (
    SELECT DISTINCT customer_id
    FROM cust_order
)
SELECT
    c.region,
    COUNT(*) AS customers_with_orders
FROM customer c
JOIN customers_with_orders cwo
    ON cwo.customer_id = c.customer_id
GROUP BY
    c.region
ORDER BY
    c.region;

-- BETTER VERSION 2: EXISTS (semantically clear)
EXPLAIN ANALYZE
SELECT
    c.region,
    COUNT(*) AS customers_with_orders
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM cust_order o
    WHERE o.customer_id = c.customer_id
)
GROUP BY
    c.region
ORDER BY
    c.region;

----------------------------------------------------------------------
-- 7.6 INDEX USAGE EXAMPLE (ON NEW TABLES)
----------------------------------------------------------------------

/*
TASK O6:
1) Run the query below (with EXPLAIN ANALYZE) BEFORE and AFTER
   creating the index idx_cust_order_customer_date (already created above, so first DROP it).
2) Observe:
   - Node type (Seq Scan vs Index Scan),
   - Estimated vs actual rows,
   - Total execution time.

The point is similar to TASK E1 on table sale,
but now using the cust_order table.
*/

-- Example query to check index usage

DROP INDEX idx_cust_order_customer_date;

CREATE INDEX idx_cust_order_customer_date
    ON cust_order (customer_id, order_date);

ANALYZE cust_order;

EXPLAIN ANALYZE
SELECT *
FROM cust_order
WHERE customer_id = 1
  AND order_date >= DATE '2023-07-01'
  AND order_date <  DATE '2023-12-31';
----------------------------------------------------------------------
-- END
----------------------------------------------------------------------

