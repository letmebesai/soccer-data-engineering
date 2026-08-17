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