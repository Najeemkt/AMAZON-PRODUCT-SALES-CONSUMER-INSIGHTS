CREATE TABLE sales_data (
    order_id VARCHAR(20) PRIMARY KEY,
    order_date DATE,
    customer_id VARCHAR(20),
    product_category VARCHAR(50),
    product_name VARCHAR(100),
    quantity INT,
    unit_price NUMERIC(10,2),
    total_sales NUMERIC(12,2),
    payment_method VARCHAR(50),
    delivery_status VARCHAR(50),
    review_rating INT
);
select* from sales_data



CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY
);
INSERT INTO customers (customer_id)
SELECT distinct customer_id
FROM sales_data;
select* from customers;


CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE
);
INSERT INTO categories (category_name)
SELECT DISTINCT product_category
FROM sales_data;

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category_id INT REFERENCES categories(category_id)
);
INSERT INTO products (product_name, category_id)
SELECT DISTINCT 
    s.product_name,
    c.category_id
FROM sales_data s
JOIN categories c
    ON s.product_category = c.category_name;


CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    order_date DATE,
    customer_id VARCHAR(20) REFERENCES customers(customer_id),
    payment_method VARCHAR(50),
    delivery_status VARCHAR(50),
    review_rating INT
);
INSERT INTO orders (order_id, order_date, customer_id, payment_method, delivery_status, review_rating)
SELECT DISTINCT
    order_id,
    order_date,
    customer_id,
    payment_method,
    delivery_status,
    review_rating
FROM sales_data;

CREATE TABLE order_items (
    order_id VARCHAR(20) REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2),
    total_sales NUMERIC(12,2),
    PRIMARY KEY (order_id, product_id)
);	
INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_sales)
SELECT 
    s.order_id,
    p.product_id,
    s.quantity,
    s.unit_price,
    s.total_sales
FROM sales_data s
JOIN products p
    ON s.product_name = p.product_name;




-- Total Revenue by Category
SELECT c.category_name,
SUM(oi.total_sales) as total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_revenue DESC;

-- Top 5 Customers by Total Spending (CTE)
WITH customer_spending AS (
    SELECT o.customer_id,
           SUM(oi.total_sales) AS total_spent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT *
FROM customer_spending
ORDER BY total_spent DESC
LIMIT 5;

--Monthly Sales Trend (Date Analysis)

SELECT DATE_TRUNC('month', o.order_date) as month,
       SUM(oi.total_sales) as monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- Rank Products by Revenue (Window Function)

SELECT p.product_name,
       SUM(oi.total_sales) AS revenue,
       RANK() OVER (ORDER BY SUM(oi.total_sales) DESC) AS rank_position
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name;

-- Highest Order Value (Subquery)

SELECT order_id, order_total
FROM (
    SELECT order_id,
           SUM(total_sales) AS order_total
    FROM order_items
    GROUP BY order_id
) sub
ORDER BY order_total DESC
LIMIT 1;

--  Average Order Value

SELECT AVG(order_total) AS avg_order_value
FROM (
    SELECT order_id,
           SUM(total_sales) AS order_total
    FROM order_items
    GROUP BY order_id
) t;

-- Revenue by Payment Method

SELECT o.payment_method,
       SUM(oi.total_sales) as total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.payment_method
ORDER BY total_revenue DESC;

-- Delivery Status Distribution

SELECT 
    review_rating,

    COUNT(CASE WHEN delivery_status = 'Delivered' THEN 1 END) AS delivered,
    COUNT(CASE WHEN delivery_status = 'Pending' THEN 1 END) AS pending,
    COUNT(CASE WHEN delivery_status = 'Returned' THEN 1 END) AS returned

FROM orders
GROUP BY review_rating
ORDER BY review_rating;

-- Running Total of Revenue (Window Function)

SELECT 
    o.order_date,
    SUM(oi.total_sales) AS daily_revenue,
    SUM(SUM(oi.total_sales)) OVER (
        ORDER BY o.order_date
    ) AS running_total_revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY o.order_date
ORDER BY o.order_date
LIMIT 10;

-- Most Frequently Purchased Product

SELECT p.product_name,
       SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC
LIMIT 5;

 -- Customer Lifetime Value with ranking

SELECT o.customer_id,
       SUM(oi.total_sales) AS lifetime_value,
       DENSE_RANK() OVER (ORDER BY SUM(oi.total_sales) DESC) AS customer_rank
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.customer_id
limit 10;

-- Average Review Rating by Category

SELECT 
    c.category_name,
    ROUND(AVG(o.review_rating), 2) AS avg_rating
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY avg_rating DESC;


