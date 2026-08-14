-- ============================================================
-- Staging Validation
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

SELECT
    table_name,
    source_rows,
    staging_rows,
    CASE
        WHEN source_rows = staging_rows THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM (
    SELECT
        'country' AS table_name,
        (SELECT COUNT(*) FROM country) AS source_rows,
        (SELECT COUNT(*) FROM stg_country) AS staging_rows

    UNION ALL

    SELECT
        'league',
        (SELECT COUNT(*) FROM league),
        (SELECT COUNT(*) FROM stg_league)

    UNION ALL

    SELECT
        'team',
        (SELECT COUNT(*) FROM team),
        (SELECT COUNT(*) FROM stg_team)

    UNION ALL

    SELECT
        'player',
        (SELECT COUNT(*) FROM player),
        (SELECT COUNT(*) FROM stg_player)

    UNION ALL

    SELECT
        'match',
        (SELECT COUNT(*) FROM `match`),
        (SELECT COUNT(*) FROM stg_match)

    UNION ALL

    SELECT
        'player_attributes',
        (SELECT COUNT(*) FROM player_attributes),
        (SELECT COUNT(*) FROM stg_player_attributes)

    UNION ALL

    SELECT
        'team_attributes',
        (SELECT COUNT(*) FROM team_attributes),
        (SELECT COUNT(*) FROM stg_team_attributes)
) AS validation;