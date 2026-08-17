-- ============================================================
-- Warehouse Schema Validation
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

-- Verify warehouse tables exist
SELECT
    TABLE_NAME,
    ENGINE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'soccer_dw'
  AND TABLE_NAME IN (
      'dim_country',
      'dim_league',
      'dim_team',
      'dim_player',
      'dim_date',
      'fact_match'
  )
ORDER BY TABLE_NAME;


-- Verify primary keys and foreign keys
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'soccer_dw'
  AND TABLE_NAME IN (
      'dim_country',
      'dim_league',
      'dim_team',
      'dim_player',
      'dim_date',
      'fact_match'
  )
ORDER BY TABLE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME;


-- Verify fact-table indexes
SELECT
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'soccer_dw'
  AND TABLE_NAME = 'fact_match'
ORDER BY INDEX_NAME, SEQ_IN_INDEX;