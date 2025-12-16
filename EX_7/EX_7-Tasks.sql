/**********************************************************************
 HOMEWORK – ADVANCED SQL PART 4 & 5 
 Focus:
   - Window functions
   - GROUP BY extensions 
 Use existing tables:
   - employee(emp_id, emp_name, region)
   - sale(sale_id, emp_id, sale_date, amount)
   - sales_by_year(region, year, amount)
**********************************************************************/

----------------------------------------------------------------------
-- (OPTIONAL) EXTRA SAMPLE DATA FOR HOMEWORK
----------------------------------------------------------------------
INSERT INTO sale (emp_id, sale_date, amount) VALUES
(1, '2024-02-10', 300.00),
(2, '2024-02-15', 450.00),
(3, '2024-02-20', 200.00),
(4, '2024-02-25', 600.00),
(5, '2024-02-28', 350.00);

----------------------------------------------------------------------
-- TASK HW1 – TOTAL SALES PER EMPLOYEE (WINDOW)
----------------------------------------------------------------------
/*
For each sale, show:

  emp_name
  sale_date
  amount
  total_sales_for_employee   -- total of all their sales

Write a single SELECT query that keeps all rows and adds this total.
*/

-- TODO: write your solution here
-- SELECT
--     ...
-- FROM sale s
-- JOIN employee e ON ...
-- ...;


----------------------------------------------------------------------
-- TASK HW2 – RUNNING TOTAL PER EMPLOYEE (OVER TIME)
----------------------------------------------------------------------
/*
For each employee, in order of sale_date, show:

  emp_name
  sale_date
  amount
  running_total_for_employee   -- cumulative sum up to this row

Write one SELECT query that produces this.
*/

-- TODO: write your solution here
-- SELECT
--     ...
-- FROM sale s
-- JOIN employee e ON ...
-- ...;


----------------------------------------------------------------------
-- TASK HW3 – PREVIOUS SALE PER EMPLOYEE
----------------------------------------------------------------------
/*
For each sale, show:

  emp_name
  sale_date
  amount
  previous_amount_for_employee

previous_amount_for_employee = amount of the previous sale of the SAME
employee (by date). For the first sale of each employee, it should be NULL.
*/

-- TODO: write your solution here
-- SELECT
--     ...
-- FROM sale s
-- JOIN employee e ON ...
-- ...;


----------------------------------------------------------------------
-- TASK HW4 –  REGION / YEAR TOTALS AND GRAND TOTAL
----------------------------------------------------------------------
/*
Using sales_by_year(region, year, amount), produce a report with:

  region
  year
  total_amount

The result should contain:
  - one row per (region, year)
  - one subtotal row per region
  - one grand total row

All of that must come from a single query
*/

-- TODO: write your solution here
-- SELECT
--     ...
-- FROM sales_by_year
-- GROUP BY ...;


----------------------------------------------------------------------
-- TASK HW5 –  MULTIPLE LEVELS IN ONE QUERY
----------------------------------------------------------------------
/*
Using sales_by_year(region, year, amount), produce ONE result set with:

  region
  year
  total_amount

The result must include:
  - totals by (region, year)
  - totals by (region) only
  - grand total (all regions, all years)

All of that must come from a single GROUP BY 
*/

-- TODO: write your solution here
-- SELECT
--     ...
-- FROM sales_by_year
-- GROUP BY GROUPING SETS (...);


----------------------------------------------------------------------
-- END OF HOMEWORK SCRIPT
----------------------------------------------------------------------
