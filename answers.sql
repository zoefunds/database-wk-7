-- answers.sql
-- Assignment: Database Design and Normalization
-- Prepared for: Week 7
-- Notes:
-- - Assumes MySQL 8.0+ (JSON_TABLE is used for a concise split of comma-separated values).
-- - If JSON_TABLE isn't available, a recursive-CTE approach is shown in comments as an alternative.

/* QUESTION 1 — Achieving 1NF
   Given table ProductDetail(OrderID, CustomerName, Products)
   where Products contains comma-separated product names,
   create a 1NF table Product1NF where each row is a single product.
*/

-- Create the normalized table (1NF)
CREATE TABLE IF NOT EXISTS Product1NF (
  OrderID INT NOT NULL,
  CustomerName VARCHAR(255),
  Product VARCHAR(255)
);

-- Populate Product1NF by splitting the comma-separated Products column.
-- Method using JSON_TABLE (MySQL 8+). This handles commas plus optional spaces.
INSERT INTO Product1NF (OrderID, CustomerName, Product)
SELECT
  pd.OrderID,
  pd.CustomerName,
  TRIM(jt.product) AS Product
FROM ProductDetail pd
JOIN JSON_TABLE(
  CONCAT('["', REPLACE(pd.Products, ', ', '","'), '"]'),
  '$[*]' COLUMNS (product VARCHAR(255) PATH '$')
) AS jt;

-- Alternative approach (if JSON_TABLE is not available) using a recursive CTE:
-- (Uncomment and use instead of the JSON_TABLE block above)
/*
WITH RECURSIVE nums AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM nums WHERE n < 20  -- adjust max items per row if needed
)
INSERT INTO Product1NF (OrderID, CustomerName, Product)
SELECT
  pd.OrderID,
  pd.CustomerName,
  TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(pd.Products, ',', nums.n), ',', -1)) AS Product
FROM ProductDetail pd
JOIN nums ON nums.n <= 1 + LENGTH(pd.Products) - LENGTH(REPLACE(pd.Products, ',', ''))
WHERE TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(pd.Products, ',', nums.n), ',', -1)) <> '';
*/

-- After verifying Product1NF, you may DROP the original Products column or the original table if desired:
-- ALTER TABLE ProductDetail DROP COLUMN Products;   -- optional


/* QUESTION 2 — Achieving 2NF
   Given table OrderDetails(OrderID, CustomerName, Product, Quantity)
   where CustomerName depends only on OrderID (partial dependency),
   split into Orders and OrderItems so non-key columns fully depend on the full PK.
*/

-- Create Orders table (stores attributes that depend only on OrderID)
CREATE TABLE IF NOT EXISTS Orders (
  OrderID INT PRIMARY KEY,
  CustomerName VARCHAR(255)
);

-- Create OrderItems table (composite PK: OrderID + Product)
CREATE TABLE IF NOT EXISTS OrderItems (
  OrderID INT NOT NULL,
  Product VARCHAR(255) NOT NULL,
  Quantity INT,
  PRIMARY KEY (OrderID, Product),
  FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Populate Orders with distinct OrderID -> CustomerName mappings
INSERT INTO Orders (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName
FROM OrderDetails;

-- Populate OrderItems with the product-level rows
INSERT INTO OrderItems (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity
FROM OrderDetails;

-- Optional: verify and then remove CustomerName from the original OrderDetails table
-- (so it no longer causes partial dependency)
-- ALTER TABLE OrderDetails DROP COLUMN CustomerName;  -- optional, after verification

-- End of answers.sql