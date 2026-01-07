# sql-DWH-project
Creating a modern Data Warehouse using SQL server (2022)! Including ETL processes, Data modeling, and data integration.

Hello! This is a Project i'll be working on the expand on my SQL knowledge. I will be taking sample data and passing it through different ETL processes through three different layers (bronze, silver, and gold). Bronze will ingest the data, silver will clean the data, and gold will analyze and transform it based on business rules.

This document outlines the high-level architecture, data flow, and modeling strategies used for this project.

Note: Unless explicitly stated, nothing seen in these projects was created or written with AI.
I believe that to actually learn what im writing down, i have to do it with my own two hands.
That being said, below is one of the two instances where AI was used. (not in creating the diagrams themselves (i have Dr.Baraa to thank for that), but rather the text and headings.
the other instance is in the data catalog, which was tedious, and i felt fine using AI, as i wrote the entire DDL scripts by hand, so i was comfortable with what i fed into the machine.
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

