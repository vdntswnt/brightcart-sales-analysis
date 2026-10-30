-- 03_analysis.sql | Business questions

-- Q1 Monthly revenue with month-over-month growth (LAG)
WITH m AS (SELECT month, ROUND(SUM(revenue),0) AS revenue, ROUND(SUM(profit),0) AS profit FROM sales GROUP BY month)
SELECT month, revenue, profit,
       ROUND(100.0*(revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month),1) AS mom_pct
FROM m ORDER BY month;

-- Q2 Category revenue and profit margin
SELECT category, ROUND(SUM(revenue),0) AS revenue, ROUND(SUM(profit),0) AS profit,
       ROUND(100.0*SUM(profit)/SUM(revenue),1) AS margin_pct
FROM sales GROUP BY category ORDER BY revenue DESC;

-- Q3 Does discounting pay? Margin and order value by discount level
SELECT CAST(discount_pct*100 AS INT) AS discount_pct, COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue)/COUNT(DISTINCT order_id),0) AS avg_order_value,
       ROUND(100.0*SUM(profit)/SUM(revenue),1) AS margin_pct
FROM sales GROUP BY discount_pct ORDER BY discount_pct;

-- Q4 Region and acquisition channel
SELECT region, ROUND(SUM(revenue),0) AS revenue, ROUND(100.0*SUM(profit)/SUM(revenue),1) AS margin_pct FROM sales GROUP BY region ORDER BY revenue DESC;
SELECT channel, COUNT(DISTINCT customer_id) AS buyers, ROUND(SUM(revenue)/COUNT(DISTINCT customer_id),0) AS revenue_per_buyer FROM sales GROUP BY channel ORDER BY revenue_per_buyer DESC;

-- Q5 Customer concentration: share of revenue from the top 10% of customers (NTILE)
WITH cust AS (SELECT customer_id, SUM(revenue) AS rev FROM sales GROUP BY customer_id),
t AS (SELECT rev, NTILE(10) OVER (ORDER BY rev DESC) AS decile FROM cust)
SELECT decile, ROUND(100.0*SUM(rev)/(SELECT SUM(rev) FROM cust),1) AS share_pct FROM t GROUP BY decile ORDER BY decile;

-- Q6 RFM segmentation (recency, frequency, monetary scored 1-4 with NTILE)
DROP TABLE IF EXISTS rfm;
CREATE TABLE rfm AS
WITH base AS (
  SELECT customer_id, CAST(julianday('2025-12-31') - julianday(MAX(order_date)) AS INT) AS recency_days,
         COUNT(DISTINCT order_id) AS frequency, SUM(revenue) AS monetary
  FROM sales GROUP BY customer_id),
scored AS (
  SELECT *, 5 - NTILE(4) OVER (ORDER BY recency_days) AS r,
            NTILE(4) OVER (ORDER BY frequency, monetary) AS f,
            NTILE(4) OVER (ORDER BY monetary) AS m FROM base)
SELECT *, CASE WHEN r>=3 AND f>=3 THEN 'Champions'
               WHEN f>=3 AND r<=2 THEN 'At risk loyal'
               WHEN r>=3 AND f<=2 THEN 'Recent, low frequency'
               ELSE 'Lapsed / low value' END AS segment FROM scored;
SELECT segment, COUNT(*) AS customers, ROUND(SUM(monetary),0) AS revenue,
       ROUND(100.0*SUM(monetary)/(SELECT SUM(monetary) FROM rfm),1) AS revenue_share_pct
FROM rfm GROUP BY segment ORDER BY revenue DESC;

-- Q7 Cohort retention: share of each signup-month cohort that orders N months later
WITH first_m AS (SELECT customer_id, strftime('%Y-%m', signup_date) AS cohort FROM customers),
act AS (SELECT DISTINCT customer_id, month FROM sales),
j AS (SELECT f.cohort, a.customer_id,
        (CAST(substr(a.month,1,4) AS INT)*12 + CAST(substr(a.month,6,2) AS INT)) -
        (CAST(substr(f.cohort,1,4) AS INT)*12 + CAST(substr(f.cohort,6,2) AS INT)) AS age
      FROM first_m f JOIN act a USING(customer_id)),
size AS (SELECT cohort, COUNT(*) AS n FROM first_m GROUP BY cohort)
SELECT j.cohort, j.age, COUNT(DISTINCT j.customer_id) AS active, size.n,
       ROUND(100.0*COUNT(DISTINCT j.customer_id)/size.n,1) AS retention_pct
FROM j JOIN size USING(cohort) WHERE age BETWEEN 0 AND 6 GROUP BY j.cohort, j.age ORDER BY j.cohort, j.age;

-- Q8 Repeat-purchase rate
SELECT ROUND(100.0*SUM(CASE WHEN n>1 THEN 1 ELSE 0 END)/COUNT(*),1) AS repeat_customer_pct
FROM (SELECT customer_id, COUNT(DISTINCT order_id) n FROM sales GROUP BY customer_id);
