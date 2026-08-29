# ⚽ European Soccer Data Engineering Platform 📊

[![Database](https://img.shields.io/badge/Database-MySQL%208.0.46-blue?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Python](https://img.shields.io/badge/Python-3.10-yellow?logo=python&logoColor=white)](https://www.python.org/)
[![Data Source](https://img.shields.io/badge/Dataset-Kaggle%20Soccer-orange?logo=kaggle&logoColor=white)](https://www.kaggle.com/datasets/hugomathien/soccer)
[![Architecture](https://img.shields.io/badge/Architecture-Star%20Schema%20Warehouse-brightgreen)](#-data-warehouse-star-schema)
[![Validation](https://img.shields.io/badge/Validation-7%2F7%20Reconciled%20(PASS)-success)](#-data-quality--reconciliation-framework)

An end-to-end **Data Engineering and Analytics Platform** that extracts multi-season European football data from a raw SQLite relational database, automates batch ETL loads into **MySQL 8.0**, enforces an idempotent staging pipeline with strict reconciliation, models a production-grade **Star-Schema Data Warehouse**, and exposes downstream analytics views and betting-market marts.

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
