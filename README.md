# Hospital Management Data  


**End-to-end data analyst portfolio project** · Excel · MySQL · Power BI

> Analyzing 200 clinic appointments across 50 patients, 10 doctors, and 3 hospital branches to uncover revenue gaps, no-show patterns, and treatment cost distribution.

---

## Dashboard preview

> *Screenshot: add your exported Power BI dashboard image here*
> `![Dashboard Preview](assets/dashboard_preview.png)`

---

## Project overview

| Detail | Value |
|---|---|
| Dataset | 5 CSV files (synthetic clinic data) |
| Records | 200 appointments · 200 billing records · 200 treatments |
| Patients | 50 unique patients |
| Doctors | 10 doctors across 3 specializations |
| Branches | Central Hospital · Eastside Clinic · Westside Clinic |
| Time period | January 2023 – November 2023 |

### Business questions answered

1. How much revenue was collected vs outstanding vs failed — and why does it matter?
2. Which specialization and hospital branch generates the most revenue?
3. Which doctors have the highest no-show rates, and is there a pattern?
4. What are the most common and most expensive treatment types?
5. What does the patient demographic breakdown look like?

---

## Key findings

- **Total revenue: $551,249** — only 31.5% ($173K) was successfully collected
- **35% of all bills failed** ($193K) — the single biggest revenue risk in the dataset
- **Pediatrics dominates revenue** at $258.9K (47% of total), followed by Dermatology at $202.7K
- **26% no-show rate** (52 of 200 appointments) — L. Wilson (Oncology) had the highest at 36.4%
- **Chemotherapy** was the most frequent treatment (49 cases); **MRI** had the highest average cost at $3,225 per treatment
- **Central Hospital** leads all branches at $229K in revenue

---

## Tools & skills used

| Tool | Usage |
|---|---|
| Microsoft Excel | Data cleaning — removing quoted commas from amount/cost columns, fixing date formats, adding helper columns |
| MySQL 8.0 | Database creation, table design with foreign keys, analytical queries |
| Power BI Desktop | Data modeling, DAX measures, dashboard design |
| GitHub | Version control and portfolio publishing |

### SQL concepts demonstrated

- `CREATE TABLE` with primary keys and foreign keys
- `JOIN` across 5 tables (INNER JOIN, LEFT JOIN)
- Aggregate functions: `SUM`, `COUNT`, `AVG`, `ROUND`
- Conditional aggregation with `CASE WHEN`
- Window functions: `RANK() OVER`, `LAG()`, `PERCENT_RANK()`, `SUM() OVER`
- Subqueries and CTEs
- `CREATE VIEW` for a flat master reporting table
- Data quality checks for orphaned records and NULL values

### DAX measures written

- `Total Revenue`, `Revenue Collected`, `Revenue Outstanding`, `Revenue Failed`
- `Collection Rate %` using `DIVIDE()`
- `Total Appointments`, `No-Show Count`, `No-Show Rate %`, `Completion Rate %`
- `Revenue MoM %` using `DATEADD` for month-over-month change
- Date intelligence with a custom `CALENDAR()` table

---

## Repository structure

```
clinic-operations-analytics/
│
├── data/
│   ├── patients_clean.csv
│   ├── doctors.csv
│   ├── appointments.csv
│   ├── treatments.csv
│   └── billing.csv
│
├── sql/
│   └── clinic_analytics.sql        ← full script: CREATE, import notes, EDA,
│                                      analysis queries, window functions, view
│
├── assets/
│   └── dashboard_preview.png       ← exported Power BI screenshot (add yours)
│
├── clinic_analytics.pbix           ← Power BI file (add after building)
└── README.md
```

---

## How to run this project

### 1. Set up MySQL

```sql
-- Run the full SQL script in MySQL Workbench
SOURCE sql/clinic_analytics.sql;
```

Requirements: MySQL 8.0+, MySQL Workbench (or any SQL client)

### 2. Import the data

Clean the CSV files in Excel first:

**billing.csv** — the `amount` column contains quoted commas (e.g. `" 3,941.97 "`).  
Apply this formula in a new column, then replace the original:

```excel
=VALUE(TRIM(SUBSTITUTE(E2,",","")))
```

**treatments.csv** — same fix for the `cost` column.

Then import CSVs into MySQL using Table Data Import Wizard or:

```sql
LOAD DATA INFILE '/your/path/billing.csv'
INTO TABLE billing
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

Import order (required for foreign keys): `patients` → `doctors` → `appointments` → `treatments` → `billing`

### 3. Connect Power BI to MySQL

1. Open Power BI Desktop → Get Data → MySQL Database
2. Server: `localhost` · Database: `clinic_analytics`
3. Load all 5 tables + `vw_clinic_master` view
4. In Power Query Editor, verify `amount` and `cost` columns are **Decimal Number** type

### 4. Build the data model

Create these relationships in Model view:

| From | To | Cardinality |
|---|---|---|
| `patients.patient_id` | `appointments.patient_id` | 1 to many |
| `doctors.doctor_id` | `appointments.doctor_id` | 1 to many |
| `appointments.appointment_id` | `treatments.appointment_id` | 1 to 1 |
| `treatments.treatment_id` | `billing.treatment_id` | 1 to 1 |

Add a Date table for time intelligence:

```dax
Date = CALENDAR(
    MIN(appointments[appointment_date]),
    MAX(appointments[appointment_date])
)
```

### 5. Create DAX measures

```dax
Total Revenue = SUM(billing[amount])

Revenue Collected =
CALCULATE(SUM(billing[amount]), billing[payment_status] = "Paid")

Collection Rate % =
DIVIDE([Revenue Collected], [Total Revenue], 0) * 100

No-Show Rate % =
DIVIDE(
    CALCULATE(COUNTROWS(appointments), appointments[status] = "No-show"),
    COUNTROWS(appointments), 0
) * 100
```

---

## Dashboard layout

**Single-page design** · Segoe UI · Background `#F5F4F0` · Two accent colors (blue + semantic green/amber/red)

| Section | Visual | Chart type |
|---|---|---|
| Top row | Total Revenue · Collected · Outstanding · Failed · No-show Rate | 5 KPI cards |
| Middle left | Revenue by payment method and status | 100% stacked bar |
| Middle center | Revenue by specialization · Revenue by branch | Horizontal bar (x2) |
| Middle right | Treatment type cost breakdown | Legend list (donut data) |
| Bottom left | Appointment status distribution · Patient demographics | Stacked bar + summary |
| Bottom center | Doctor no-show ranking | Table with conditional formatting |
| Bottom right | Slicers | Tile slicers × 4 |

**Chart title conventions used:**

- `Revenue by payment method & status`
- `Revenue by specialization`
- `By hospital branch`
- `Treatment type breakdown`
- `Appointment status distribution`
- `Patient age & insurance`
- `Doctor no-show ranking`

**Slicer fields:** Payment method · Hospital branch · Appointment status · Insurance provider

---

## Data model diagram

```
patients ──────┐
               ├──► appointments ──► treatments ──► billing
doctors ───────┘
```

---

## About this project

This project was built as part of a data analyst portfolio to demonstrate end-to-end skills across the full analytics workflow: raw data → cleaning → database design → SQL analysis → business intelligence dashboard.

The dataset is synthetic and was designed to reflect realistic clinic operations scenarios including payment failures, appointment no-shows, and multi-branch revenue distribution.

---

*Built by Clark · Data Analyst Portfolio · 2024*
