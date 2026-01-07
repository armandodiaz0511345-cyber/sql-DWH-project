/*
================================================
DDL Scripts: Create Gold Views
================================================
PURPOSE: The purpose of this script is to produce the gold layer of the data warehouse.

gold layer includes: 
-final processed data that is fully integrated
-the final dimensions and fact VIEWS of the data warehouse (entire star Schema)

each view combines and transforms data from the silver layer to get a more complete picture
of the data (customers, products and sales)

USAGE:
use this to directly query for analytics and reporting.

*/
--NOTE: ALL CHECKS DONE TO DDL CAN BE FOUND IN THIS SAME FOLDER IN THE: ddl_gold_quality_checks.sql

--==========================================================
-- CREATE DIMENSION: gold.dim_customers
--==========================================================

------==========CUSTOMER DIMENSION==========-----
--* whenever you have a dimension, you can create a SURROGATE KEY for it

CREATE OR ALTER VIEW gold.dim_customers AS
SELECT 
ROW_NUMBER() OVER (Order by cst_id) as customer_key, -- surrogate key!
ci.cst_id AS customer_id, 
ci.cst_key AS customer_number,
ci.cst_firstname AS first_name,
ci.cst_lastname AS last_name,
cl.cntry as country,
ci.cst_marital_status AS marital_status,
ca.bdate as birthdate,
CASE WHEN ci.cst_gndr !='n/a' THEN ci.cst_gndr
	 ELSE Coalesce(ca.gen, 'n/a')
END as gender, --this here integrates both sources of gender data, while prioritizing crm data (only looking elsewhere when nothing is found in the crm)
ci.cst_create_date as creation_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
on ci.cst_key = cl.cid




--==========================================================
-- CREATE DIMENSION: gold.dim_products
--==========================================================

-----========PRODUCT DIMENSION============-----
--* whenever you have a dimension, you can create a SURROGATE KEY for it
--* Note that a column NAME is necessary for views, just as much as they are for tables.
CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pn.cat_subcat_id AS category_id,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance AS maintenance,
pn.prd_line AS product_line,
pn.prd_cost AS cost,
pn.prd_start_dt AS product_start_date
FROM silver.crm_prd_info as pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_subcat_id = pc.id
WHERE pn.prd_end_dt IS NULL -- this filters out old, historical data, end date is also now not included in data since it will always be null

--==========================================================
-- CREATE FACT: gold.fact_sales
--==========================================================

------=========SALES FACT SHEET===========---------
--* connect dimensions through IDs and replace those with surrogate keys from dimension pages.

CREATE OR ALTER VIEW gold.fact_sales AS
SELECT
sd.sls_ord_num AS order_number, --key
pr.product_key, -- imported surrogate product key
cs.customer_key, -- imported surrogate customer key
--sd.sls_prd_key, --original product key, which we no longer need (since we will use the surrogate keys in order to connect everything easily)
--sd.sls_cust_id, -- original customer id, which we no longer need for this table (we now will use the surrogate key to connect everything easily)
sd.sls_order_dt AS order_date, --date
sd.sls_ship_dt AS shipping_date, --date
sd.sls_due_dt AS due_date, --date
sd.sls_sales AS sales_total, --value
sd.sls_quantity AS quantity, --value
sd.sls_price AS price --value
FROM silver.crm_sales_details as sd
LEFT JOIN gold.dim_products pr 
ON sd.sls_prd_key = pr.product_number -- note that product_number was previously product_key
LEFT JOIN gold.dim_customers cs
ON sd.sls_cust_id = cs.customer_id


--select * from gold.dim_products
--select * from gold.dim_customers
--select * from gold.fact_sales
--the number of diff keys, dates, and values is what tells that this
-- is a FACT sheet, NOT a dimension.

