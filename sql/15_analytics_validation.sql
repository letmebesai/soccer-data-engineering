-- ============================================================
-- Analytics Validation
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

-- Confirm all expected analytics views exist.
SELECT
    expected_views.view_name,
    CASE
        WHEN actual_views.TABLE_NAME IS NULL THEN 'MISSING'
        ELSE 'PASS'
    END AS view_status
FROM (
    SELECT 'vw_match_results' AS view_name
    UNION ALL SELECT 'vw_team_match_results'
    UNION ALL SELECT 'vw_team_season_standings'
    UNION ALL SELECT 'vw_league_season_summary'
    UNION ALL SELECT 'vw_player_attribute_snapshots'
    UNION ALL SELECT 'vw_latest_player_attributes'
    UNION ALL SELECT 'vw_team_attribute_snapshots'
    UNION ALL SELECT 'vw_latest_team_attributes'
    UNION ALL SELECT 'vw_betting_market_summary'
    UNION ALL SELECT 'vw_betting_favorite_results'
    UNION ALL SELECT 'vw_league_betting_accuracy'
) AS expected_views
LEFT JOIN INFORMATION_SCHEMA.TABLES AS actual_views
    ON actual_views.TABLE_SCHEMA = DATABASE()
   AND actual_views.TABLE_TYPE = 'VIEW'
   AND actual_views.TABLE_NAME = expected_views.view_name
ORDER BY expected_views.view_name;


-- Reconcile core view row counts to warehouse tables.
SELECT
    check_name,
    expected_rows,
    actual_rows,
    actual_rows - expected_rows AS row_delta,
    CASE
        WHEN expected_rows = actual_rows THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM (
    SELECT
        'match_results_equals_fact_match' AS check_name,
        (SELECT COUNT(*) FROM fact_match) AS expected_rows,
        (SELECT COUNT(*) FROM vw_match_results) AS actual_rows

    UNION ALL

    SELECT
        'team_match_results_two_rows_per_match',
        (SELECT COUNT(*) * 2 FROM fact_match),
        (SELECT COUNT(*) FROM vw_team_match_results)

    UNION ALL

    SELECT
        'league_summary_one_row_per_league_season',
        (
            SELECT COUNT(*)
            FROM (
                SELECT league_key, season
                FROM fact_match
                GROUP BY league_key, season
            ) AS league_seasons
        ),
        (SELECT COUNT(*) FROM vw_league_season_summary)

    UNION ALL

    SELECT
        'standings_one_row_per_team_league_season',
        (
            SELECT COUNT(*)
            FROM (
                SELECT country_name, league_name, season, team_api_id
                FROM vw_team_match_results
                GROUP BY country_name, league_name, season, team_api_id
            ) AS team_seasons
        ),
        (SELECT COUNT(*) FROM vw_team_season_standings)
) AS row_count_checks;


-- Validate latest attribute views remain unique by natural key.
SELECT
    check_name,
    duplicate_rows,
    CASE
        WHEN duplicate_rows = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM (
    SELECT
        'latest_player_attributes_unique' AS check_name,
        COUNT(*) AS duplicate_rows
    FROM (
        SELECT player_api_id
        FROM vw_latest_player_attributes
        GROUP BY player_api_id
        HAVING COUNT(*) > 1
    ) AS duplicate_players

    UNION ALL

    SELECT
        'latest_team_attributes_unique',
        COUNT(*)
    FROM (
        SELECT team_api_id
        FROM vw_latest_team_attributes
        GROUP BY team_api_id
        HAVING COUNT(*) > 1
    ) AS duplicate_teams
) AS uniqueness_checks;


-- Validate standings values remain within logical soccer bounds.
SELECT
    COUNT(*) AS standings_metric_issues
FROM vw_team_season_standings
WHERE matches_played <> wins + draws + losses
   OR points <> wins * 3 + draws
   OR goal_difference <> goals_for - goals_against
   OR home_matches + away_matches <> matches_played
   OR clean_sheets > matches_played;


-- Validate normalized probabilities sum to approximately 100 percent.
SELECT
    COUNT(*) AS betting_probability_issues
FROM vw_betting_market_summary
WHERE normalized_home_probability_pct IS NOT NULL
  AND normalized_draw_probability_pct IS NOT NULL
  AND normalized_away_probability_pct IS NOT NULL
  AND ABS(
        normalized_home_probability_pct
        + normalized_draw_probability_pct
        + normalized_away_probability_pct
        - 100
    ) > 0.05;


-- Validate favorite labels are populated whenever full odds are available.
SELECT
    COUNT(*) AS betting_favorite_label_issues
FROM vw_betting_market_summary
WHERE avg_home_odds IS NOT NULL
  AND avg_draw_odds IS NOT NULL
  AND avg_away_odds IS NOT NULL
  AND market_favorite_result IS NULL;


-- Provide a compact QA dashboard for the analyst layer.
SELECT
    'fact_matches' AS metric_name,
    COUNT(*) AS metric_value
FROM fact_match

UNION ALL

SELECT
    'team_match_rows',
    COUNT(*)
FROM vw_team_match_results

UNION ALL

SELECT
    'team_season_standing_rows',
    COUNT(*)
FROM vw_team_season_standings

UNION ALL

SELECT
    'player_attribute_snapshots',
    COUNT(*)
FROM vw_player_attribute_snapshots

UNION ALL

SELECT
    'team_attribute_snapshots',
    COUNT(*)
FROM vw_team_attribute_snapshots

UNION ALL

SELECT
    'betting_market_rows',
    COUNT(*)
FROM vw_betting_market_summary;
