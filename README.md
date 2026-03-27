# ☕ Cafe Sales – SQL Data Cleaning, Joins, and Analysis

<p align="left">
  <img src="https://img.shields.io/badge/MySQL-100%25-blue?style=for-the-badge&logo=mysql&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dataset-Kaggle-20BEFF?style=for-the-badge&logo=kaggle&logoColor=white"/>
  <img src="https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge"/>
</p>

This project is an end‑to‑end example of taking a **dirty cafe sales dataset** from Kaggle, cleaning it with **MySQL**, and then analysing it using **joins, CTEs, and basic window‑style logic**.  
The goal is to show that I can work with messy real‑world data, turn it into a clean table, and answer business questions using SQL.

---

## 📂 Dataset

- **Source:** [Kaggle – Cafe Sales – Dirty Data for Cleaning Training](https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training/data)
- **Period:** 2023 (Jan – Dec)
- **Rows:** ~10,000
- **Columns:** 8

| Column | Description |
|---|---|
| Transaction ID | Unique transaction identifier |
| Item | Product sold (Coffee, Tea, Juice, etc.) |
| Quantity | Number of units purchased |
| Price Per Unit | Unit price in USD |
| Total Spent | Total transaction value |
| Payment Method | Cash / Credit Card / Digital Wallet |
| Location | In-store / Takeaway |
| Transaction Date | Date of transaction (YYYY-MM-DD) |

**The raw data contains:**
- Missing values (blank cells)
- `UNKNOWN` / `ERROR` strings used in place of NULLs
- Inconsistent text (different spellings/casing)
- Incorrect or missing numeric totals

---

## 📁 Repository Files

| File | Description |
|---|---|
| `dirty_cafe_sales.xlsx` | Raw dataset as downloaded from Kaggle (messy) |
| `clean_cafe_sales.xlsx` | Cleaned output dataset exported after SQL processing |
| `01_create_clean_table.sql` | Full data cleaning script |
| `02_analysis_queries.sql` | Business analysis queries |
| `README.md` | Project documentation |

---

## 🏗️ Database Objects

| Object | Type | Description |
|---|---|---|
| `dirty_cafe_sales` | Table | Original raw data imported from CSV |
| `c_cafe_view` | View | Staging view — standardises text and converts dirty values to NULL |
| `cafe_sales_clean` | Table | Final cleaned fact table ready for analysis |
| `item_category` | Table | Lookup/dimension table mapping each item to category and temperature type |

---

## 📁 Project Structure

```text
sql-cafe-sales-cleaning/
├── dirty_cafe_sales.xlsx          ← Raw dataset (Kaggle source)
├── clean_cafe_sales.xlsx          ← Cleaned output dataset
├── 01_create_clean_table.sql
│   ├── Profiling raw data
│   ├── Creating staging view (c_cafe_view)
│   ├── Building cafe_sales_clean
│   ├── Creating item_category lookup
│   └── Core cleaning, joins, CTE utilities
├── 02_analysis_queries.sql
│   ├── KPI queries
│   ├── Revenue breakdowns
│   ├── Monthly trend
│   └── CTE business questions
└── README.md
```

---

## 🧹 Data Cleaning Steps

### 1. Profiling the Raw Data
- Used `DESCRIBE` and `COUNT(*)` to understand shape (~9k rows after import)
- Wrote `SUM(CASE WHEN ...)` checks to count NULLs, empty strings, `UNKNOWN`, and `ERROR` per column
- Used `SELECT DISTINCT` to inspect `Item`, `Payment Method`, `Location`, `Transaction Date`
- Checked duplicate `Transaction ID` with `GROUP BY ... HAVING COUNT(*) > 1`

### 2. Staging View (`c_cafe_view`)
- Applied `TRIM()` to remove extra whitespace from all text columns
- Converted dirty values (`''`, `UNKNOWN`, `ERROR`) → `NULL` for:
  - Item, Quantity, Price Per Unit, Total Spent, Payment Method, Location, Transaction Date
- Retained raw versions as separate columns (`item_raw`, `quantity_raw`, `price_raw`, etc.)

### 3. Building the Clean Table (`cafe_sales_clean`)
`CREATE TABLE cafe_sales_clean AS SELECT` from `c_cafe_view` with:
- `transaction_id` – from `transaction_id_raw`
- `item` – `COALESCE(item_raw, 'Unknown item')`
- `quantity_num` – `CAST(quantity_raw AS UNSIGNED)`
- `price_per_unit_num` – `CAST(price_raw AS DECIMAL(10,2))`
- `total_spent_num` – `CAST(total_raw AS DECIMAL(10,2))`
- `payment_method` – `COALESCE(payment_raw, 'Unspecified')`
- `location` – `COALESCE(location_raw, 'Unknown location')`
- `transaction_date_raw` – cleaned text version of date

### 4. Recomputing Numeric Values
Ensured `Quantity × Price Per Unit = Total Spent` consistency:
- If `total_spent` is NULL but `quantity` and `price_per_unit` exist → recompute total
- If `price_per_unit` is NULL but `total_spent` and `quantity` exist → recompute price
- If `quantity` is NULL but `total_spent` and `price_per_unit` exist → recompute quantity

### 5. Normalising Categories
- **Payment method:** `LOWER()` + `CASE` → `Cash`, `Credit Card`, `Digital Wallet`, `Unspecified`
- **Location:** Invalid/missing values → `'Unknown location'`

### 6. Handling Dates
- Input dates in `YYYY-MM-DD` format
- Used `CAST(... AS DATE)` → `transaction_date` column
- Kept rows with `NULL` dates; filtered them out only for time-series analysis

### 7. Final Column Renaming
- `quantity_num` → `quantity`
- `price_per_unit_num` → `price_per_unit`
- `total_spent_num` → `total_spent`

**Result:** `cafe_sales_clean` — a tidy fact table with 8,596 valid transactions ready for analysis.

---

## 🔗 Joins & Item Category Table

Created a small lookup table to enable category-level analysis via `JOIN`:

```sql
CREATE TABLE item_category (
    item_name   VARCHAR(50),
    category    VARCHAR(50),
    is_hot_cold VARCHAR(50)
);

INSERT INTO item_category VALUES
('Coffee',       'Beverage', 'Hot'),
('Tea',          'Beverage', 'Hot'),
('Juice',        'Beverage', 'Cold'),
('Smoothie',     'Beverage', 'Cold'),
('Cake',         'Food',     'Neither'),
('Cookie',       'Food',     'Neither'),
('Sandwich',     'Food',     'Neither'),
('Salad',        'Food',     'Neither'),
('Unknown item', 'Unknown',  'Unknown');
```

**Join-powered analysis includes:**
- Revenue by category (Food vs Beverage)
- Hot vs Cold beverage performance
- Food items performance (quantity, revenue, transactions)
- Category performance by location
- High-value food transactions (> $20)
- Monthly beverage revenue
- Items generating > $10,000 total revenue

---

## 📊 Key Results

### Core KPIs
| Metric | Value |
|---|---|
| Total Revenue | $76,690.50 |
| Total Transactions | 8,596 |
| Average Spend per Transaction | ~$8.92 |

### Revenue by Location
| Rank | Location | Revenue | Transactions |
|---|---|---|---|
| 1 | Unknown location | $30,475 | 3,407 |
| 2 | In-store | $23,353 | 2,726 |
| 3 | Takeaway | $22,862 | 2,463 |

### Top 5 Items by Revenue
| Rank | Item | Revenue |
|---|---|---|
| 1 | Salad | $14,890.00 |
| 2 | Sandwich | $11,680.00 |
| 3 | Smoothie | $11,608.00 |
| 4 | Juice | $9,108.00 |
| 5 | Cake | $9,009.00 |

---

## 📐 CTEs & Business Questions

### Month-over-Month Revenue Change
```sql
WITH monthly_rev AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m-01') AS report_month,
           SUM(total_spent) AS revenue
    FROM cafe_sales_clean
    WHERE transaction_date IS NOT NULL
    GROUP BY report_month
)
SELECT m_current.report_month,
       m_current.revenue                              AS current_month_rev,
       m_previous.revenue                             AS prev_month_rev,
       m_current.revenue - m_previous.revenue         AS revenue_diff
FROM monthly_rev m_current
LEFT JOIN monthly_rev m_previous
    ON m_current.report_month = DATE_ADD(m_previous.report_month, INTERVAL 1 MONTH)
ORDER BY m_current.report_month;
```

### Revenue Share by Payment Method
```sql
WITH total_rev AS (
    SELECT SUM(total_spent) AS grand_total FROM cafe_sales_clean
),
pay_rev AS (
    SELECT payment_method, SUM(total_spent) AS pay_method_rev
    FROM cafe_sales_clean
    GROUP BY payment_method
)
SELECT p.payment_method,
       ROUND(p.pay_method_rev / t.grand_total * 100, 2) AS percent_of_total
FROM pay_rev p
CROSS JOIN total_rev t
ORDER BY percent_of_total DESC;
```

---

## 🛠️ Tools Used

- **MySQL 8.0** — all cleaning and analysis
- **MySQL Workbench** — query development and schema design
- **Excel / XLSX** — raw data source and cleaned data export

---

## ▶️ How to Run

1. Import `dirty_cafe_sales.xlsx` into MySQL (use Table Data Import Wizard in Workbench)
2. Run `01_create_clean_table.sql` — creates the staging view, clean table, and lookup table
3. Run `02_analysis_queries.sql` — executes all business KPI and CTE queries
4. Optionally inspect `clean_cafe_sales.xlsx` to compare raw vs cleaned output
