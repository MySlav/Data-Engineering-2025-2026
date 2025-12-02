
/**********************************************************************
 * 0. CHECK SCHEMA & SAMPLE DATA (run in the transactional DB)
 *********************************************************************/


-- See which tables we have in the transactional database
-- (for orientation only)
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Peek at data
SELECT * FROM Customer ORDER BY IDCustomer;
SELECT * FROM Product ORDER BY IDProduct;
SELECT * FROM CustomerOrder ORDER BY IDOrder;
SELECT * FROM OrderItem ORDER BY IDOrderItem;
SELECT * FROM Payment ORDER BY IDPayment;


/**********************************************************************
 * 1. JOINS
 *********************************************************************/

-- Task JOIN-1:
--   List all order lines with:
--   customer name, order id, order date, product name, quantity, line total.
--   Use INNER JOIN between Customer, CustomerOrder, OrderItem, Product.
-- Solution:
SELECT
    c.IDCustomer,
    c.name         AS customer_name,
    o.IDOrder,
    o.order_date,
    p.product_name,
    oi.quantity,
    oi.quantity * oi.unit_price AS line_total
FROM CustomerOrder o
JOIN Customer   c ON c.IDCustomer = o.CustomerID
JOIN OrderItem  oi ON oi.OrderID  = o.IDOrder
JOIN Product    p ON p.IDProduct  = oi.ProductID
ORDER BY o.IDOrder, p.product_name;


-- Task JOIN-2:
--   For every customer, show their name and total amount spent.
--   Customers without orders should still be listed (with total 0).
--   Use LEFT JOIN + aggregation.
-- Solution:
SELECT
    c.IDCustomer,
    c.name AS customer_name,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
FROM Customer c
LEFT JOIN CustomerOrder o ON o.CustomerID = c.IDCustomer
LEFT JOIN OrderItem     oi ON oi.OrderID  = o.IDOrder
GROUP BY c.IDCustomer, c.name
ORDER BY c.IDCustomer;


-- Task JOIN-3:
--   Show all payments and, using a RIGHT JOIN, include any orders
--   that do NOT have a payment (payment columns should be NULL).
-- Solution:
SELECT
    o.IDOrder,
    o.order_date,
    pmt.IDPayment,
    pmt.payment_date,
    pmt.payment_method,
    pmt.amount
FROM Payment pmt
RIGHT JOIN CustomerOrder o ON o.IDOrder = pmt.OrderID
ORDER BY o.IDOrder;


-- Task JOIN-4 (FULL OUTER JOIN):
--   Imagine we want to check data quality between OrderItem and Payment.
--   Show all order IDs that appear either in OrderItem or Payment
--   and indicate where they are missing.
-- Solution:
SELECT
    COALESCE(oi.OrderID, pmt.OrderID) AS order_id,
    CASE WHEN oi.OrderID  IS NULL THEN 'missing in OrderItem'  ELSE 'present' END AS in_orderitem,
    CASE WHEN pmt.OrderID IS NULL THEN 'missing in Payment'    ELSE 'present' END AS in_payment
FROM OrderItem oi
FULL OUTER JOIN Payment pmt
    ON pmt.OrderID = oi.OrderID
ORDER BY order_id;


-- Task JOIN-5 (LEFT ANTI JOIN):
--   Find customers who have NEVER placed an order.
--   Use a LEFT JOIN + WHERE ... IS NULL pattern (anti join).
-- Solution:
SELECT c.*
FROM Customer c
LEFT JOIN CustomerOrder o
       ON o.CustomerID = c.IDCustomer
WHERE o.IDOrder IS NULL;


-- Task JOIN-6 (CROSS JOIN):
--   Create a small “promotion matrix”: every product × every payment_method
--   that the business supports.
--   Use CROSS JOIN between Product and a derived table of methods.
-- Solution:
SELECT
    p.IDProduct,
    p.product_name,
    m.payment_method
FROM Product p
CROSS JOIN (
    VALUES ('Credit Card'),
           ('Cash'),
           ('PayPal'),
           ('Bank Transfer')
) AS m(payment_method)
ORDER BY p.IDProduct, m.payment_method;


/**********************************************************************
 * 2. SET OPERATORS: UNION, UNION ALL, INTERSECT, EXCEPT
 *********************************************************************/

-- Task SET-1:
--   Get a list of all “actors” that appear in the system:
--   customer emails and a synthetic “support@shop.example” email.
--   Use UNION (distinct).
-- Solution:
SELECT email AS actor_email
FROM Customer
UNION
SELECT 'support@shop.example' AS actor_email
ORDER BY actor_email;


-- Task SET-2:
--   Show all product categories that appear either:
--     - as Product.category, or
--     - as a “special” category we’d like to start selling: 'Books'.
--   Use UNION ALL and notice duplicates.
-- Solution:
SELECT category
FROM Product
UNION ALL
SELECT 'Books' AS category
ORDER BY category;


-- Task SET-3 (INTERSECT):
--   Suppose “Electronics” and “Accessories” are categories.
--   Build two sets:
--     S1 = products with price >= 300
--     S2 = products whose name contains the letter 'a' (case-insensitive)
--   Use INTERSECT to find products in both sets.
-- Solution:
SELECT IDProduct, product_name
FROM Product
WHERE price >= 300

INTERSECT

SELECT IDProduct, product_name
FROM Product
WHERE LOWER(product_name) LIKE '%a%';


-- Task SET-4 (EXCEPT):
--   Find customers that HAVE placed orders (appear in CustomerOrder)
--   but currently have no payments at all.
--   Do this using EXCEPT between two sets of customer IDs.
-- Solution:
--   Set A: customers who have at least one order
WITH customers_with_orders AS (
    SELECT DISTINCT CustomerID
    FROM CustomerOrder
),
--   Set B: customers who have at least one payment
customers_with_payments AS (
    SELECT DISTINCT o.CustomerID
    FROM Payment p
    JOIN CustomerOrder o ON o.IDOrder = p.OrderID
)
SELECT cwo.CustomerID
FROM customers_with_orders cwo
EXCEPT
SELECT cwp.CustomerID
FROM customers_with_payments cwp
ORDER BY CustomerID;


/**********************************************************************
 * 3. SUBQUERIES & CORRELATED SUBQUERIES
 *********************************************************************/

-- Task SUB-1 (subquery in WHERE):
--   Find customers whose total spending is ABOVE the overall average
--   spending per customer.
--   Use a subquery for the average.
-- Solution:
WITH per_customer AS (
    SELECT
        c.IDCustomer,
        SUM(oi.quantity * oi.unit_price) AS total_spent
    FROM Customer c
    JOIN CustomerOrder o ON o.CustomerID = c.IDCustomer
    JOIN OrderItem     oi ON oi.OrderID  = o.IDOrder
    GROUP BY c.IDCustomer
)
SELECT *
FROM per_customer
WHERE total_spent >
      (SELECT AVG(total_spent) FROM per_customer);


-- Task SUB-2 (correlated subquery):
--   Return all customers who have placed MORE THAN ONE order.
--   Use a correlated subquery that counts orders per customer.
-- Solution:
SELECT c.*
FROM Customer c
WHERE (
    SELECT COUNT(*)
    FROM CustomerOrder o
    WHERE o.CustomerID = c.IDCustomer   -- correlation
) > 1;


-- Task SUB-3 (subquery in FROM):
--   Build a subquery that aggregates per order (order total and quantity),
--   then select from that subquery and filter orders above 500 EUR.
-- Solution:
SELECT *
FROM (
    SELECT
        o.IDOrder,
        o.CustomerID,
        o.order_date,
        SUM(oi.quantity * oi.unit_price) AS total_amount,
        SUM(oi.quantity) AS total_quantity
    FROM CustomerOrder o
    JOIN OrderItem oi ON oi.OrderID = o.IDOrder
    GROUP BY o.IDOrder, o.CustomerID, o.order_date
) AS order_summary
WHERE total_amount > 500
ORDER BY IDOrder;


/**********************************************************************
 * 4. CROSSTAB / PIVOT (PostgreSQL tablefunc.crosstab)
 *********************************************************************/

-- Enable the extension once in the transactional database:
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Task PIVOT-1:
--   Create a pivot table showing, per customer, total amount paid
--   by payment_method (Credit Card, PayPal, Bank Transfer).
--   Use crosstab(source_query) FROM tablefunc.
--
-- Step 1: Source query for crosstab:
--   required structure: (row_name, category, value)
--   Here: (customer_name, payment_method, total_amount)
WITH customer_payment AS (
    SELECT
        c.name         AS customer_name,
        p.payment_method,
        SUM(p.amount)  AS total_amount
    FROM Payment p
    JOIN CustomerOrder o ON o.IDOrder = p.OrderID
    JOIN Customer c       ON c.IDCustomer = o.CustomerID
    GROUP BY c.name, p.payment_method
)
SELECT * FROM customer_payment ORDER BY customer_name, payment_method;

-- Step 2: actual pivot using crosstab.
--   We explicitly declare the resulting columns and types.
SELECT *
FROM crosstab(
        $$
        SELECT
            c.name::text        AS customer_name,
            p.payment_method::text,
            SUM(p.amount)::numeric
        FROM Payment p
        JOIN CustomerOrder o ON o.IDOrder = p.OrderID
        JOIN Customer c       ON c.IDCustomer = o.CustomerID
        GROUP BY c.name, p.payment_method
        ORDER BY c.name, p.payment_method
        $$)
AS ct (
    customer_name      text,
    credit_card_total  numeric,
    paypal_total       numeric,
    bank_transfer_total numeric
);


/**********************************************************************
 * 5. COMMON TABLE EXPRESSIONS (CTEs)
 *********************************************************************/

-- Task CTE-1:
--   Re-write the “order_summary” query from SUB-3 as a CTE
--   and then join it to Customer to get customer names.
-- Solution:
WITH order_summary AS (
    SELECT
        o.IDOrder,
        o.CustomerID,
        o.order_date,
        SUM(oi.quantity * oi.unit_price) AS total_amount,
        SUM(oi.quantity) AS total_quantity
    FROM CustomerOrder o
    JOIN OrderItem oi ON oi.OrderID = o.IDOrder
    GROUP BY o.IDOrder, o.CustomerID, o.order_date
)
SELECT
    os.IDOrder,
    c.name AS customer_name,
    os.order_date,
    os.total_amount,
    os.total_quantity
FROM order_summary os
JOIN Customer c ON c.IDCustomer = os.CustomerID
ORDER BY os.IDOrder;


-- Task CTE-2 (multiple CTEs):
--   Build:
--     1) per_customer_totals (total spent)
--     2) big_spenders: customers with total_spent > 1000
--   Then return big_spenders with their totals.
-- Solution:
WITH per_customer_totals AS (
    SELECT
        c.IDCustomer,
        c.name,
        SUM(oi.quantity * oi.unit_price) AS total_spent
    FROM Customer c
    JOIN CustomerOrder o ON o.CustomerID = c.IDCustomer
    JOIN OrderItem oi     ON oi.OrderID  = o.IDOrder
    GROUP BY c.IDCustomer, c.name
),
big_spenders AS (
    SELECT *
    FROM per_customer_totals
    WHERE total_spent > 1000
)
SELECT * FROM big_spenders;


/**********************************************************************
 * 6. RECURSIVE CTE (hierarchy example)
 *********************************************************************/

-- For recursion we first create a simple product_category hierarchy
-- in the transactional database (if not already present).

-- Drop & recreate for idempotency (OK in a lab environment):
DROP TABLE IF EXISTS ProductCategory CASCADE;

CREATE TABLE ProductCategory (
    IDCategory   SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_id     INT REFERENCES ProductCategory(IDCategory)
);

-- Insert small hierarchy: Electronics → (Laptops, Phones, Tablets)
INSERT INTO ProductCategory (category_name, parent_id) VALUES
('Root',        NULL),      -- level 0
('Electronics', 1),         -- level 1
('Laptops',     2),         -- level 2
('Phones',      2),         -- level 2
('Tablets',     2);         -- level 2

-- Task REC-1:
--   Using a recursive CTE, list the hierarchy starting from 'Electronics'
--   and show each category with its level and full “path”.
-- Solution:
WITH RECURSIVE cat_tree AS (
    -- Anchor: start at Electronics
    SELECT
        c.IDCategory,
        c.category_name,
        c.parent_id,
        0 AS level,
        c.category_name::text AS path
    FROM ProductCategory c
    WHERE c.category_name = 'Electronics'

    UNION ALL

    -- Recursive member: pick children of current nodes
    SELECT
        child.IDCategory,
        child.category_name,
        child.parent_id,
        parent.level + 1 AS level,
        parent.path || ' » ' || child.category_name AS path
    FROM ProductCategory child
    JOIN cat_tree parent ON child.parent_id = parent.IDCategory
)
SELECT *
FROM cat_tree
ORDER BY level, category_name;


