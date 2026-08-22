-- ============================================================
-- Warehouse Design & Schema Inspection
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

-- Inspect all staging table columns
SELECT
    TABLE_NAME,
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'soccer_dw'
  AND TABLE_NAME IN (
      'stg_country',
      'stg_league',
      'stg_team',
      'stg_player',
      'stg_match',
      'stg_player_attributes',
      'stg_team_attributes'
  )
ORDER BY
    TABLE_NAME,
    ORDINAL_POSITION;

SELECT
    TABLE_NAME,
    GROUP_CONCAT(
        CONCAT(
            COLUMN_NAME,
            ' (',
            DATA_TYPE,
            ')'
        )
        ORDER BY ORDINAL_POSITION
        SEPARATOR ', '
    ) AS columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'soccer_dw'
  AND TABLE_NAME IN (
      'stg_country',
      'stg_league',
      'stg_match',
      'stg_player',
      'stg_player_attributes',
      'stg_team',
      'stg_team_attributes'
  )
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

SELECT
    TABLE_NAME,
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'soccer_dw'
  AND TABLE_NAME = 'stg_match'
ORDER BY ORDINAL_POSITION;