
/*
====================================================
QUALITY CHECKS:
The following checks:
-checks for duplicates in customer id when joining silver.crm_cust_info, silver.erp_cust_az12, and silver.erp_loc_a101
-checks and integrates gender data for the customer gold view (combining silver.crm_cust_info & silver.erp_cust_az12 GENDER, while keeping the crm info as the main/primary source, and only substituting when necessary (n/a's))
-checks for duplicates in prd_key when joining silver.crm_prd_info and silver.erp_px_cat_g1v2 based on the category id.
-lastly connects all the facts and dimension sheets and checks if there are any NULLS in the customer key (surrogate) or the product key (surrogate) in the sales view.
-- no nulls are seen, meaning that in the sales fact sheet, every row is accounted for by both some sort of customer key and some sort of product key.

====================================================
*/

--==================================================
--gold.dim_customers CHECK
--==================================================
--1-- CHECK FOR duplicates from joins

SELECT cst_id, COUNT(*) FROM (
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
)t
GROUP BY cst_id
HAVING COUNT(*) > 1

--2--Gender data integration: 

SELECT DISTINCT -- check fistinct
ci.cst_gndr,
ca.gen, -- note that this shows the gender of some people that previously showed an 'n/a' for gender

CASE WHEN ci.cst_gndr !='n/a' THEN ci.cst_gndr
	 ELSE Coalesce(ca.gen, 'n/a')
END Gender

FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
on ci.cst_key = cl.cid
Order by 1,2

--==================================================
--gold.dim_products CHECK
--==================================================
--CHECK for duplicates in prd_key (as we will be using it to connect to sales data so we cant have dupes)
SELECT prd_key, COUNT(*) counts
FROM (
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
)t
Group by prd_key
HAVING  COUNT(*) >1

  GO

SELECT * from silver.erp_px_cat_g1v2 -- used for checking correct joins
select * from silver.crm_prd_info -- used for checking correct joins
SELECT * from gold.dim_products -- final visual check

--==================================================
--gold.facts_sales CHECK
--==================================================
---FINAL CHECK-- connect all fact sheets and dimensions through surrogate keys to 
SELECT * from gold.fact_sales fs
LEFT JOIN gold.dim_customers cs
ON fs.customer_key = cs.customer_key
LEFT JOIN gold.dim_products pr
ON fs.product_key = pr.product_key
WHERE cs.customer_key IS NULL or pr.product_key IS NULL
-- no results, so everything is matching perfectly.
-- this runs, meaning that all surrogate keys are connecting correctly
