**Note- this page was created by AI for time-saving sake, but was double checked by my human eyes

Data Catalog for Gold Layer


## 1. gold.dim_customers
**Purpose:** Store customer data, along with enriched demographic and geographic data.

| Column Name | Data Type | Description | Example |
| :--- | :--- | :--- | :--- |
| customer_key | INT (PK) | Unique surrogate key for the customer. | 1 |
| customer_id | INT | Original system ID from the source. | 11000 |
| customer_number | NVARCHAR | Unique business identifier/code. | AW00011000 |
| first_name | NVARCHAR | Customer's given name. | Jon |
| last_name | NVARCHAR | Customer's family name. | Yang |
| country | NVARCHAR | Country of residence. | Australia |
| marital_status | NVARCHAR | Marital status (e.g., Single, Married). | Married |
| birthdate | DATE | Customer's date of birth. | 1971-10-06 |
| gender | NVARCHAR | Normalized gender (Male/Female). | Male |
| creation_date | DATETIME | Timestamp when the record was created. | 2025-10-06 |

---

## 2. gold.dim_products
**Purpose:** Contains master data for all products.

| Column Name | Data Type | Description | Example |
| :--- | :--- | :--- | :--- |
| product_key | INT (PK) | Unique surrogate key for the product. | 1 |
| product_id | INT | Original system ID from the source. | 210 |
| product_number | NVARCHAR | Unique business code (SKU). | FR-R92B-58 |
| product_name | NVARCHAR | Full descriptive name of the product. | HL Road Frame - Black- 58 |
| category_id | NVARCHAR | ID code for the product category. | CO_RF |
| category | NVARCHAR | High-level product category name. | Components |
| subcategory | NVARCHAR | Specific sub-level category. | Road Frames |
| maintenance | NVARCHAR | Flag indicating if maintenance is required. | Yes |
| product_line | NVARCHAR | Normalized product line name. | Road |
| cost | INT | The manufacturing or acquisition cost. | 1898 |
| product_start_date | DATE | Effective date for this product record. | 2003-07-01 |

---

## 3. gold.fact_sales
**Purpose:** Contains transactional data for all customer orders.

| Column Name | Data Type | Description | Example |
| :--- | :--- | :--- | :--- |
| order_number | NVARCHAR | Unique identifier for the sales order. | SO43697 |
| product_key | INT (FK) | Links to gold.dim_products. | 20 |
| customer_key | INT (FK) | Links to gold.dim_customers. | 10769 |
| order_date | DATE | The date the order was placed. | 2010-12-29 |
| shipping_date | DATE | The date the order was shipped. | 2011-01-05 |
| due_date | DATE | The date the payment or delivery is due. | 2011-01-10 |
| sales_total | INT | Total revenue generated (Price * Qty). | 3578 |
| quantity | INT | Number of units sold. | 1 |
| price | INT | Unit price of the product. | 3578 |
