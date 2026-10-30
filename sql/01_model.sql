-- 01_model.sql | Build one analysis-ready line-item table
DROP TABLE IF EXISTS sales;
CREATE TABLE sales AS
SELECT o.order_id, o.customer_id, o.order_date,
       strftime('%Y-%m', o.order_date) AS month,
       o.discount_pct, o.payment_method,
       c.region, c.channel, c.signup_date,
       p.category, p.product_id,
       i.quantity,
       ROUND(i.quantity * p.unit_price * (1 - o.discount_pct), 2) AS revenue,
       ROUND(i.quantity * p.unit_cost, 2)                         AS cost,
       ROUND(i.quantity * p.unit_price * (1 - o.discount_pct) - i.quantity * p.unit_cost, 2) AS profit
FROM order_items i
JOIN orders o    ON o.order_id = i.order_id
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p  ON p.product_id = i.product_id;
