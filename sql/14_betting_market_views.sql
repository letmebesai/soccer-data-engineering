-- ============================================================
-- Betting Market Analytics Views
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

CREATE OR REPLACE VIEW vw_betting_market_summary AS
SELECT
    odds_base.match_key,
    odds_base.match_api_id,
    odds_base.match_date,
    odds_base.season,
    odds_base.stage,
    odds_base.country_name,
    odds_base.league_name,
    odds_base.home_team_name,
    odds_base.away_team_name,
    odds_base.home_team_goal,
    odds_base.away_team_goal,
    odds_base.match_result,
    odds_base.match_result_label,
    odds_base.available_bookmakers,
    odds_base.avg_home_odds,
    odds_base.avg_draw_odds,
    odds_base.avg_away_odds,
    ROUND(100.0 / NULLIF(odds_base.avg_home_odds, 0), 2) AS raw_home_implied_pct,
    ROUND(100.0 / NULLIF(odds_base.avg_draw_odds, 0), 2) AS raw_draw_implied_pct,
    ROUND(100.0 / NULLIF(odds_base.avg_away_odds, 0), 2) AS raw_away_implied_pct,
    ROUND(
        (1.0 / NULLIF(odds_base.avg_home_odds, 0))
        / NULLIF(
            (1.0 / NULLIF(odds_base.avg_home_odds, 0))
            + (1.0 / NULLIF(odds_base.avg_draw_odds, 0))
            + (1.0 / NULLIF(odds_base.avg_away_odds, 0)),
            0
        ) * 100,
        2
    ) AS normalized_home_probability_pct,
    ROUND(
        (1.0 / NULLIF(odds_base.avg_draw_odds, 0))
        / NULLIF(
            (1.0 / NULLIF(odds_base.avg_home_odds, 0))
            + (1.0 / NULLIF(odds_base.avg_draw_odds, 0))
            + (1.0 / NULLIF(odds_base.avg_away_odds, 0)),
            0
        ) * 100,
        2
    ) AS normalized_draw_probability_pct,
    ROUND(
        (1.0 / NULLIF(odds_base.avg_away_odds, 0))
        / NULLIF(
            (1.0 / NULLIF(odds_base.avg_home_odds, 0))
            + (1.0 / NULLIF(odds_base.avg_draw_odds, 0))
            + (1.0 / NULLIF(odds_base.avg_away_odds, 0)),
            0
        ) * 100,
        2
    ) AS normalized_away_probability_pct,
    CASE
        WHEN odds_base.avg_home_odds IS NULL
          OR odds_base.avg_draw_odds IS NULL
          OR odds_base.avg_away_odds IS NULL THEN NULL
        WHEN odds_base.avg_home_odds <= odds_base.avg_draw_odds
         AND odds_base.avg_home_odds <= odds_base.avg_away_odds THEN 'H'
        WHEN odds_base.avg_draw_odds <= odds_base.avg_home_odds
         AND odds_base.avg_draw_odds <= odds_base.avg_away_odds THEN 'D'
        ELSE 'A'
    END AS market_favorite_result,
    CASE
        WHEN odds_base.avg_home_odds IS NULL
          OR odds_base.avg_draw_odds IS NULL
          OR odds_base.avg_away_odds IS NULL THEN NULL
        WHEN odds_base.avg_home_odds <= odds_base.avg_draw_odds
         AND odds_base.avg_home_odds <= odds_base.avg_away_odds THEN odds_base.home_team_name
        WHEN odds_base.avg_draw_odds <= odds_base.avg_home_odds
         AND odds_base.avg_draw_odds <= odds_base.avg_away_odds THEN 'Draw'
        ELSE odds_base.away_team_name
    END AS market_favorite_label
FROM (
    SELECT
        f.match_key,
        f.match_api_id,
        d.full_date AS match_date,
        f.season,
        f.stage,
        c.country_name,
        l.league_name,
        home_team.team_long_name AS home_team_name,
        away_team.team_long_name AS away_team_name,
        f.home_team_goal,
        f.away_team_goal,
        f.match_result,
        CASE f.match_result
            WHEN 'H' THEN 'Home Win'
            WHEN 'D' THEN 'Draw'
            ELSE 'Away Win'
        END AS match_result_label,
        (
            (f.b365_home_odds IS NOT NULL)
            + (f.bw_home_odds IS NOT NULL)
            + (f.iw_home_odds IS NOT NULL)
            + (f.lb_home_odds IS NOT NULL)
            + (f.ps_home_odds IS NOT NULL)
            + (f.wh_home_odds IS NOT NULL)
            + (f.sj_home_odds IS NOT NULL)
            + (f.vc_home_odds IS NOT NULL)
            + (f.gb_home_odds IS NOT NULL)
            + (f.bs_home_odds IS NOT NULL)
        ) AS available_bookmakers,
        (
            COALESCE(f.b365_home_odds, 0)
            + COALESCE(f.bw_home_odds, 0)
            + COALESCE(f.iw_home_odds, 0)
            + COALESCE(f.lb_home_odds, 0)
            + COALESCE(f.ps_home_odds, 0)
            + COALESCE(f.wh_home_odds, 0)
            + COALESCE(f.sj_home_odds, 0)
            + COALESCE(f.vc_home_odds, 0)
            + COALESCE(f.gb_home_odds, 0)
            + COALESCE(f.bs_home_odds, 0)
        ) / NULLIF(
            (f.b365_home_odds IS NOT NULL)
            + (f.bw_home_odds IS NOT NULL)
            + (f.iw_home_odds IS NOT NULL)
            + (f.lb_home_odds IS NOT NULL)
            + (f.ps_home_odds IS NOT NULL)
            + (f.wh_home_odds IS NOT NULL)
            + (f.sj_home_odds IS NOT NULL)
            + (f.vc_home_odds IS NOT NULL)
            + (f.gb_home_odds IS NOT NULL)
            + (f.bs_home_odds IS NOT NULL),
            0
        ) AS avg_home_odds,
        (
            COALESCE(f.b365_draw_odds, 0)
            + COALESCE(f.bw_draw_odds, 0)
            + COALESCE(f.iw_draw_odds, 0)
            + COALESCE(f.lb_draw_odds, 0)
            + COALESCE(f.ps_draw_odds, 0)
            + COALESCE(f.wh_draw_odds, 0)
            + COALESCE(f.sj_draw_odds, 0)
            + COALESCE(f.vc_draw_odds, 0)
            + COALESCE(f.gb_draw_odds, 0)
            + COALESCE(f.bs_draw_odds, 0)
        ) / NULLIF(
            (f.b365_draw_odds IS NOT NULL)
            + (f.bw_draw_odds IS NOT NULL)
            + (f.iw_draw_odds IS NOT NULL)
            + (f.lb_draw_odds IS NOT NULL)
            + (f.ps_draw_odds IS NOT NULL)
            + (f.wh_draw_odds IS NOT NULL)
            + (f.sj_draw_odds IS NOT NULL)
            + (f.vc_draw_odds IS NOT NULL)
            + (f.gb_draw_odds IS NOT NULL)
            + (f.bs_draw_odds IS NOT NULL),
            0
        ) AS avg_draw_odds,
        (
            COALESCE(f.b365_away_odds, 0)
            + COALESCE(f.bw_away_odds, 0)
            + COALESCE(f.iw_away_odds, 0)
            + COALESCE(f.lb_away_odds, 0)
            + COALESCE(f.ps_away_odds, 0)
            + COALESCE(f.wh_away_odds, 0)
            + COALESCE(f.sj_away_odds, 0)
            + COALESCE(f.vc_away_odds, 0)
            + COALESCE(f.gb_away_odds, 0)
            + COALESCE(f.bs_away_odds, 0)
        ) / NULLIF(
            (f.b365_away_odds IS NOT NULL)
            + (f.bw_away_odds IS NOT NULL)
            + (f.iw_away_odds IS NOT NULL)
            + (f.lb_away_odds IS NOT NULL)
            + (f.ps_away_odds IS NOT NULL)
            + (f.wh_away_odds IS NOT NULL)
            + (f.sj_away_odds IS NOT NULL)
            + (f.vc_away_odds IS NOT NULL)
            + (f.gb_away_odds IS NOT NULL)
            + (f.bs_away_odds IS NOT NULL),
            0
        ) AS avg_away_odds
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
        ON away_team.team_key = f.away_team_key
) AS odds_base;


CREATE OR REPLACE VIEW vw_betting_favorite_results AS
SELECT
    market_summary.*,
    CASE
        WHEN market_favorite_result IS NULL THEN 'NO_MARKET'
        WHEN market_favorite_result = match_result THEN 'FAVORITE_WON'
        WHEN match_result = 'D' THEN 'FAVORITE_DREW'
        ELSE 'FAVORITE_LOST'
    END AS favorite_outcome
FROM vw_betting_market_summary AS market_summary;


CREATE OR REPLACE VIEW vw_league_betting_accuracy AS
SELECT
    country_name,
    league_name,
    season,
    COUNT(*) AS matches_with_market,
    SUM(CASE WHEN favorite_outcome = 'FAVORITE_WON' THEN 1 ELSE 0 END) AS favorite_wins,
    SUM(CASE WHEN favorite_outcome = 'FAVORITE_DREW' THEN 1 ELSE 0 END) AS favorite_draws,
    SUM(CASE WHEN favorite_outcome = 'FAVORITE_LOST' THEN 1 ELSE 0 END) AS favorite_losses,
    ROUND(
        SUM(CASE WHEN favorite_outcome = 'FAVORITE_WON' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS favorite_win_pct,
    ROUND(AVG(available_bookmakers), 2) AS avg_bookmakers_available
FROM vw_betting_favorite_results
WHERE favorite_outcome <> 'NO_MARKET'
GROUP BY
    country_name,
    league_name,
    season;
