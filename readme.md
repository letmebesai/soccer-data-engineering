# ⚽ European Soccer Data Engineering Platform 📊

[![Database](https://img.shields.io/badge/Database-MySQL%208.0.46-blue?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Python](https://img.shields.io/badge/Python-3.10-yellow?logo=python&logoColor=white)](https://www.python.org/)
[![Data Source](https://img.shields.io/badge/Dataset-Kaggle%20Soccer-orange?logo=kaggle&logoColor=white)](https://www.kaggle.com/datasets/hugomathien/soccer)
[![Architecture](https://img.shields.io/badge/Architecture-Star%20Schema%20Warehouse-brightgreen)](#-data-warehouse-star-schema)
[![Validation](https://img.shields.io/badge/Validation-7%2F7%20Reconciled%20(PASS)-success)](#-data-quality--reconciliation-framework)

An end-to-end **Data Engineering and Analytics Platform** that extracts multi-season European football data from a raw SQLite relational database, automates batch ETL loads into **MySQL 8.0**, enforces an idempotent staging pipeline with strict reconciliation, models a production-grade **Star-Schema Data Warehouse**, and exposes downstream analytics views and betting-market marts[cite: 1].

---

## 📌 Architecture Overview

```mermaid
flowchart TD
    A[("📂 SQLite Source<br/>(European Soccer DB)")] -->|Python 3.10 ETL<br/>pandas / SQLAlchemy / PyMySQL| B[("🗄️ MySQL Raw Layer<br/>(soccer_dw)")]
    B -->|TRUNCATE + Full-Refresh Load| C[("⚙️ Staging Layer<br/>(stg_tables)")]
    C -->|Reconciliation Checks<br/>PASS/FAIL Validation| D{"🧪 Data Quality Gate"}
    D -->|Passed| E[("⭐ Dimensional Warehouse<br/>(Star Schema)")]
    E --> F["📅 dim_date"]
    E --> G["🌍 dim_country & dim_league"]
    E --> H["👥 dim_team & dim_player"]
    E --> I["🎯 fact_match (Surrogate Keys & Derived Measures)"]
    I --> J["📈 Analytics Views (Match-level)"]
    I --> K["🏷️ Attribute Marts (Team / Player FIFA Ratings)"]
    I --> L["🎲 Betting-Market Views (Bookmaker Odds)"]
```[cite: 1]

---

## 🚀 Key Features

* **Automated Python Batch Ingestion**: Dynamic table discovery and chunk-based data migration from SQLite to MySQL[cite: 1].
* **Idempotent Full-Refresh Staging**: Isolated raw landing zone from downstream transformation layers using a truncate-before-load strategy[cite: 1].
* **Automated Data Quality & Reconciliation**: 7-table row-count and integrity audits converting source-vs-staging validation into clear operational `PASS`/`FAIL` metrics[cite: 1].
* **Dimensional Modeling (Star Schema)**: Decoupled source keys using surrogate warehouse keys (`_key`), conformed dimensions, and role-playing dimensions for home and away teams[cite: 1].
* **Analytical Measures & Sports Betting Marts**: Derived metrics for match outcomes, points, goal difference, clean sheets, and multi-bookmaker odds analysis[cite: 1].

---

## 📊 Dataset & Schema Breakdown

Sourced from Hugo Mathien's **European Soccer Database** containing 25k+ matches, 10k+ players, and 11 European countries across the 2008–2016 seasons[cite: 1]:

| Source Table | Rows | Columns | Description / Warehouse Role |
| :--- | :--- | :--- | :--- |
| `Country` | 11 | 2 | Geographic master records[cite: 1] |
| `League` | 11 | 3 | League entities mapped to countries[cite: 1] |
| `Team` | 299 | 5 | Team master data and API identifiers[cite: 1] |
| `Team_Attributes` | 1,458 | 25 | Historical time-varying team tactical ratings[cite: 1] |
| `Player` | 11,060 | 7 | Player biographies, height, weight, and birth dates[cite: 1] |
| `Player_Attributes` | 183,978 | 42 | Granular FIFA skill and attribute time-series[cite: 1] |
| `Match` | 25,979 | 115 | Matches, lineups, pitch coordinates, event XML, and betting odds[cite: 1] |

---

## 🏗️ Data Warehouse Star Schema

The analytical warehouse (`soccer_dw`) is designed for fast dimensional slice-and-dice aggregations[cite: 1]:

* **`dim_country`**: `country_key` (PK), `country_id` (Natural Key), `name`[cite: 1].
* **`dim_league`**: `league_key` (PK), `league_id` (Natural Key), `country_key` (FK), `name`[cite: 1].
* **`dim_team`**: `team_key` (PK), `team_api_id` (Business Key), `team_long_name`, `team_short_name`[cite: 1].
* **`dim_player`**: `player_key` (PK), `player_api_id` (Business Key), cleaned birthdate, height, weight[cite: 1].
* **`dim_date`**: `date_key` (PK, `YYYYMMDD`), `full_date`, calendar mappings[cite: 1].
* **`fact_match`** (Central Fact Grain: 1 row per individual soccer match)[cite: 1]:
  * **Surrogate FKs**: `date_key`, `country_key`, `league_key`, `home_team_key` *(Role-Playing FK)*, `away_team_key` *(Role-Playing FK)*[cite: 1].
  * **Derived Measures**: `total_goals`, `goal_difference`, `match_result` (`H`/`D`/`A`), `home_team_points`, `away_team_points`, `is_clean_sheet_home`, `is_clean_sheet_away`[cite: 1].
  * **Market & Tactical Feeds**: Multi-bookmaker odds (B365, BW, IW, LB, etc.) and raw XML feeds for events/possession[cite: 1].

---

## 📂 Repository Structure

```text
├── python/
│   └── etl_sqlite_to_mysql.py      # Automated SQLite extraction and chunked MySQL loading
├── sql/
│   ├── 01_database_exploration.sql # Schema discovery and metadata inspection
│   ├── 02_data_quality_audit.sql   # Raw layer row-counts and null audits
│   ├── 03_staging.sql              # Staging DDL definitions
│   ├── 04_staging_load.sql         # Idempotent TRUNCATE + INSERT staging ETL
│   ├── 05_staging_validation.sql   # Source-vs-Staging PASS/FAIL reconciliation
│   ├── 06_warehouse_design.sql     # Warehouse structure prototyping
│   ├── 07_warehouse_schema.sql     # Star-schema DDL and surrogate keys
│   ├── 08_warehouse_validation.sql # INFORMATION_SCHEMA constraint checks
│   ├── 09_warehouse_load.sql       # Conformed dimension pipeline
│   ├── 10_fact_match_load.sql      # Central fact table ETL with key mappings
│   ├── 11_warehouse_reconciliation.sql # Warehouse integrity checks
│   ├── 12_analytics_views.sql      # Core match performance and league views
│   ├── 13_attribute_marts.sql      # Player and team FIFA rating marts
│   ├── 14_betting_market_views.sql # Bookmaker margin & betting performance views
│   └── 15_analytics_validation.sql # Analytics consumption layer tests
├── docs/
│   ├── architecture.md             # End-to-end platform design
│   └── data_dictionary.md          # Warehouse table definitions and keys
├── .gitignore                      # Excludes raw .sqlite, .csv, and credentials
└── README.md
```[cite: 1]

---

## ⚙️ Setup & Execution

### 1. Prerequisites 💻
* Python 3.10+ installed[cite: 1]
* MySQL 8.0 Server running locally on port `3306`[cite: 1]
* Kaggle European Soccer SQLite database file (`database.sqlite`)[cite: 1]

### 2. Environment Variables 🔐
Set the connection variables in your environment to avoid hardcoding secrets:
```bash
export MYSQL_HOST="127.0.0.1"
export MYSQL_PORT="3306"
export MYSQL_USER="root"
export MYSQL_PASSWORD="your_secure_password"
export MYSQL_DATABASE="soccer_dw"
```[cite: 1]

### 3. Run ETL & Build Pipeline 🔄
```bash
# Clone the repository
git clone [https://github.com/letmebesai/soccer-data-engineering.git](https://github.com/letmebesai/soccer-data-engineering.git)
cd soccer-data-engineering

# Install Python dependencies
pip install pandas sqlalchemy pymysql

# Run raw data extraction and loading
python python/etl_sqlite_to_mysql.py
```[cite: 1]

Execute the SQL scripts sequentially (`01` through `15`) in your SQL client (e.g., MySQL Workbench or Antigravity) to build the staging, warehouse, and analytics layers[cite: 1].

---

## 🛠️ Engineering Challenges & Troubleshooting

* **Wide Table Memory/Transaction Bottlenecks**: Loading the 115-column `Match` table using `method="multi"` and large chunk sizes triggered `PendingRollbackError`[cite: 1]. Resolved by optimizing chunk size to `1000` rows and using standard parameterized inserts[cite: 1].
* **Pipeline Idempotency & Duplicate Loads**: Re-running ingestion initially resulted in duplicate staging counts (e.g., `Country` doubled to 22 rows)[cite: 1]. Solved by implementing an explicit `TRUNCATE TABLE` step before loading[cite: 1].
* **Connection String Encoding**: Special characters in credentials caused parsing failures (`@localhost`), resolved by URL-encoding passwords using `urllib.parse.quote_plus`[cite: 1].

---

## 📜 Disclaimer & Licensing

This project is built for educational and portfolio demonstration purposes[cite: 1]. Data is sourced from Hugo Mathien's Kaggle European Soccer Database[cite: 1]. Please verify Kaggle and original data provider terms prior to any commercial application[cite: 1].
