-- ============================================================
-- Warehouse Reconciliation
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

-- Confirm each warehouse table reconciles to its staging source.
SELECT
    table_name,
    staging_rows,
    warehouse_rows,
    staging_rows - warehouse_rows AS row_delta,
    CASE
        WHEN staging_rows = warehouse_rows THEN 'PASS'
        ELSE 'FAIL'
    END AS reconciliation_status
FROM (
    SELECT
        'country' AS table_name,
        (SELECT COUNT(*) FROM stg_country) AS staging_rows,
        (SELECT COUNT(*) FROM dim_country) AS warehouse_rows

    UNION ALL

    SELECT
        'league',
        (SELECT COUNT(*) FROM stg_league),
        (SELECT COUNT(*) FROM dim_league)

    UNION ALL

    SELECT
        'team',
        (SELECT COUNT(*) FROM stg_team),
        (SELECT COUNT(*) FROM dim_team)

    UNION ALL

    SELECT
        'player',
        (SELECT COUNT(*) FROM stg_player),
        (SELECT COUNT(*) FROM dim_player)

    UNION ALL

    SELECT
        'match',
        (SELECT COUNT(*) FROM stg_match),
        (SELECT COUNT(*) FROM fact_match)
) AS row_reconciliation;


-- Identify staging matches that cannot be joined into the fact table.
SELECT
    check_name,
    failed_rows
FROM (
    SELECT
        'missing_dim_date' AS check_name,
        COUNT(*) AS failed_rows
    FROM stg_match AS m
    LEFT JOIN dim_date AS d
        ON d.full_date = DATE(m.`date`)
    WHERE d.date_key IS NULL

    UNION ALL

    SELECT
        'missing_dim_country',
        COUNT(*)
    FROM stg_match AS m
    LEFT JOIN dim_country AS c
        ON c.country_id = m.country_id
    WHERE c.country_key IS NULL

    UNION ALL

    SELECT
        'missing_dim_league',
        COUNT(*)
    FROM stg_match AS m
    LEFT JOIN dim_league AS l
        ON l.league_id = m.league_id
    WHERE l.league_key IS NULL

    UNION ALL

    SELECT
        'missing_home_dim_team',
        COUNT(*)
    FROM stg_match AS m
    LEFT JOIN dim_team AS t
        ON t.team_api_id = m.home_team_api_id
    WHERE t.team_key IS NULL

    UNION ALL

    SELECT
        'missing_away_dim_team',
        COUNT(*)
    FROM stg_match AS m
    LEFT JOIN dim_team AS t
        ON t.team_api_id = m.away_team_api_id
    WHERE t.team_key IS NULL
) AS load_readiness;


-- Confirm natural keys remain unique in warehouse dimensions and facts.
SELECT
    entity_name,
    duplicate_keys
FROM (
    SELECT
        'dim_country.country_id' AS entity_name,
        COUNT(*) - COUNT(DISTINCT country_id) AS duplicate_keys
    FROM dim_country

    UNION ALL

    SELECT
        'dim_league.league_id',
        COUNT(*) - COUNT(DISTINCT league_id)
    FROM dim_league

    UNION ALL

    SELECT
        'dim_team.team_api_id',
        COUNT(*) - COUNT(DISTINCT team_api_id)
    FROM dim_team

    UNION ALL

    SELECT
        'dim_player.player_api_id',
        COUNT(*) - COUNT(DISTINCT player_api_id)
    FROM dim_player

    UNION ALL

    SELECT
        'fact_match.match_api_id',
        COUNT(*) - COUNT(DISTINCT match_api_id)
    FROM fact_match
) AS uniqueness_checks;


-- Confirm derived result metrics agree with source goals.
SELECT
    COUNT(*) AS derived_metric_issues
FROM fact_match
WHERE total_goals <> home_team_goal + away_team_goal
   OR goal_difference <> home_team_goal - away_team_goal
   OR match_result <> CASE
        WHEN home_team_goal > away_team_goal THEN 'H'
        WHEN home_team_goal = away_team_goal THEN 'D'
        ELSE 'A'
    END
   OR home_team_points <> CASE
        WHEN home_team_goal > away_team_goal THEN 3
        WHEN home_team_goal = away_team_goal THEN 1
        ELSE 0
    END
   OR away_team_points <> CASE
        WHEN away_team_goal > home_team_goal THEN 3
        WHEN home_team_goal = away_team_goal THEN 1
        ELSE 0
    END
   OR is_clean_sheet_home <> CASE WHEN away_team_goal = 0 THEN 1 ELSE 0 END
   OR is_clean_sheet_away <> CASE WHEN home_team_goal = 0 THEN 1 ELSE 0 END;


-- Summarize the final warehouse coverage by league and season.
SELECT
    c.country_name,
    l.league_name,
    f.season,
    COUNT(*) AS matches_loaded,
    SUM(f.total_goals) AS goals_loaded,
    MIN(f.match_date) AS first_match_date,
    MAX(f.match_date) AS last_match_date
FROM fact_match AS f
INNER JOIN dim_country AS c
    ON c.country_key = f.country_key
INNER JOIN dim_league AS l
    ON l.league_key = f.league_key
GROUP BY
    c.country_name,
    l.league_name,
    f.season
ORDER BY
    c.country_name,
    l.league_name,
    f.season;
