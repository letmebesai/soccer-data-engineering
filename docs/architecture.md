# Architecture

## End-to-End Pipeline

```text
European Soccer SQLite Database
              |
              v
        Python Ingestion
              |
              v
        MySQL Raw Layer
              |
              v
         Staging Layer
              |
              v
       Data Quality Checks
              |
              v
    Dimensional Data Warehouse
              |
              v
       Analytics / Marts