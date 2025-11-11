-- See where you are
SELECT current_database();

-- Peek at tables 
SELECT * FROM Customer LIMIT 5;
SELECT * FROM Product  LIMIT 5;
SELECT * FROM CustomerOrder LIMIT 5;
SELECT * FROM OrderItem LIMIT 5;
SELECT * FROM Payment LIMIT 5;


-- adding some rows
INSERT INTO Customer (name, email, address) VALUES
  ('Ann Archer', 'ann.a@example.com', '1 King''s Rd');
  
INSERT INTO Customer (name, email, address) VALUES
  ('Chris Kim',  'ckim@example.com',  NULL);

INSERT INTO Product (product_name, category, price) VALUES
  ('Desk',  'Furniture', 199.99),
  ('Chair', 'Furniture',  99.99)
;

-- A couple of extra orders/items/payments so aggregates look nicer
INSERT INTO CustomerOrder (CustomerID, order_date) VALUES
  ((SELECT IDCustomer FROM Customer WHERE email='ann.a@example.com'), '2023-11-06'),
  ((SELECT IDCustomer FROM Customer WHERE email='ckim@example.com'),  '2023-11-07');

INSERT INTO OrderItem (OrderID, ProductID, quantity, unit_price) VALUES
  ((SELECT IDOrder FROM CustomerOrder WHERE order_date='2023-11-06' LIMIT 1),
   (SELECT IDProduct FROM Product WHERE product_name='Chair'), 4, 95.00),
  ((SELECT IDOrder FROM CustomerOrder WHERE order_date='2023-11-07' LIMIT 1),
   (SELECT IDProduct FROM Product WHERE product_name='Desk'), 1, 199.99);

INSERT INTO Payment (OrderID, payment_date, payment_method, amount) VALUES
  ((SELECT IDOrder FROM CustomerOrder WHERE order_date='2023-11-06' LIMIT 1), '2023-11-06','PayPal',380.00),
  ((SELECT IDOrder FROM CustomerOrder WHERE order_date='2023-11-07' LIMIT 1), '2023-11-07','Credit Card',199.99);


-- pick columns + alias (AS "…")
SELECT name AS "Customer Name", email AS "Email"
FROM Customer;

-- whole table
SELECT * FROM Product;

-- DISTINCT values (category list)
SELECT DISTINCT category
FROM Product
ORDER BY category;  -- ORDER BY (default ASC)

-- NULL and LIKE
-- Customers with missing address OR address starting with '1'
SELECT IDCustomer, name, address
FROM Customer
WHERE address IS NULL OR address LIKE '1%';  -- NULL ops + LIKE

-- IN (list) + BETWEEN + ORDER BY DESC
SELECT IDProduct, product_name, price
FROM Product
WHERE category IN ('Accessories','Furniture')     -- IN (list)
  AND price BETWEEN 20 AND 99.99                    -- BETWEEN (inclusive)
ORDER BY price DESC;

-- NOT + OR demo
SELECT *
FROM Customer
WHERE NOT email LIKE '%@example.com' OR name LIKE 'A%';


-- Products NOT in a list
SELECT product_name, category
FROM Product
WHERE category NOT IN ('Accessories','Furniture')
ORDER BY product_name;


-- Per-order rollup (no joins): OrderItem alone
SELECT
  OrderID,
  COUNT(*)                       AS line_count,          -- COUNT
  SUM(quantity)                  AS total_qty,           -- SUM
  SUM(quantity * unit_price) 	 AS total,
  ROUND(AVG(unit_price), 2)      AS avg_unit_price,      -- AVG nested in ROUND
  MAX(unit_price)                AS max_unit_price,      -- MAX
  MIN(unit_price)                AS min_unit_price       -- MIN
FROM OrderItem
GROUP BY OrderID                               -- GROUP BY
HAVING SUM(quantity * unit_price) >= 400       -- HAVING (group condition)
ORDER BY SUM(quantity * unit_price) DESC;      -- ORDER BY aggregate


-- “Top products by total quantity” using only the Product table & alias
-- (We stay single-table by grouping OrderItem and ordering its own aggregates.)
SELECT
  oi.ProductID                           AS pid,
  SUM(oi.quantity)                       AS total_qty
FROM OrderItem AS oi                  -- table alias
GROUP BY ProductID
ORDER BY total_qty DESC;



-- Latest payment per order 
SELECT
  p.OrderID,
  MAX(p.payment_date) AS latest_payment_date
FROM Payment p
GROUP BY p.OrderID
ORDER BY p.OrderID;

/*

-- PRACTICE TASKS


Checking customer data quality

You’ve been asked to find customers whose information looks suspicious.
Specifically, return anyone missing an email or whose address appears to be a short street name ending with “St”.
Show their name, and address, email by name alphabetically.

--------------------------------------------------------------------------------------------------------------------
Product team pricing review

The product manager wants to review only Furniture and Accessories items priced in the affordable range ($20 – $200),
but exclude anything that’s literally called “Charger” (it’s handled by another team).
List product ID, name, category, and price, sorted first by product name then by price (highest first within each name).

--------------------------------------------------------------------------------------------------------------------
For inventory planning, operations needs to know how much of each product is being sold.
Summarize the OrderItem table by product:

	count how many order lines each product appears in,
	
	total quantity sold,
	
	total sales revenue,

	and the average unit price rounded to two decimals.
	
Show only products with an average unit price of at least 50 and a total quantity between 2 and 10.
Rank them by revenue from highest to lowest.

--------------------------------------------------------------------------------------------------------------------
Finance checks payment patterns

The finance department wants to know which payment methods are bringing in the most money.
Look only at payments made in October and November 2023, group by payment method,
and report the number of payments and the total amount processed.
Keep only those methods that had at least two transactions or brought in $500 or more,
ordered by total amount descending.

--------------------------------------------------------------------------------------------------------------------
Marketing filters potential ambassadors

Marketing wants to send an invite to customers whose third letter in their name is “n”
(pattern matching exercise) and whose email address is not from our default “@example.com” domain.
List their ID, name, and email, alphabetically by name.

--------------------------------------------------------------------------------------------------------------------
Seasonality check on orders

Management is checking whether there were any orders placed outside the main October campaign.
Show all orders with order dates before October 5 or after October 31 2023,
including order ID, customer ID, and date, sorted chronologically.
*/

