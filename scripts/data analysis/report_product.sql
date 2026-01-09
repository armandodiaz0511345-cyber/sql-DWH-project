/*
======================================================
Product Report
======================================================
Purpose:
	- this report will consolidate key product details and metrics

Highlights:
	1: Gathers essential product info (i.e: names, category, subcategroy, and cost
	2: Segments products based on revenue (High-Performers, Mid-Range, or Low-Performers)
	3: Aggregates customer metrics
		- total orders, sales, quantity sold, total customers (unique), lifespan (months)
	4: Calculates valuable KPIs
		-recency (months since last SALE)
		-average order revenue (AOR) = total_sales/ COUNT(distinct order_number)     
														^^^^^number_of_orders
		-average monthly spend on product (during lifetime of prod (all products still ongoing)) = total_sales/ DATEDIFF(MONTH,MAX(order_date, GETDATE())
																			^^^^ days_since_last_order
======================================================
*/
CREATE VIEW gold.report_products AS
WITH product_information AS 
(
--BASE Query
SELECT
p.product_name,
p.category,
p.subcategory,
p.cost,
p.product_start_date,
MAX(order_date) latests_order,
DATEDIFF(MONTH,MAX(order_date), GETDATE()) months_since_last_order,
COUNT(DISTINCT f.order_number) number_of_orders,
SUM(f.quantity) total_bought,
SUM(f.sales_total) total_sales,
COUNT(DISTINCT f.customer_key) number_of_purchasing_customers
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
GROUP BY 
	p.product_name,
	p.category,
	p.subcategory,
	p.cost,
	p.product_start_date
)

--Main, Final details Query
SELECT
product_name,
category,
subcategory,
cost,
product_start_date,
latests_order,
months_since_last_order, --recency
number_of_orders,
total_bought,
total_sales,
CASE WHEN total_sales >=1000000 THEN 'High-Performer'
	 WHEN total_sales BETWEEN 100000 and 1000000 THEN 'Average-performer'
	 WHEN total_sales <=100000 THEN 'Low-Performer'
END as product_performance,
number_of_purchasing_customers,
ROUND(CAST(total_sales as float)/NULLIF(number_of_orders,0),2) avg_revenue_per_order, -- make sure to include the NULLIFs so script doesnt break
total_sales/NULLIF((DATEDIFF(MONTH,product_start_date, GETDATE())),0) avg_monthly_revenue -- make sure to include the NULLIFs so script doesnt break
FROM product_information


GO

--SELECT * FROM gold.dim_products
--SELECT * FROM gold.fact_sales
