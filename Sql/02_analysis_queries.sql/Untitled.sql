
-- EDA of Clean Table


-- Revenue, Total Transactions, 
SELECT
    ROUND(SUM(total_spent), 2)       AS revenue,
    COUNT(*)           				AS total_transactions,
    AVG(total_spent)    			AS avg_spend
FROM cafe_sales_clean;

-- revenue by location
SELECT 
	location,
    sum(total_spent) 		AS revenue,
    count(transaction_id)	AS num_transcations
FROM cafe_sales_clean
GROUP BY location
ORDER BY revenue Desc;
    

# Top 5 items by revenue.
SELECT 
	item,
    Sum(total_spent)		AS revenue
FROM cafe_sales_clean
GROUP BY 	item
ORDER BY 	revenue Desc
LIMIT 5;

# How Much Each Item Sold
SELECT 
	Item,
	count(*)				AS transactions
FROM cafe_sales_clean
GROUP BY 	Item
ORDER BY 	Transaction Desc;
    
    -- Before
# Monthly sales trend.
Select Date_Format(`Transaction Date`, '%Y-%m') as month,
	sum(`Total Spent`) as Revenue 
    from dirty_cafe_sales
    group by month
    order by Revenue Desc;
    
    -- After
# Monthly sales trend.
SELECT 
	Date_Format(transaction_date, '%Y-%m') 	AS month,
    SUM(total_spent)					  	AS revenue
FROM cafe_sales_clean
GROUP BY month
ORDER BY month;


    
#Before vs After
# Revenue by location, by payment method, by item.

	-- Before
select Location ,sum(`Total Spent`) ' Location Revenue' from dirty_cafe_sales 
	group by Location;
    
	-- After
select location ,sum(total_spent) 'clean location Revenue' from cafe_sales_clean 
	group by location;
    
	-- Before
select `Payment Method` ,sum(`Total Spent`) ' Payment Revenue' from dirty_cafe_sales 
	group by `Payment Method`;
    
    -- After        
select payment_method ,sum(total_spent) 'clean payment_method Revenue' from cafe_sales_clean 
	group by payment_method;
    
	-- Before
select Item ,sum(`Total Spent`) 'Item Revenue' from dirty_cafe_sales 
	group by Item;
    
     -- After   
select item ,sum(total_spent) 'clean item Revenue' from cafe_sales_clean 
	group by item;





    



