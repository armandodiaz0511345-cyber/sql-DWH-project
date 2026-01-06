/* NOTE: this is a compiling of all CHECKS AND TESTS done to check validity of data
for the silver layer. in order from CRM to ERP.*/

--======================================--
--crm_cust_info
--======================================--
SELECT
*,
FlagLatest
FROM
(
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) FlagLatest
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL -- give results where the customer ID is not null

)t
WHERE FlagLatest !=1
--======================================--
--crm_prd_info
--======================================--

(SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2)--step 2 (cat_subcat)

go

(SELECT sls_prd_key FROM bronze.crm_sales_details) -- step 2 (prd key)

--  1-Check PKs for Nulls or Dupes
SELECT
prd_id,
COUNT(*) IDTimesShown
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL
Order by COUNT(prd_id) desc

--Step 2 -- use substring function to seperate prd_key into 2 values. First 5 values is category & subcategory. following values are the key
-- must also turn dashes into underscores, and get the prd_key (character 7 - end) for end we use LEN(prd_key) to get dynamic length.
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_subcat_id,
REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as prd_key, -- replacing - with _, and getting the varied length substring after the cat-subcat.
--WHERE SUBSTRING(prd_key,7,LEN(prd_key)) NOT IN (SELECT sls_prd_key FROM bronze.crm_sales_details) use to check what products HAVE and HAVENT been ordered.
--STEP 3
--step 3 -trim name check
SELECT 
prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm) -- all good
--step 4
--check costs
SELECT prd_cost
FROM silver.crm_prd_info -- replace silver with bronze accordingly for checks
WHERE prd_cost < 0 or prd_cost IS NULL -- check for null costs and for 'negative costs']
-- step 5
--checking for all distinct values for prd_line
SELECT
prd_line,
COUNT(*)
FROM silver.crm_prd_info
group by prd_line
  
go
  
SELECT DISTINCT prd_line
from silver.crm_prd_info
-- replace these ambiguous product line values (single letters) with full words/descriptions for better readabilty.
-- how? CASE WHEN UPPER(TRIM(prd_line)) = 'M' then 'Mountain 
		--etc etc
--step 6- find invalid date orders (start must be earlier than end)
SELECT 
prd_key,
prd_id,
prd_nm,
prd_start_dt, 
prd_end_dt, 
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1  as prd_end_dt_test
From bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')


SELECT 
prd_key,
prd_id,
prd_nm,
prd_start_dt, 
prd_end_dt
From silver.crm_prd_info
WHERE prd_start_dt>prd_end_dt -- silver table is all good


 --^^^^ here we made out end dates based off of our start dates


--======================================--
--crm_sales_details
--======================================--



--=======NOTE FOR CHECKS:=======
--=======CHECKS WILL BE SAVED FOR SILVER TABLE (VALIDATING)=======--

--1--check ORD num for spaces
SELECT sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)
------

--2--Check prd_key and customer key based on other tables

SELECT sls_prd_key From silver.crm_sales_details WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)
SELECT sls_cust_id From silver.crm_sales_details WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)
--

--3-- Check for invalid dates (sls_order_dt, sls_ship_dt, sls_due_dt)
--3a--
--not changed to silver becasue different data type


SELECT 
NULLIF(sls_order_dt,0) as sls_order_d
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 OR  sls_order_dt > 20500101 OR sls_order_dt < 19900101 -- this is bad, we have '0' for dates, which wont work, we can NULLIF() to turn it into a NULL

----1st check^^ any zero dates? -------^^^2nd check:any dates not matching proper length?----- 3rd check^^date boundaries
--yyyymmdd
--this means length of date MUST be = 8

---3b--
--not changed to silver becasue different data type

SELECT 
NULLIF(sls_ship_dt,0) as sls_ship_d
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 OR  sls_ship_dt > 20500101 OR sls_ship_dt < 19900101 -- this is bad, we have '0' for dates, which wont work, we can NULLIF() to turn it into a NULL

--although the checks dont show any problems, we are going to apply the same rule just in case it happens in the future (small data set so it wont cause too much trouble).


--3c--
--not changed to silver becasue different data type

SELECT 
NULLIF(sls_due_dt,0) as sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 OR  sls_due_dt > 20500101 OR sls_due_dt < 19900101 -- this is bad, we have '0' for dates, which wont work, we can NULLIF() to turn it into a NULL
--although the checks dont show any problems, we are going to apply the same rule just in case it happens in the future (small data set so it wont cause too much trouble).


--4-- Checking for Invalid date orders
--not changed to silver becasue different data type
SELECT *
from bronze.crm_sales_details
Where LEN(sls_order_dt)= 8 and (sls_order_dt> sls_ship_dt or sls_order_dt >sls_due_dt or sls_ship_dt > sls_due_dt)

/*
SELECT *
from silver.crm_sales_details
Where (sls_order_dt> sls_ship_dt or sls_order_dt >sls_due_dt or sls_ship_dt > sls_due_dt)
*/ -- silver only, checks for integrity  order of dates

--5-- Check Invalid Sales, quantity, or price
-- sales= quantity * price
-- no negatives, zeros or nulls.

--RULES:
--if sales is wrong (negative, null, or 0), derive it from price*quantity
--if price is wrong (null or 0), calculate it from the sales/quantity
--if a price is negative, convert it to a positive
SELECT DISTINCT
sls_sales as old_sales,
sls_quantity,
sls_price as old_price,

CASE WHEN sls_sales IS NULL or sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	 THEN sls_quantity * ABS(sls_price)
 ELSE sls_sales
END sls_sales,

CASE WHEN sls_price IS NULL or sls_price = 0
	 THEN sls_sales/ NULLIF(sls_quantity,0) -- null if just in case we ever get a null quantity
	 WHEN sls_price < 0 THEN ABS(sls_price)
 ELSE sls_price
END sls_price

from silver.crm_sales_details
where sls_sales <= 0 
or sls_sales IS NULL or sls_quantity IS NULL or sls_price IS NULL
or sls_quantity*sls_price != sls_sales
ORDER BY sls_sales,sls_quantity, sls_price
-- shows lots of inconsistencies
--RULES:
--if sales is wrong (negative, null, or 0), derive it from price*quantity
--if price is wrong (null or 0), calculate it from the sales/quantity
--if a price is negative, convert it to a positive

select * from silver.crm_sales_details

--======================================--
--erp_cust_az12
--======================================--

--=========NOTE: NO CHANGES AT THE DDL,(data types, # of columns,etc..)===========-

--you can add this to check if any id's are not found in crm cust info
/*WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) -- getting rid of 'NAS' since it has no use
	 ELSE cid
END NOT IN (SELECT DISTINCT cst_key from silver.crm_cust_info)*/


--============NOTE: all checks will be saved for silver layer (checking data quality)

-- use to check connection to CRM cust info
SELECT cst_key from silver.crm_cust_info


--1 check integrity of cid
select cid 
from silver.erp_cust_az12
where cid != TRIM(cid) or cid is null or LEN(cid) NOT IN (10,13)

--2 check if we have customers lawed w/ 'NAS' as customers in the crm (w/o 'NAS')
SELECT * from silver.crm_cust_info
WHERE cst_key LIKE '%AW00011017'
-- my way (using LEN instead of LIKE)
/*

SELECT 
cid as oldcid,
CASE WHEN LEN(cid) = 13 THEN SUBSTRING(cid,4,LEN(cid)) -- getting rid of 'NAS' since it has no use
	 WHEN LEN(cid) = 10 then cid
 ELSE NULL
END as CustomerID,
bdate as Birthdate,
gen as gender
from bronze.erp_cust_az12
*/

--3 Check if dbates are out of range

SELECT DISTINCT
bdate
from silver.erp_cust_az12
WHERE bdate < '1924-01-01' or bdate > GETDATE() -- note that when checkign dates, you must use '' (quotes)
-- we arent going to get rid of the 100+ year olds, so silver will show old customers.
-- but nobody from the future.

--4 check genders (all possible genders)
SELECT DISTINCT
CASE WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male' --use IN to simplify ( if upper (trim( gen)) is either F or FEMALE, then Female.
	 WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female' -- use IN to simplify, since we can use else for NULLS and BLANKS.
 ELSE 'n/a'
END Gender
FROM silver.erp_cust_az12



--======================================--
--erp_loc_a101
--======================================--

--================NOTE: all checks will be left in silver, for data validating=============-

--remove dash from cid

SELECT 
REPLACE(cid,'-','') cid
from bronze.erp_loc_a101
WHERE REPLACE(cid,'-','') NOT IN (SELECT cst_key FROM silver.crm_cust_info)
--silver check
SELECT
cid
FRom silver.erp_loc_a101
WHERE cid != REPLACE(cid,'-','') -- all good
--^^ this where provides a check, interchange the REPLACE function cid vs the source provided cid to get difference.
--SELECT cst_key from silver.crm_cust_info -- check for cst key connection

--Check for Normalization in Country
SELECT 
cntry,
count(*)
FROM bronze.erp_loc_a101
group by cntry

-- Normalize Names & check
SELECT DISTINCT
CASE WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) IN ('DE','GERMANY') THEN 'Germany'
	 WHEN cntry IS NULL THEN 'n/a'
	 WHEN TRIM(cntry) = '' THEN 'n/a'
 ELSE cntry
END Country,
count(*) as TimesSeen
From bronze.erp_loc_a101
group by CASE WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) IN ('DE','GERMANY') THEN 'Germany'
	 WHEN cntry IS NULL THEN 'n/a'
	 WHEN TRIM(cntry) = '' THEN 'n/a'
 ELSE cntry
END

--silver normalization check
SELECT DISTINCT
cntry
FROM silver.erp_loc_a101 -- all good

--======================================--
--erp_px_cat_g1v2
--======================================--

--======== ALL CHECKS WILL BE FOR SILVER (data validation)===========
--SELECT * from silver.erp_px_cat_g1v2
--1--check that ID matches with crm_prod_info cat_subcat
SELECT
id
FROM silver.erp_px_cat_g1v2
WHERE id NOT IN(SELECT DISTINCT cat_subcat_id FROM silver.crm_prd_info)
-- one id not matched, but we can move past it? -- baraa moved past it.


--2 Check unwanted spaces in string values
SELECT * from silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- 3 check if we need to normalize string values (low cardinality)
SELECT DISTINCT
cat
FROM silver.erp_px_cat_g1v2

--4 check if we need to normalize string values (low cardinality)
SELECT DISTINCT
subcat
FROM silver.erp_px_cat_g1v2

--5 make sure maintenance yes/no is binary.
SELECT DISTINCT
maintenance 
FROM silver.erp_px_cat_g1v2

