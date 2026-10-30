-- 02_validate.sql | Checks before analysis
SELECT COUNT(*) AS orders, COUNT(DISTINCT order_id) AS distinct_orders FROM orders;                  -- equal
SELECT COUNT(*) AS orphan_items FROM order_items WHERE order_id NOT IN (SELECT order_id FROM orders); -- 0
SELECT COUNT(*) AS orders_before_signup FROM orders o JOIN customers c USING(customer_id) WHERE o.order_date < c.signup_date; -- 0
SELECT COUNT(*) AS negative_profit_lines FROM sales WHERE profit < 0;
SELECT ROUND(SUM(revenue),0) AS total_revenue, ROUND(SUM(profit),0) AS total_profit FROM sales;
