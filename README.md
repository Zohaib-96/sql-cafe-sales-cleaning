# ☕ Cafe Sales – SQL Data Cleaning, Joins, and Analysis

<p align="left">
  <img src="https://img.shields.io/badge/MySQL-100%25-blue?style=for-the-badge&logo=mysql&logoColor=white"/>
</p>

This project is an end‑to‑end example of taking a **dirty cafe sales dataset** from Kaggle, cleaning it with **MySQL**, and then analysing it using **joins, CTEs, and basic window‑style logic**.  
The goal is to show that I can work with messy real‑world data, turn it into a clean table, and answer business questions using SQL.

---

## 📂 Dataset

- Source: [Kaggle – Cafe Sales – Dirty Data for Cleaning Training](https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training/data) [web:21]
- Rows: ~10,000  
- Columns: 8  
  - Transaction ID  
  - Item  
  - Quantity  
  - Price Per Unit  
  - Total Spent  
  - Payment Method  
  - Location  
  - Transaction Date  

**The raw data contains:**
- Missing values  
- `UNKNOWN` / `ERROR` strings  
- Inconsistent text (different spellings/casing)  
- Incorrect or missing totals  

---

## 🏗️ Database Objects & Files

**Tables & View**
- `dirty_cafe_sales` – original raw data  
- `c_cafe_view` – staging view used to standardise text and NULLs  
- `cafe_sales_clean` – final cleaned fact table  
- `item_category` – small lookup/dimension table that maps each item to:
  - `category` (Food vs Beverage vs Unknown)  
  - `is_hot_cold` (Hot, Cold, Neither)


## Project Structure

```text
Sql/
├── 01_create_clean_table.sql
│   ├── Profiling raw data
│   ├── Creating staging view
│   ├── Building cafe_sales_clean
│   ├── Creating item_category lookup
│   └── Core cleaning, joins, CTE utilities
└── 02_analysis_queries.sql
    ├── KPI queries
    ├── Revenue breakdowns
    ├── Monthly trend
    └── CTE business questions
```


## 🧹 Data Cleaning (SQL)

### 1. Profiling the raw data
- Used DESCRIBE and COUNT(*) to understand shape (≈9k rows after import)
- Wrote conditional SUM(CASE WHEN ...) checks to count:
- Nulls, empty strings, UNKNOWN, ERROR in text columns
- Used SELECT DISTINCT to inspect Item, Payment Method, Location, Transaction Date
- Checked duplicate Transaction ID with GROUP BY ... HAVING COUNT(*) > 1

### 2. Staging view (`c_cafe_view`)
Applied TRIM() to remove extra spaces from text
- Converted dirty values ('', UNKNOWN, ERROR) to NULL for:
- Item, Quantity, Price Per Unit, Total Spent, Payment Method, Location, Transaction Date
- Kept "raw" versions (item_raw, quantity_raw, price_raw, total_raw, payment_raw, location_raw, date_raw)

### 3. Building clean table (`cafe_sales_clean`)
CREATE TABLE cafe_sales_clean AS SELECT from c_cafe_view with:
- transaction_id – from transaction_id_raw
- item – COALESCE(item_raw, 'Unknown item')
- quantity_num – CAST(quantity_raw AS UNSIGNED)
- price_per_unit_num – CAST(price_raw AS DECIMAL(10,2))
- total_spent_num – CAST(total_raw AS DECIMAL(10,2))
- payment_method – COALESCE(payment_raw, 'Unspecified')
- location – COALESCE(location_raw, 'Unknown location')
- transaction_date_raw – cleaned text version of the date

### 4. Recomputing numeric values
- Ensured Quantity × Price Per Unit = Total Spent consistency:
- If total_spent_num NULL but quantity_num and price_per_unit_num exist → recompute
- If price_per_unit_num NULL but total_spent_num and quantity_num exist → recompute
- If quantity_num NULL but total_spent_num and price_per_unit_num exist → recompute

### 5. Cleaning categories
- Payment method: Normalised strings with LOWER() and CASE → Cash, Credit Card, Digital Wallet, Unspecified
- Location: Filled missing/invalid → 'Unknown location'
  
### 6. Handling dates
- Input dates in YYYY-MM-DD format
- Used CAST(... AS DATE) → transaction_date column
- Kept rows with NULL dates, filtered for time series analysis

### 7. Final renaming
- quantity_num → quantity
- price_per_unit_num → price_per_unit
- total_spent_num → total_spent

**Result:** `cafe_sales_clean` – tidy fact table ready for analysis.
---

## 🔗 Joins & Item Category Table

**Created lookup table for joins:**

```sql
CREATE TABLE item_category (
    item_name   VARCHAR(50),
    category    VARCHAR(50), 
    is_hot_cold VARCHAR(50)
);

INSERT INTO item_category VALUES
('Coffee',   'Beverage', 'Hot'),
('Tea',      'Beverage', 'Hot'),
('Juice',    'Beverage', 'Cold'),
('Smoothie', 'Beverage', 'Cold'),
('Cake',     'Food',     'Neither'),
('Cookie',   'Food',     'Neither'),
('Sandwich', 'Food',     'Neither'),
('Salad',    'Food',     'Neither'),
('Unknown item', 'Unknown', 'Unknown');

Revenue by category (Food vs Beverage)
Hot vs Cold beverage performance  
Food items performance (quantity, revenue, transactions)
Category performance by location
High-value food transactions (>20)
Monthly beverage revenue
Items generating >$10,000 revenue
```
Revenue by category (Food vs Beverage)
Hot vs Cold beverage performance  
Food items performance (quantity, revenue, transactions)
Category performance by location
High-value food transactions (>20)
Monthly beverage revenue
Items generating >$10,000 revenue

📊 Key Results (Cleaned Data)
Core KPIs
- Revenue: 76,690.50
- Total transactions: 8,596  
- Average spend per transaction: ≈8.92
  
*Revenue by location*
1. Unknown location: 30,475 revenue, 3,407 transactions
2. In-store: 23,353 revenue, 2,726 transactions  
3. Takeaway: 22,862 revenue, 2,463 transactions
   
*Top 5 items by revenue*
1. Salad – 14,890.00
2. Sandwich – 11,680.00  
3. Smoothie – 11,608.00
4. Juice – 9,108.00
5. Cake – 9,009.00

📐 CTEs & Business Questions
*Month‑over‑month revenue change*
```sql
WITH monthly_rev AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m-01') AS report_month,
           SUM(total_spent) AS revenue
    FROM cafe_sales_clean 
    WHERE transaction_date IS NOT NULL
    GROUP BY report_month
)
SELECT m_current.report_month,
       m_current.revenue AS current_month_rev,
       m_previous.revenue AS prev_month_rev,
       m_current.revenue - m_previous.revenue AS revenue_diff
FROM monthly_rev m_current
LEFT JOIN monthly_rev m_previous
  ON m_current.report_month = DATE_ADD(m_previous.report_month, INTERVAL 1 MONTH)
ORDER BY m_current.report_month;
```
*Revenue share by payment method*
```sql
WITH total_rev AS (SELECT SUM(total_spent) AS grand_total FROM cafe_sales_clean),
     pay_rev AS (SELECT payment_method, SUM(total_spent) AS pay_method_rev 
                 FROM cafe_sales_clean GROUP BY payment_method)
SELECT p.payment_method, 
       ROUND(p.pay_method_rev / t.grand_total * 100, 2) AS percent_of_total
FROM pay_rev p CROSS JOIN total_rev t
ORDER BY percent_of_total DESC;
```


