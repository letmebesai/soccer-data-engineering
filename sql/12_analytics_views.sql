-- ============================================================
-- Analytics Views
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

CREATE OR REPLACE VIEW vw_match_results AS
SELECT
    f.match_key,
    f.match_api_id,
    f.source_match_id,
    d.full_date AS match_date,
    f.match_date AS match_datetime,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.week_of_year,
    f.season,
    f.stage,
    c.country_name,
    l.league_name,
    home_team.team_key AS home_team_key,
    home_team.team_api_id AS home_team_api_id,
    home_team.team_long_name AS home_team_name,
    away_team.team_key AS away_team_key,
    away_team.team_api_id AS away_team_api_id,
    away_team.team_long_name AS away_team_name,
    f.home_team_goal,
    f.away_team_goal,
    f.total_goals,
    f.goal_difference,
    f.match_result,
    CASE f.match_result
        WHEN 'H' THEN 'Home Win'
        WHEN 'D' THEN 'Draw'
        ELSE 'Away Win'
    END AS match_result_label,
    f.home_team_points,
    f.away_team_points,
    f.is_clean_sheet_home,
    f.is_clean_sheet_away,
    f.b365_home_odds,
    f.b365_draw_odds,
    f.b365_away_odds,
    f.wh_home_odds,
    f.wh_draw_odds,
    f.wh_away_odds
FROM fact_match AS f
INNER JOIN dim_date AS d
    ON d.date_key = f.date_key
INNER JOIN dim_country AS c
    ON c.country_key = f.country_key
INNER JOIN dim_league AS l
    ON l.league_key = f.league_key
INNER JOIN dim_team AS home_team
    ON home_team.team_key = f.home_team_key
INNER JOIN dim_team AS away_team
    ON away_team.team_key = f.away_team_key;


CREATE OR REPLACE VIEW vw_team_match_results AS
SELECT
    match_key,
    match_api_id,
    match_date,
    match_datetime,
    year,
    quarter,
    month,
    month_name,
    season,
    stage,
    country_name,
    league_name,
    home_team_key AS team_key,
    home_team_api_id AS team_api_id,
    home_team_name AS team_name,
    away_team_key AS opponent_team_key,
    away_team_api_id AS opponent_team_api_id,
    away_team_name AS opponent_team_name,
    'HOME' AS venue,
    home_team_goal AS goals_for,
    away_team_goal AS goals_against,
    home_team_goal - away_team_goal AS goal_difference,
    CASE
        WHEN match_result = 'H' THEN 'WIN'
        WHEN match_result = 'D' THEN 'DRAW'
        ELSE 'LOSS'
    END AS result,
    home_team_points AS points,
    is_clean_sheet_home AS clean_sheet
FROM vw_match_results

UNION ALL

SELECT
    match_key,
    match_api_id,
    match_date,
    match_datetime,
    year,
    quarter,
    month,
    month_name,
    season,
    stage,
    country_name,
    league_name,
    away_team_key AS team_key,
    away_team_api_id AS team_api_id,
    away_team_name AS team_name,
    home_team_key AS opponent_team_key,
    home_team_api_id AS opponent_team_api_id,
    home_team_name AS opponent_team_name,
    'AWAY' AS venue,
    away_team_goal AS goals_for,
    home_team_goal AS goals_against,
    away_team_goal - home_team_goal AS goal_difference,
    CASE
        WHEN match_result = 'A' THEN 'WIN'
        WHEN match_result = 'D' THEN 'DRAW'
        ELSE 'LOSS'
    END AS result,
    away_team_points AS points,
    is_clean_sheet_away AS clean_sheet
FROM vw_match_results;


CREATE OR REPLACE VIEW vw_team_season_standings AS
SELECT
    ROW_NUMBER() OVER (
        PARTITION BY season_summary.country_name, season_summary.league_name, season_summary.season
        ORDER BY
            season_summary.points DESC,
            season_summary.goal_difference DESC,
            season_summary.goals_for DESC,
            season_summary.wins DESC,
            season_summary.team_name ASC
    ) AS league_position,
    season_summary.country_name,
    season_summary.league_name,
    season_summary.season,
    season_summary.team_key,
    season_summary.team_api_id,
    season_summary.team_name,
    season_summary.matches_played,
    season_summary.wins,
    season_summary.draws,
    season_summary.losses,
    season_summary.goals_for,
    season_summary.goals_against,
    season_summary.goal_difference,
    season_summary.points,
    season_summary.home_matches,
    season_summary.away_matches,
    season_summary.clean_sheets
FROM (
    SELECT
        country_name,
        league_name,
        season,
        team_key,
        team_api_id,
        team_name,
        COUNT(*) AS matches_played,
        SUM(CASE WHEN result = 'WIN' THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN result = 'DRAW' THEN 1 ELSE 0 END) AS draws,
        SUM(CASE WHEN result = 'LOSS' THEN 1 ELSE 0 END) AS losses,
        SUM(goals_for) AS goals_for,
        SUM(goals_against) AS goals_against,
        SUM(goal_difference) AS goal_difference,
        SUM(points) AS points,
        SUM(CASE WHEN venue = 'HOME' THEN 1 ELSE 0 END) AS home_matches,
        SUM(CASE WHEN venue = 'AWAY' THEN 1 ELSE 0 END) AS away_matches,
        SUM(clean_sheet) AS clean_sheets
    FROM vw_team_match_results
    GROUP BY
        country_name,
        league_name,
        season,
        team_key,
        team_api_id,
        team_name
) AS season_summary;


CREATE OR REPLACE VIEW vw_league_season_summary AS
SELECT
    country_name,
    league_name,
    season,
    COUNT(*) AS matches_played,
    SUM(total_goals) AS total_goals,
    ROUND(AVG(total_goals), 2) AS avg_goals_per_match,
    SUM(CASE WHEN match_result = 'H' THEN 1 ELSE 0 END) AS home_wins,
    SUM(CASE WHEN match_result = 'D' THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN match_result = 'A' THEN 1 ELSE 0 END) AS away_wins,
    ROUND(SUM(CASE WHEN match_result = 'H' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS home_win_pct,
    ROUND(SUM(CASE WHEN match_result = 'D' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS draw_pct,
    ROUND(SUM(CASE WHEN match_result = 'A' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS away_win_pct,
    MIN(match_date) AS first_match_date,
    MAX(match_date) AS last_match_date
FROM vw_match_results
GROUP BY
    country_name,
    league_name,
    season;
