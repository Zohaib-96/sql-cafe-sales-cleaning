
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





-- 1: Create an item_category table
CREATE TABLE item_category (
	item_name VARCHAR(50),
    category VARCHAR(50),
    is_hot_cold VARCHAR(50)
    );
       
INSERT INTO item_category (item_name, category, is_hot_cold)  VALUES
('Coffee', 'Beverage', 'Hot'),
('Tea', 'Beverage', 'Hot'),
('Juice', 'Beverage', 'Cold'),
('Smoothie', 'Beverage', 'Cold'),
('Cake', 'Food', 'Neither'),
('Cookie', 'Food', 'Neither'),
('Sandwich', 'Food', 'Neither'),
('Salad', 'Food', 'Neither'),
('Unknown item', 'Unknown', 'Unknown');


		-- JOINS
-- 1: INNER JOIN, let's see revenue by Category (Food vs. Beverage).
SELECT 
    c.category,
    SUM(s.total_spent) as revenue,
    count(s.transaction_id) as transactions
FROM cafe_sales_clean s
Join item_category c ON 
	c.item_name = s.item
group by c.category
order by transactions Desc;

-- 2: Do people spend more on Hot or Cold drinks?
SELECT 
    c.is_hot_cold,
    Sum(s.total_spent) AS revenue,
	Count(s.transaction_id) AS transactions
FROM cafe_sales_clean s
INNER JOIN item_category c
	ON s.item = c.item_name
Where  c.category = 'Beverage'
group by c.is_hot_cold
Order by transactions DESC;

-- 3: "Looking only at the 'Food' category, what is the total quantity sold for each item?
SELECT 
	s.item,
	SUM(s.quantity) AS total_quantity,
    SUM(s.total_spent) AS revenue,
    COUNT(s.transaction_id) AS transactions
FROM cafe_sales_clean s
INNER JOIN item_category c 
	ON s.item = c.item_name
Where c.category = 'Food'
group by s.item 
order by total_quantity DESC;

-- 4: Category Performance by Location
SELECT 
	s.location,
	c.category,
    SUM(s.total_spent) AS revenue
FROM cafe_sales_clean s
INNER JOIN item_category c 
	ON s.item = c.item_name
group by c.category ,s.location
order by revenue DESC;

-- 5: High-Value Food Transactions
SELECT 
	c.item_name					AS item,
    s.location					AS location,
    s.transaction_date 			AS transaction_date,
    s.total_spent				AS revenue
FROM cafe_sales_clean s
INNER JOIN item_category c
	ON s.item = c.item_name
Where c.category = 'Food' 
	AND s.total_spent > 20
Order by s.location
limit 5000;

-- 6: Monthly Beverage Revenue
SELECT 
	Date_Format(s.transaction_date,  '%Y-%m')	AS month,
    c.category									AS item,
    Sum(s.total_spent)							AS revenue
FROM cafe_sales_clean s 
INNER JOIN item_category c
	ON s.item = c.item_name
WHERE c.category = 'Beverage'
group by month
order by month;

-- 7: Which specific items (like Coffee, Cake, etc.) 
-- generated more than $10,000 in total revenue?

SELECT 
	s.item 							AS item,
    c.category						AS category,
    SUM(s.total_spent)				AS revenue
FROM cafe_sales_clean s
INNER JOIN item_category c
	ON s.item = c.item_name
Group by category, item
having revenue > 10000
order by revenue Desc;

		-- CTE
-- 1: Month-over-month revenue change
WIth monthly_rev AS (
		SELECT
			DATE_FORMAT(transaction_date, '%Y-%m-01') AS report_month,
			SUM(total_spent) AS revenue
		FROM cafe_sales_clean
		WHERE transaction_date IS NOT NULL
		GROUP BY report_month
  )
  
	Select 
		m_current.report_month,
        m_current.revenue						AS current_month_rev,
        m_previous.revenue						AS prev_month_rev,
		m_current.revenue - m_previous.revenue	AS revenue_diff
        
	FROM monthly_rev m_current
    LEFT JOIN monthly_rev m_previous
    ON m_current.report_month = DATE_ADD(m_previous.report_month, interval 1 month)
    order by m_current.report_month;
    
-- 2: Revenue share by payment method
    
WITH total_rev AS (
	SELECT 
		SUM(total_spent) 		AS grand_total
	FROM cafe_sales_clean
),
pay_rev AS (
	SELECT 
		payment_method,
		SUM(total_spent) 		AS pay_method_rev
	FROM cafe_sales_clean
	group by payment_method
        )
	-- Combine them to calculate the percentage
SELECT 
	p.payment_method,
    p.pay_method_rev,
    ROUND((p.pay_method_rev / t.grand_total) * 100 ,2) AS percent_of_total
FROM pay_rev p
CROSS JOIN total_rev t;

-- 3: Which items generated more revenue than the average item's revenue?

WITH ItemRevenues AS (
		-- 1 calculate Revenue per item
		Select 
			item						AS item,
			SUM(total_spent)			AS item_rev
		FROM cafe_sales_clean
		group by item
	),
		-- 2 calculate the average of above revenues.
	AverageRevenue AS (
		select 
			avg(item_rev)				AS avg_rev
		FROM ItemRevenues
)
		-- revenue greater then average item's revenue

    Select 
		i.item,
        i.item_rev
	FROM ItemRevenues i
    CROSS JOIN AverageRevenue a
    WHERE i.item_rev > a.avg_rev
    ORDER BY i.item_rev DESC;

		-- 3.1: NO 3 with sub query

			select 
				item, sum(total_spent) as total_rev
			FROM cafe_sales_clean group by item
			having total_rev > (
				select avg(item_total) 
				FROM (
					SELECT sum(total_spent) as item_total 
					from cafe_sales_clean group by item
			) AS sub
			);


-- 4: What percentage of transactions in the 'In-store' location used Cash vs. Credit Card?"

WITH totalinstore AS (
	SELECT COUNT(*) AS total_tx
    FROM cafe_sales_clean
    WHERE location = 'In-store'
),
	paymentinstore AS (
		SELECT payment_method, 
		count(*) 	AS method_tx
        FROM cafe_sales_clean
        WHERE location = 'In-store'
        GROUP BY payment_method
	)
	
SELECT 
	pt.payment_method,
    pt.method_tx,
    st.total_tx,
    ROUND(pt.method_tx / st.total_tx * 100, 1) 		AS percentage
FROM totalinstore st 
CROSS JOIN paymentinstore pt
order by percentage DESC;

-- 5: Calculates revenue per item for EVERY day (Daily Highs)
    
WITH HighRevenueDays AS (
	select 
	transaction_date,
    sum(total_spent)	as daily_total
    from cafe_sales_clean
    group by transaction_date
    having daily_total > 320
),
	DailyItemRevenue AS (
    select 
    item,
    transaction_date,
    sum(total_spent)	item_daily_total
    from cafe_sales_clean
    group by transaction_date, item
    )
select 
	h.transaction_date as transaction_date,
    h.daily_total,
    d.item,
    d.item_daily_total	as top_item
FROM HighRevenueDays h
JOIN DailyItemRevenue d 
ON h.transaction_date = d.transaction_date
WHERE (
    SELECT COUNT(*)
    FROM DailyItemRevenue d2
    WHERE d2.transaction_date = d.transaction_date
      AND d2.item_daily_total > d.item_daily_total
) = 0
ORDER BY h.transaction_date;






-- 1: Create an item_category table
CREATE TABLE item_category (
	item_name VARCHAR(50),
    category VARCHAR(50),
    is_hot_cold VARCHAR(50)
    );
       
INSERT INTO item_category (item_name, category, is_hot_cold)  VALUES
('Coffee', 'Beverage', 'Hot'),
('Tea', 'Beverage', 'Hot'),
('Juice', 'Beverage', 'Cold'),
('Smoothie', 'Beverage', 'Cold'),
('Cake', 'Food', 'Neither'),
('Cookie', 'Food', 'Neither'),
('Sandwich', 'Food', 'Neither'),
('Salad', 'Food', 'Neither'),
('Unknown item', 'Unknown', 'Unknown');


		-- JOINS
-- 1: INNER JOIN, let's see revenue by Category (Food vs. Beverage).
SELECT 
    c.category,
    SUM(s.total_spent) as revenue,
    count(s.transaction_id) as transactions
FROM cafe_sales_clean s
Join item_category c ON 
	c.item_name = s.item
group by c.category
order by transactions Desc;

-- 2: Do people spend more on Hot or Cold drinks?
SELECT 
    c.is_hot_cold,
    Sum(s.total_spent) AS revenue,
	Count(s.transaction_id) AS transactions
FROM cafe_sales_clean s
INNER JOIN item_category c
	ON s.item = c.item_name
Where  c.category = 'Beverage'
group by c.is_hot_cold
Order by transactions DESC;

-- 3: "Looking only at the 'Food' category, what is the total quantity sold for each item?
SELECT 
	s.item,
	SUM(s.quantity) AS total_quantity,
    SUM(s.total_spent) AS revenue,
    COUNT(s.transaction_id) AS transactions
FROM cafe_sales_clean s
INNER JOIN item_category c 
	ON s.item = c.item_name
Where c.category = 'Food'
group by s.item 
order by total_quantity DESC;

-- 4: Category Performance by Location
SELECT 
	s.location,
	c.category,
    SUM(s.total_spent) AS revenue
FROM cafe_sales_clean s
INNER JOIN item_category c 
	ON s.item = c.item_name
group by c.category ,s.location
order by revenue DESC;

-- 5: High-Value Food Transactions
SELECT 
	c.item_name					AS item,
    s.location					AS location,
    s.transaction_date 			AS transaction_date,
    s.total_spent				AS revenue
FROM cafe_sales_clean s
INNER JOIN item_category c
	ON s.item = c.item_name
Where c.category = 'Food' 
	AND s.total_spent > 20
Order by s.location
limit 5000;

-- 6: Monthly Beverage Revenue
SELECT 
	Date_Format(s.transaction_date,  '%Y-%m')	AS month,
    c.category									AS item,
    Sum(s.total_spent)							AS revenue
FROM cafe_sales_clean s 
INNER JOIN item_category c
	ON s.item = c.item_name
WHERE c.category = 'Beverage'
group by month
order by month;

-- 7: Which specific items (like Coffee, Cake, etc.) 
-- generated more than $10,000 in total revenue?

SELECT 
	s.item 							AS item,
    c.category						AS category,
    SUM(s.total_spent)				AS revenue
FROM cafe_sales_clean s
INNER JOIN item_category c
	ON s.item = c.item_name
Group by category, item
having revenue > 10000
order by revenue Desc;

		-- CTE
-- 1: Month-over-month revenue change
WIth monthly_rev AS (
		SELECT
			DATE_FORMAT(transaction_date, '%Y-%m-01') AS report_month,
			SUM(total_spent) AS revenue
		FROM cafe_sales_clean
		WHERE transaction_date IS NOT NULL
		GROUP BY report_month
  )
  
	Select 
		m_current.report_month,
        m_current.revenue						AS current_month_rev,
        m_previous.revenue						AS prev_month_rev,
		m_current.revenue - m_previous.revenue	AS revenue_diff
        
	FROM monthly_rev m_current
    LEFT JOIN monthly_rev m_previous
    ON m_current.report_month = DATE_ADD(m_previous.report_month, interval 1 month)
    order by m_current.report_month;
    
-- 2: Revenue share by payment method
    
WITH total_rev AS (
	SELECT 
		SUM(total_spent) 		AS grand_total
	FROM cafe_sales_clean
),
pay_rev AS (
	SELECT 
		payment_method,
		SUM(total_spent) 		AS pay_method_rev
	FROM cafe_sales_clean
	group by payment_method
        )
	-- Combine them to calculate the percentage
SELECT 
	p.payment_method,
    p.pay_method_rev,
    ROUND((p.pay_method_rev / t.grand_total) * 100 ,2) AS percent_of_total
FROM pay_rev p
CROSS JOIN total_rev t;

-- 3: Which items generated more revenue than the average item's revenue?

WITH ItemRevenues AS (
		-- 1 calculate Revenue per item
		Select 
			item						AS item,
			SUM(total_spent)			AS item_rev
		FROM cafe_sales_clean
		group by item
	),
		-- 2 calculate the average of above revenues.
	AverageRevenue AS (
		select 
			avg(item_rev)				AS avg_rev
		FROM ItemRevenues
)
		-- revenue greater then average item's revenue

    Select 
		i.item,
        i.item_rev
	FROM ItemRevenues i
    CROSS JOIN AverageRevenue a
    WHERE i.item_rev > a.avg_rev
    ORDER BY i.item_rev DESC;

		-- 3.1: NO 3 with sub query

			select 
				item, sum(total_spent) as total_rev
			FROM cafe_sales_clean group by item
			having total_rev > (
				select avg(item_total) 
				FROM (
					SELECT sum(total_spent) as item_total 
					from cafe_sales_clean group by item
			) AS sub
			);


-- 4: What percentage of transactions in the 'In-store' location used Cash vs. Credit Card?"

WITH totalinstore AS (
	SELECT COUNT(*) AS total_tx
    FROM cafe_sales_clean
    WHERE location = 'In-store'
),
	paymentinstore AS (
		SELECT payment_method, 
		count(*) 	AS method_tx
        FROM cafe_sales_clean
        WHERE location = 'In-store'
        GROUP BY payment_method
	)
	
SELECT 
	pt.payment_method,
    pt.method_tx,
    st.total_tx,
    ROUND(pt.method_tx / st.total_tx * 100, 1) 		AS percentage
FROM totalinstore st 
CROSS JOIN paymentinstore pt
order by percentage DESC;

-- 5: Calculates revenue per item for EVERY day (Daily Highs)
    
WITH HighRevenueDays AS (
	select 
	transaction_date,
    sum(total_spent)	as daily_total
    from cafe_sales_clean
    group by transaction_date
    having daily_total > 320
),
	DailyItemRevenue AS (
    select 
    item,
    transaction_date,
    sum(total_spent)	item_daily_total
    from cafe_sales_clean
    group by transaction_date, item
    )
select 
	h.transaction_date as transaction_date,
    h.daily_total,
    d.item,
    d.item_daily_total	as top_item
FROM HighRevenueDays h
JOIN DailyItemRevenue d 
ON h.transaction_date = d.transaction_date
WHERE (
    SELECT COUNT(*)
    FROM DailyItemRevenue d2
    WHERE d2.transaction_date = d.transaction_date
      AND d2.item_daily_total > d.item_daily_total
) = 0
ORDER BY h.transaction_date;






    



