  
--  Prerequiset Data cleaning --

#describe
DESCRIBE dirty_cafe_sales;

SELECT * 
FROM dirty_cafe_sales
LIMIT 20 OFFSET 500;

#count rows 9006
SELECT COUNT(*) AS total_rows
FROM dirty_cafe_sales;

    
# 1. Random Check

select * 
from dirty_cafe_sales 
Where Item = 'Coffee'
    And Location = 'In-Store'
    And `Payment Method` = 'Cash';

# 2. Random Check   
Select 
	`Total Spent`,  
	Sum(`Total Spent`) totalSpend 
from dirty_cafe_sales 
group by `Total Spent`;

#look for messing data, which columns need cleaning most.
select 
	SUM(Case when `Transaction ID` is Null OR TRIM(`Transaction ID`) = 
    '' OR  UPPER(TRIM(`Transaction ID`)) in ('UNKNOWN','ERROR') 
    then 1 else 0 end) as messing_transcation_id,
    
    SUM(Case when Item is null OR TRIM(Item) = '' OR UPPER(TRIM(Item)
    in ('UNKNOWN','ERROR')) then 1 else 0 end) as messing_item,
    
    Sum(Case when Quantity is null OR TRIM(Quantity) = '' OR upper(TRIM(Quantity)
	in ('UNKNOWN','ERROR')) then 1 else 0 end) as messing_quantity,
    
    SUM(Case when `Price Per Unit` is null OR  TRIM(`Price Per Unit`) = '' 
    OR UPPER(TRIM( `Price Per Unit`) in ('UNKNOWN','ERROR'))  then 1 else 0 end) as messing_unit_price,
    
    SUM(CASE WHEN `Price Per Unit` IS NULL OR TRIM(`Price Per Unit`) = '' OR 
    UPPER(TRIM(`Price Per Unit`)) IN ('UNKNOWN','ERROR') THEN 1 ELSE 0 END) AS missing_price,
    
    SUM(CASE WHEN `Total Spent` IS NULL OR TRIM(`Total Spent`) = '' 
    OR UPPER(TRIM(`Total Spent`)) 
    IN ('UNKNOWN','ERROR') THEN 1 ELSE 0 END) AS missing_total,
    
	SUM(CASE WHEN `Payment Method` IS NULL OR TRIM(`Payment Method`) = '' 
	OR UPPER(TRIM(`Payment Method`)) 
	IN ('UNKNOWN','ERROR') THEN 1 ELSE 0 END) AS missing_payment_method,
  
	SUM(CASE WHEN Location IS NULL OR TRIM(Location) = '' OR UPPER(TRIM(Location)) 
	IN ('UNKNOWN','ERROR') THEN 1 ELSE 0 END) AS missing_location,
	
    SUM(CASE WHEN `Transaction Date` IS NULL OR TRIM(`Transaction Date`) = '' 
    OR UPPER(TRIM(`Transaction Date`)) IN ('UNKNOWN','ERROR') THEN 1 ELSE 0 END) AS missing_transaction_date
    
FROM dirty_cafe_sales;
    
#check DISTINCT values
	SELECT DISTINCT Item
	FROM dirty_cafe_sales
	ORDER BY Item;

	SELECT DISTINCT `Payment Method`
	FROM dirty_cafe_sales
	ORDER BY `Payment Method`;
    
	SELECT DISTINCT Quantity
	FROM dirty_cafe_sales
	ORDER BY Quantity;
    
	SELECT DISTINCT `Total Spent`
	FROM dirty_cafe_sales
	ORDER BY `Total Spent`;
    
	SELECT DISTINCT Location
	FROM dirty_cafe_sales
	ORDER BY Location;
    
    SELECT DISTINCT `Transaction Date`
	FROM dirty_cafe_sales
	ORDER BY `Transaction Date`;

#  check duplicates
	select `Transaction ID`, count(*) as cnt
	from dirty_cafe_sales 
	group by `Transaction ID`
	having cnt > 1;
    



-- Data cleaning

# Create a VIEW 
CREATE or REPLACE VIEW c_cafe_view AS

# Count of unknown items / unspecified payments.
select Item ,Count(Item) from dirty_cafe_sales 
	group by Item
    Having item = 'UNKNOWN' 
    Or item = 'ERROR';
    
# Replace unknown / unspecified data With Nulls.  
SELECT 
	nullif(Trim(`Transaction ID`), '') AS Trasaction_id_raw,
  -- Replace('UNKNOWN', 'ERROR') with NULL in Coulmn item
  CASE
	WHEN Item IS NUll OR TRIM(item) = '' OR UPPER(TRIM(Item)) 
		IN ('UNKNOWN', 'ERROR')
			THEN NULL
		ELSE TRIM(Item)
        END AS item_raw,
  -- Replace('UNKNOWN', 'ERROR') with NULL in Coulmn Quantity
  CASE
	WHEN Quantity IS NULL OR TRIM(Quantity) = '' OR UPPER(TRIM(Quantity)) 
		IN ('UNKNOWN', 'ERROR')
			THEN NULL 
		ELSE TRIM(Quantity)
        END AS quantitiy_raw,
  -- Replace('UNKNOWN', 'ERROR') with NULL in Coulmn Price Per Unit
  CASE
	WHEN `Price Per Unit` IS NULL OR TRIM(`Price Per Unit`) = '' 
		OR UPPER(TRIM(`Price Per Unit`)) IN ('UNKNOWN', 'ERROR') 
			THEN NULL
		ELSE TRIM(`Price Per Unit`) 
        END AS price_raw,
  -- Replace('UNKNOWN', 'ERROR') with NULL in Coulmn Total Spent
  CASE
    WHEN `Total Spent` IS NULL OR TRIM(`Total Spent`) = '' OR UPPER(TRIM(`Total Spent`)) 
    IN ('UNKNOWN','ERROR')
      THEN NULL
    ELSE TRIM(`Total Spent`)
  END AS total_raw,

  -- Replace('UNKNOWN', 'ERROR') with NULL in Coulmn Payment Method
  CASE
    WHEN `Payment Method` IS NULL OR TRIM(`Payment Method`) = '' OR UPPER(TRIM(`Payment Method`))
    IN ('UNKNOWN','ERROR')
      THEN NULL
    ELSE TRIM(`Payment Method`)
  END AS payment_raw,

  -- Replace('UNKNOWN', 'ERROR') with NULL in Coulmn Location
  CASE
    WHEN Location IS NULL OR TRIM(Location) = '' OR UPPER(TRIM(Location)) 
    IN ('UNKNOWN','ERROR')
      THEN NULL
    ELSE TRIM(Location)
  END AS location_raw,

  -- Replace('UNKNOWN', 'ERROR') with NULL in Coulmn Transaction Date
  CASE
    WHEN `Transaction Date` IS NULL OR TRIM(`Transaction Date`) = '' 
    OR UPPER(TRIM(`Transaction Date`)) IN ('UNKNOWN','ERROR')
      THEN NULL
    ELSE TRIM(`Transaction Date`)
  END AS date_raw;

        
select * from c_cafe_view;

#to see ('UNKNOWN','ERROR') replaced with NULL
Select distinct(payment_raw) from c_cafe_view;



-- Data cleaning: Create a New Clean Table

#Drop if Exists
DROP Table if exists cafe_sales_clean;

#Create Table
Create Table cafe_sales_clean AS

Select 
	Trasaction_id_raw AS transaction_id,
    
    coalesce(item_raw, 'Unknown item') as item,
    
    CAST(quantitiy_raw AS UNSIGNED) AS quantity_num,
	CAST(price_raw    AS DECIMAL(10,2)) AS price_per_unit_num,
	CAST(total_raw    AS DECIMAL(10,2)) AS total_spent_num,
    
    coalesce(location_raw, 'unknown location') as location,
    coalesce(payment_raw, 'unspecified') as payment_method,
    
    date_raw as transaction_date_raw
    
from c_cafe_view;
    
#query the created table
select * 
	from cafe_sales_clean;

#Total Spent = Quantity × Price Per Unit, check rows where this doesn’t match.
select * 
	from cafe_sales_clean
where (quantity_num * price_per_unit_num) <> total_spent_num;

#calculate the null total_spent, where we have either quantity_num or price_per_unit_num

	-- first check the null total spent (462 NULL)
    select  count(*) as missing_total_count 
		from cafe_sales_clean
	where total_spent_num is Null;
    
	-- calculate the total_spent_num if quantity_num AND price_per_unit_num Exist
    UPDATE cafe_sales_clean
    SET total_spent_num =  ROUND(quantity_num * price_per_unit_num, 2)
    WHERE total_spent_num IS NULL
    AND quantity_num IS NOT NULL
    AND price_per_unit_num IS NOT NULL;
    
	-- calculate the price_per_unit_num if quantity_num AND total_spent_num Exist
	UPDATE cafe_sales_clean
    SET price_per_unit_num =  ROUND(total_spent_num / quantity_num, 2)
    WHERE price_per_unit_num IS NULL
    AND quantity_num IS NOT NULL
    AND total_spent_num IS NOT NULL;
    
	-- calculate the quantity_num if total_spent_num AND price_per_unit_num Exist
	UPDATE cafe_sales_clean
    SET quantity_num = ROUND(total_spent_num / price_per_unit_num, 2)
    WHERE quantity_num IS NULL
	AND total_spent_num IS NOT NULL
    AND price_per_unit_num IS NOT NULL;
    
    -- How many rows still have numbers missing? 
    Select count(*) as missing_rows
    from cafe_sales_clean
    WHERE quantity_num IS NULL
	OR price_per_unit_num IS NULL
	OR total_spent_num IS NULL; 
    
#Look for ('UNKNOWN','ERROR') and Empty data in columns
select * from cafe_sales_clean;

Select 
	distinct(item) 
from cafe_sales_clean;
    
Select 
	distinct(quantity_num) 
from cafe_sales_clean;
    
Select 
	distinct(price_per_unit_num) 
from cafe_sales_clean;

Select 
	distinct(total_spent_num) 
from cafe_sales_clean;

Select 
	distinct(location) 
from cafe_sales_clean;

	-- payment_method 
Select 
	distinct(payment_method) 
from cafe_sales_clean;

	-- payment_method update
UPDATE cafe_sales_clean
set payment_method = 'Unspecified'
	where payment_method = 'unspecified';

	-- transaction_date_raw have Nulls
Select 
	distinct(transaction_date_raw) 
from cafe_sales_clean;
	
    -- Count Nulls (410)
select 
	Count(*) as null_date_count
    from cafe_sales_clean
where transaction_date_raw is null 
	or TRIM(transaction_date_raw) = '';
    
    -- Null percentage 4.55
select 
	ROUND(count(*) * 100.0 / (select count(*) from cafe_sales_clean), 2) as percentage_null_date
    from cafe_sales_clean
where transaction_date_raw is null 
	or TRIM(transaction_date_raw) = '';
    
	-- Remove Null trasactions date rows
delete from cafe_sales_clean
where transaction_date_raw is Null
	OR transaction_date_raw = '';
	-- change Date cloumn data type to DATE from text
ALTER TABLE cafe_sales_clean
modify COLUMN transaction_date_raw DATE;	

ALTER TABLE cafe_sales_clean
RENAME COLUMN transaction_date_raw  to transaction_date;	

ALTER TABLE cafe_sales_clean
RENAME COLUMN total_spent_num  to total_spent;	

ALTER TABLE cafe_sales_clean
RENAME COLUMN quantity_num  to quantity;	

ALTER TABLE cafe_sales_clean
RENAME COLUMN price_per_unit_num  to price_per_unit;	

describe cafe_sales_clean;


		




