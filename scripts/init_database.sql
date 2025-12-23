/*
Simply Creating the database and Schemas
*/
USE master;
Go
-- check if db already exists

IF EXISTS (SELECT 1 from sys.databases WHERE name = 'DataWareHouse')
BEGIN
  ALTER DATABASE DataWareHouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE DataWareHouse;
END;
GO

-- create new database

CREATE DATABASE DataWareHouse;
GO

USE DataWareHouse;
GO

--Create Schemas

CREATE SCHEMA bronze;
go
CREATE SCHEMA silver;
go
CREATE SCHEMA gold;
go
