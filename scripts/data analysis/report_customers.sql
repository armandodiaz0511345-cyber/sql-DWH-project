/*
======================================================
Customer Report
======================================================
Purpose:
	- this report will consolidate key customer metrics and behaviors

Highlights:
	1: Gathers essential customer info (i.e: names, age, country, transaction details
	2: Segments customers (VIP, Regular, New) based on spending.
	3: Aggregates customer metrics
		- total orders, sales, quantity purchased, lifespan
	4: Calculates valuable KPIs
		-recency (months since last order)
		-average order value
		-average monthly spend
======================================================
*/


--===================================
-- MY METHOD
--===================================
WITH customer_segmentation AS
(
SELECT
s.customer_key,
c.first_name,
c.last_name,
s.total_orders,
s.total_quantity,
s.total_spending,
s.customer_age,
s.latest_purchase,
s.average_spending_per_order,
s.total_spending/DATEDIFF(MONTH,earliest_purchase,GETDATE()) as customer_monthly_spending,
CASE WHEN customer_age > 12 AND total_spending > 5000 THEN 'VIP'
	 WHEN customer_age > 12 AND total_spending <= 5000 THEN 'Regular'
	 Else 'New'
END customer_group
FROM (
SELECT
customer_key,
SUM(quantity) as total_quantity,
Count(DISTINCT order_number) total_orders,
SUM(sales_total) total_spending,
AVG(sales_total) average_spending_per_order,
MIN(order_date) earliest_purchase,
MAX(order_date) latest_purchase,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) as customer_age -- we are allowed to use datediff in the aggregate because it is seen as a measure, (measuring distance between min and mix). also, it is unique to just this customer, which works perfectly (as intended).
From gold.fact_sales
Group by customer_key
)s
LEFT JOIN gold.dim_customers c
on s.customer_key = c.customer_key
)






SELECT
CONCAT(c.first_name,' ',c.last_name) AS customer_name,
DATEDIFF(YEAR, c.birthdate,GETDATE()) AS customer_age,
c.country,
s.customer_group,
s.customer_age,
s.total_spending,
s.average_spending_per_order,
s.total_orders,
s.total_quantity,
DATEDIFF(MONTH,s.latest_purchase,GETDATE()) months_since_last_purchase,
customer_monthly_spending
FROM gold.dim_customers c
LEFT JOIN customer_segmentation s
ON c.customer_key = s.customer_key

--=======================================================


--==================================
--Baraa's Method
--==================================


-- THIS allows people to look at the data and do their own proper analysis
-- take in any info from the customers and analyze them


CREATE VIEW gold.report_customers AS
WITH base_query AS 
(
--1 BASE QUERY: Retrieves core columns from tables
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_total,
f.quantity,
c.customer_key,
c.customer_number,
c.birthdate,
CONCAT(c.first_name,' ',c.last_name) as customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL
)
, customer_aggregation AS
(
-- Customer Aggregation: Summarizes key metrics at the customer level
SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) as total_orders,
SUM(sales_total) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) last_order_date,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) as customer_lifespan -- we are allowed to use datediff in the aggregate because it is seen as a measure, (measuring distance between min and mix). also, it is unique to just this customer, which works perfectly (as intended).
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)

SELECT 
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age<20 THEN 'Under 20'
	 WHEN age BETWEEN 20 and 29 THEN '20-29'
	 WHEN age BETWEEN 30 and 39 THEN '30-39'
	 WHEN age BETWEEN 40 and 49 THEN '40-49'
ELSE '50 and above'
END age_group,
CASE WHEN customer_lifespan > 12 AND customer_lifespan > 5000 THEN 'VIP'
	 WHEN customer_lifespan > 12 AND customer_lifespan <= 5000 THEN 'Regular'
	 Else 'New'
END customer_group,
DATEDIFF(month,last_order_date,GETDATE()) recency,

--compute average order value (AVO)
CASE WHEN total_sales = 0 THEN 0
ELSE total_sales/ total_orders
END  avg_order_value,-- note that my method for this calculated the AVG as an aggregate function in the intermediate step

--compute average montly spend
CASE WHEN customer_lifespan = 0 THEN total_sales
	 ELSE total_sales/customer_lifespan
END AS avg_monthly_spend, --different calculation from what i had though it was. (this is total sales/lifetime months)
total_orders,
total_sales,
total_quantity,
total_products,
customer_lifespan -- we are allowed to use datediff in the aggregate because it is seen as a measure, (measuring distance between min and mix). also, it is unique to just this customer, which works perfectly (as intended).

FROM customer_aggregation
