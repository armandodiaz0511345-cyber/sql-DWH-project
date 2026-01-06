/*
LOAD Stored Procedure Script:
The purpose of this script is it transform (clean) the data in the bronze (raw data) layer
and load it into the silver layer. this clean data will allow us to work in the gold layer and gain
insights, as well as analyze the data.
*/
--==SILVER DATA LOADS (CLEANED)==--

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
DECLARE @start_time_indv DATETIME2, @end_time_indv DATETIME2, @start_time_ttl DATETIME2, @end_time_ttl DATETIME2
	BEGIN TRY
		SET @start_time_ttl = GETDATE()

		PRINT '============================================'
		PRINT 'Loading Silver Layer'
		PRINT '============================================'
--==CRM TABLES==--
	--==cust_info==--
		PRINT '======TRUNCATING silver.crm_cust_info======'
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '======INSERTING silver.crm_cust_info======'
		SET @start_time_indv = GETDATE()
		INSERT INTO silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date)

		SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) cst_firstname,
		TRIM(cst_lastname) cst_lastname,
		CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			 ELSE 'n/a'
		END cst_marital_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			 WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			 ELSE 'n/a'
		END cst_gndr,
		cst_create_date
		FROM
		(
		SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) FlagLatest
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL -- give results where the customer ID is not null

		)t
		WHERE FlagLatest = 1

		SET @end_time_indv = GETDATE()
		PRINT 'TIME TO LOAD crm_cust_info: ' + CAST(DATEDIFF(second, @start_time_indv, @end_time_indv) as VARCHAR)
		
	--==prod_info==--
		PRINT '======TRUNCATING silver.crm_prd_info======'
		TRUNCATE TABLE silver.crm_prd_info
		PRINT '======INSERTING silver.crm_prd_info======'
		SET @start_time_indv = GETDATE()
		INSERT INTO silver.crm_prd_info (prd_id,cat_subcat_id,prd_key, prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
		SELECT 
		prd_id, -- Step 1 (all fine)
		REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_subcat_id, -- extracted category and subcategory IDs
		SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key, -- getting the varied length substring after the cat-subcat. -- extracting product key
		prd_nm, -- all good
		COALESCE(prd_cost,0) as prd_cost, --change nulls to 0 -- all good
		CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain' -- always try to use UPPER(TRIM())
			 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
			 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			 ELSE 'n/a'
		END AS prd_line, -- step 5 complete (data normalization)
		CAST(prd_start_dt as DATE) prd_start_dt, -- data type casting
		CAST((LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1) AS DATE)  as prd_end_dt -- calculated end date as one date before the next start date -- data enrichment.
		FROM bronze.crm_prd_info

		SET @end_time_indv = GETDATE()
		PRINT 'TIME TO LOAD crm_prd_info: ' + CAST(DATEDIFF(second, @start_time_indv, @end_time_indv) as VARCHAR)

	--==sales_details==--
		PRINT '======TRUNCATING silver.crm_sales_details======'
		TRUNCATE TABLE silver.crm_sales_details
		PRINT '======INSERTING silver.crm_sales_details======'
		SET @start_time_indv = GETDATE()
		INSERT INTO silver.crm_sales_details
		(sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
		SELECT
		sls_ord_num,--1
		sls_prd_key,--2
		sls_cust_id,--2
		CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt, --3a
		CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt, --3b
		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt, --3b

		CASE WHEN sls_sales IS NULL or sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) --(business rule basis)
			 THEN sls_quantity * ABS(sls_price)
		 ELSE sls_sales
		END sls_sales,--5 -- recalc based on original values of quantity and price
		sls_quantity,
		CASE WHEN sls_price IS NULL or sls_price = 0 --(business rule basis)
			 THEN sls_sales/ NULLIF(sls_quantity,0) -- null if just in case we ever get a null quantity
			 WHEN sls_price < 0 THEN ABS(sls_price)
		 ELSE sls_price
		END sls_price--5 -- recalc based on original values of quantity and sales
		from bronze.crm_sales_details

		SET @end_time_indv = GETDATE()
		PRINT 'TIME TO LOAD crm_sales_details: ' + CAST(DATEDIFF(second, @start_time_indv, @end_time_indv) as VARCHAR)

--==ERP TABLES==--

	--==cust_az12==--
		PRINT '======TRUNCATING silver.erp_cust_az12======'
		TRUNCATE TABLE silver.erp_cust_az12
		PRINT '======INSERTING silver.erp_cust_az12======'
		SET @start_time_indv = GETDATE()
		INSERT INTO silver.erp_cust_az12 
		(
		cid,
		bdate,
		gen)-- the columns
		SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) -- getting rid of 'NAS' since it has no use
			 ELSE cid
		END as CustomerID, --removed invalid/unneeded values
		CASE WHEN bdate >GETDATE() THEN NULL
			 ELSE bdate
		END Birthdate, -- handled invalid birthdates to NULL
		CASE WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male' --use IN to simplify ( if upper (trim( gen)) is either F or FEMALE, then Female.
			 WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female' -- use IN to simplify, since we can use else for NULLS and BLANKS.
		 ELSE 'n/a'
		END Gender -- normalized genders 'F'>'Female' etc.
		from bronze.erp_cust_az12

		SET @end_time_indv = GETDATE()
		PRINT 'TIME TO LOAD erp_cust_az12: ' + CAST(DATEDIFF(second, @start_time_indv, @end_time_indv) as VARCHAR)

	--==loc_a101==--
		PRINT '======TRUNCATING silver.erp_loc_a101======'
		TRUNCATE TABLE silver.erp_loc_a101
		PRINT '======INSERTING silver.erp_loc_a101======'
		SET @start_time_indv = GETDATE()
		INSERT INTO silver.erp_loc_a101 (cid, cntry)
		SELECT
		REPLACE(cid,'-','') as cid, -- handled invalid values (replaced)
		CASE WHEN UPPER(TRIM(cntry)) IN ('USA','US') THEN 'United States'
			 WHEN UPPER(TRIM(cntry)) IN ('DE') THEN 'Germany'
			 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
		END as cntry -- data normalization
		FROM bronze.erp_loc_a101

		SET @end_time_indv = GETDATE()
		PRINT 'TIME TO LOAD erp_loc_a101: ' + CAST(DATEDIFF(second, @start_time_indv, @end_time_indv) as VARCHAR)

	--==px_cat_g1v2==--
		PRINT '======TRUNCATING silver.erp_px_cat_g1v2======'
		TRUNCATE TABLE silver.erp_px_cat_g1v2
		PRINT '======INSERTING silver.erp_px_cat_g1v2======'
		SET @start_time_indv = GETDATE()
		INSERT INTO silver.erp_px_cat_g1v2 (id,cat,subcat,maintenance)
		SELECT 
		id, --1
		cat,--2,3
		subcat,--2,4
		maintenance--2,5
		FROM bronze.erp_px_cat_g1v2
		
		SET @end_time_indv = GETDATE()
		PRINT 'TIME TO LOAD erp_px_cat_g1v2: ' + CAST(DATEDIFF(second, @start_time_indv, @end_time_indv) as VARCHAR)

--==END OF LOAD==--
		SET @end_time_ttl = GETDATE()

		PRINT 'TOTAL TIME TO LOAD SILVER LAYER: ' + CAST(DATEDIFF(second, @start_time_ttl, @end_time_ttl) as VARCHAR)
	END TRY

	BEGIN CATCH
	PRINT 'ERROR FOUND DURING LOADING SILVER LAYER'
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER: ' + Cast(ERROR_NUMBER() as NVARCHAR);
	END CATCH
END


--exec silver.load_silver
