# SQL-Modern-Medallion-DWH
Creating a Modern Data Warehouse using SQL server (2022)! 

This Data Warehouse uses the ***Medallion Architecture*** (**Bronze**- data ingestion, **Silver**- cleansing/standardization, **Gold**- Fully integrated data views w/ business logic)

designing and implementing everything by hand really lets you appreciate how much detail goes into getting clean data.
This project took me around 12 hours of dedicated focus.

**Note on AI Usage**: Unless explicitly stated, **NOTHING** seen in these projects was created or written by AI.
I believe that to actually learn what im writing down, i have to do it with my own two hands.

That being said, below is one of the two instances where AI was used (making the README file easier on the eyes).

-the other instance is in the data catalog, which was tedious, and i felt fine using AI, as any DDL scripts being references was written by yours truly.
---

## 🏛️ Data Warehouse Architecture
*High-level overview of the server environments, layers (Bronze, Silver, Gold), and storage components.*

<img width="879" height="394" alt="DWH Structure" src="https://github.com/user-attachments/assets/a2864783-3adb-46b7-8a59-ed182c95b0b1" />


---

## 🔄 Data Lineage & Flow
*Visual representation of how data moves from source systems through transformations into the final presentation layer.*

<img width="879" height="483" alt="DWH Data Flow" src="https://github.com/user-attachments/assets/7007265e-46f4-438d-b679-71f580c7179f" />


---

## 🧩 Integration Model
*Details on how different source entities are mapped and integrated into a unified format within the Silver layer.*

<img width="879" height="799" alt="DWH Integration Model" src="https://github.com/user-attachments/assets/7f5c1b65-ac27-4ae6-abb8-7ba5074fbe2f" />


---

## 📊 Data Mart (Star Schema)
*The final dimensional model (Fact and Dimension tables) optimized for business intelligence and reporting.*

<img width="879" height="635" alt="DWH Data Mart (star schema)" src="https://github.com/user-attachments/assets/f6e78122-ff77-444d-bfd5-bd4af175c85d" />

