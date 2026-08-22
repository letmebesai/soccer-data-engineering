-- ============================================================
-- Warehouse Dimension Load
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

-- Reload dimensions from a clean warehouse state.
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE fact_match;
TRUNCATE TABLE dim_league;
TRUNCATE TABLE dim_country;
TRUNCATE TABLE dim_team;
TRUNCATE TABLE dim_player;
TRUNCATE TABLE dim_date;

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO dim_country (
    country_id,
    country_name
)
SELECT
    id AS country_id,
    name AS country_name
FROM stg_country;

INSERT INTO dim_league (
    league_id,
    country_key,
    country_id,
    league_name
)
SELECT
    l.id AS league_id,
    c.country_key,
    l.country_id,
    l.name AS league_name
FROM stg_league AS l
INNER JOIN dim_country AS c
    ON c.country_id = l.country_id;

INSERT INTO dim_team (
    team_api_id,
    team_fifa_api_id,
    team_long_name,
    team_short_name
)
SELECT
    team_api_id,
    CAST(team_fifa_api_id AS UNSIGNED) AS team_fifa_api_id,
    team_long_name,
    team_short_name
FROM stg_team;

INSERT INTO dim_player (
    player_api_id,
    player_fifa_api_id,
    player_name,
    birthday,
    height_cm,
    weight_lbs
)
SELECT
    player_api_id,
    CAST(player_fifa_api_id AS UNSIGNED) AS player_fifa_api_id,
    player_name,
    DATE(birthday) AS birthday,
    CAST(height AS DECIMAL(5,2)) AS height_cm,
    CAST(weight AS UNSIGNED) AS weight_lbs
FROM stg_player;

INSERT INTO dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_name,
    day_of_week,
    week_of_year,
    is_weekend,
    soccer_season
)
SELECT
    CAST(DATE_FORMAT(calendar_date, '%Y%m%d') AS UNSIGNED) AS date_key,
    calendar_date AS full_date,
    YEAR(calendar_date) AS year,
    QUARTER(calendar_date) AS quarter,
    MONTH(calendar_date) AS month,
    DATE_FORMAT(calendar_date, '%M') AS month_name,
    DAY(calendar_date) AS day,
    DAYNAME(calendar_date) AS day_name,
    DAYOFWEEK(calendar_date) AS day_of_week,
    WEEK(calendar_date, 3) AS week_of_year,
    CASE WHEN DAYOFWEEK(calendar_date) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    CASE
        WHEN MONTH(calendar_date) >= 7
            THEN CONCAT(YEAR(calendar_date), '/', YEAR(calendar_date) + 1)
        ELSE CONCAT(YEAR(calendar_date) - 1, '/', YEAR(calendar_date))
    END AS soccer_season
FROM (
    SELECT
        DATE_ADD(
            bounds.min_match_date,
            INTERVAL (
                ones.n
                + tens.n * 10
                + hundreds.n * 100
                + thousands.n * 1000
            ) DAY
        ) AS calendar_date,
        bounds.max_match_date
    FROM (
        SELECT
            MIN(DATE(`date`)) AS min_match_date,
            MAX(DATE(`date`)) AS max_match_date
        FROM stg_match
    ) AS bounds
    CROSS JOIN (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) AS ones
    CROSS JOIN (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) AS tens
    CROSS JOIN (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) AS hundreds
    CROSS JOIN (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) AS thousands
) AS generated_dates
WHERE calendar_date <= max_match_date;

SELECT 'dim_country' AS table_name, COUNT(*) AS rows_loaded
FROM dim_country

UNION ALL

SELECT 'dim_league', COUNT(*)
FROM dim_league

UNION ALL

SELECT 'dim_team', COUNT(*)
FROM dim_team

UNION ALL

SELECT 'dim_player', COUNT(*)
FROM dim_player

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM dim_date;
