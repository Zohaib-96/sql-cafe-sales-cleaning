# Cafe Sales – SQL Data Cleaning and Analysis

<p align="left">
  <img src="https://img.shields.io/badge/MySQL-100%25-blue?style=for-the-badge&logo=mysql&logoColor=white"/>
</p>

This project is a small end‑to‑end example of cleaning and analysing a **dirty cafe sales dataset** with **MySQL**.  
The goal is to show how I can work with messy real‑world data and prepare it for analysis.

---

## Dataset

- Source: https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training/data
- Rows: 10,000
- Columns: 8
  - Transaction ID  
  - Item  
  - Quantity  
  - Price Per Unit  
  - Total Spent  
  - Payment Method  
  - Location  
  - Transaction Date  

The raw table contains many issues: missing values, `UNKNOWN` / `ERROR` strings, inconsistent text, and incorrect totals.

---

## Database Objects

- **Raw table:** `dirty_cafe_sales`  
- **Staging view:** `c_cafe_view`  
- **Clean table:** `cafe_sales_clean`  

SQL scripts:

- `sql/01_create_clean_table.sql` – full cleaning pipeline  
- `sql/02_analysis_queries.sql` – analysis / reporting queries

---

## Data Cleaning Steps (SQL)

1. **Profiling the raw data**
   - Described the table structure.
   - Counted total rows.
   - Checked random samples.
   - Counted missing / bad values using conditions on `NULL`, empty strings, `UNKNOWN`, and `ERROR`.
   - Listed distinct values for `Item`, `Payment Method`, `Location`, etc.
   - Checked duplicates based on `Transaction ID`.

2. **Creating a staging view (`c_cafe_view`)**
   - Used `TRIM()` to remove extra spaces.
   - Replaced `UNKNOWN`, `ERROR`, and empty strings with `NULL` for:
     - Item  
     - Quantity  
     - Price Per Unit  
     - Total Spent  
     - Payment Method  
     - Location  
     - Transaction Date  
   - Kept each column in a `_raw` form (for example: `item_raw`, `total_raw`).

3. **Building the clean table (`cafe_sales_clean`)**
   - Created a new table from the view with:
     - `transaction_id` (from raw text id)
     - `item` – `COALESCE(item_raw, 'Unknown item')`
     - `quantity_num` – `CAST(quantitiy_raw AS UNSIGNED)`
     - `price_per_unit_num` – `CAST(price_raw AS DECIMAL(10,2))`
     - `total_spent_num` – `CAST(total_raw AS DECIMAL(10,2))`
     - `location` – `COALESCE(location_raw, 'Unknown location')`
     - `payment_method` – `COALESCE(payment_raw, 'Unspecified')`
     - `transaction_date_raw` – cleaned text date
   - This separates the clean numeric fields from the original text.

4. **Recomputing numeric values**
   - Ensured the three main numeric columns are consistent:
     - `total_spent_num = quantity_num * price_per_unit_num`
   - Used three `UPDATE` statements:
     - If **total_spent_num** is `NULL` but quantity and price exist, set `total_spent_num = quantity_num * price_per_unit_num`.
     - If **price_per_unit_num** is `NULL` but total and quantity exist, set `price_per_unit_num = total_spent_num / quantity_num`.
     - If **quantity_num** is `NULL` but total and price exist, set `quantity_num = total_spent_num / price_per_unit_num`.
   - Checked how many rows still had missing numeric values after this step.

5. **Cleaning categories**
   - Standardised **payment method**:
     - Replaced missing / invalid values with `Unspecified`.
     - Mapped values like `unspecified` to `Unspecified`.
   - Standardised **location**:
     - Replaced missing values with `Unknown location`.

6. **Handling dates**
   - Counted how many rows had `NULL` or empty transaction dates.
   - Removed rows with completely missing transaction dates (for a clean time series).
   - Converted `transaction_date_raw` from text to `DATE` and renamed it to `transaction_date`.

7. **Renaming columns for analysis**
   - Renamed:
     - `total_spent_num` → `total_spent`
     - `quantity_num`   → `quantity`
     - `price_per_unit_num` → `price_per_unit`

The final table `cafe_sales_clean` is ready for analysis and reporting.

---

## Exploratory Data Analysis (SQL)

All queries are stored in `sql/02_analysis_queries.sql`.

1. **Key metrics**

```sql
SELECT
    SUM(total_spent)   AS revenue,
    COUNT(*)           AS total_transactions,
    AVG(total_spent)   AS avg_spend
FROM cafe_sales_clean;

result:
Revenue: 76,690.50
Total transactions: 8,596
Average spend per transaction: ~8.92

#Revenue by location

SELECT 
    location,
    SUM(total_spent)      AS revenue,
    COUNT(transaction_id) AS num_transactions
FROM cafe_sales_clean
GROUP BY location
ORDER BY revenue DESC;

insight:
Unknown location has the highest recorded revenue, followed by In‑store and Takeaway.

#Top 5 items by revenue

SELECT 
    item,
    SUM(total_spent) AS revenue
FROM cafe_sales_clean
GROUP BY item
ORDER BY revenue DESC
LIMIT 5;


SELECT 
    item,
    SUM(total_spent) AS revenue
FROM cafe_sales_clean
GROUP BY item
ORDER BY revenue DESC
LIMIT 5;

Result:

Salad
Sandwich
Smoothie
Juice
Cake

#How many times each item was sold

SELECT 
    item,
    COUNT(*) AS transactions
FROM cafe_sales_clean
GROUP BY item
ORDER BY transactions DESC;

Monthly sales trend
SELECT 
    DATE_FORMAT(transaction_date, '%Y-%m') AS month,
    SUM(total_spent)                       AS revenue
FROM cafe_sales_clean
GROUP BY month
ORDER BY month;

This query gives a clean monthly revenue view for 2023, which is more accurate than the trend from the raw table.
