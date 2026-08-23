-- ============================================================
-- Attribute Analytics Marts
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

CREATE OR REPLACE VIEW vw_player_attribute_snapshots AS
SELECT
    p.player_key,
    p.player_api_id,
    p.player_fifa_api_id,
    p.player_name,
    p.birthday,
    p.height_cm,
    p.weight_lbs,
    DATE(pa.`date`) AS attribute_date,
    pa.overall_rating,
    pa.potential,
    pa.preferred_foot,
    pa.attacking_work_rate,
    pa.defensive_work_rate,
    pa.crossing,
    pa.finishing,
    pa.heading_accuracy,
    pa.short_passing,
    pa.volleys,
    pa.dribbling,
    pa.curve,
    pa.free_kick_accuracy,
    pa.long_passing,
    pa.ball_control,
    pa.acceleration,
    pa.sprint_speed,
    pa.agility,
    pa.reactions,
    pa.balance,
    pa.shot_power,
    pa.jumping,
    pa.stamina,
    pa.strength,
    pa.long_shots,
    pa.aggression,
    pa.interceptions,
    pa.positioning,
    pa.vision,
    pa.penalties,
    pa.marking,
    pa.standing_tackle,
    pa.sliding_tackle,
    pa.gk_diving,
    pa.gk_handling,
    pa.gk_kicking,
    pa.gk_positioning,
    pa.gk_reflexes,
    ROUND((
        pa.crossing
        + pa.finishing
        + pa.heading_accuracy
        + pa.short_passing
        + pa.volleys
        + pa.dribbling
        + pa.curve
        + pa.free_kick_accuracy
        + pa.long_passing
        + pa.ball_control
    ) / 10.0, 2) AS attacking_skill_score,
    ROUND((
        pa.acceleration
        + pa.sprint_speed
        + pa.agility
        + pa.reactions
        + pa.balance
    ) / 5.0, 2) AS movement_skill_score,
    ROUND((
        pa.marking
        + pa.standing_tackle
        + pa.sliding_tackle
        + pa.interceptions
    ) / 4.0, 2) AS defending_skill_score,
    ROUND((
        pa.gk_diving
        + pa.gk_handling
        + pa.gk_kicking
        + pa.gk_positioning
        + pa.gk_reflexes
    ) / 5.0, 2) AS goalkeeping_skill_score
FROM stg_player_attributes AS pa
INNER JOIN dim_player AS p
    ON p.player_api_id = pa.player_api_id;


CREATE OR REPLACE VIEW vw_latest_player_attributes AS
SELECT
    ranked_players.*
FROM (
    SELECT
        player_snapshots.*,
        ROW_NUMBER() OVER (
            PARTITION BY player_snapshots.player_api_id
            ORDER BY player_snapshots.attribute_date DESC
        ) AS snapshot_rank
    FROM vw_player_attribute_snapshots AS player_snapshots
) AS ranked_players
WHERE snapshot_rank = 1;


CREATE OR REPLACE VIEW vw_team_attribute_snapshots AS
SELECT
    t.team_key,
    t.team_api_id,
    t.team_fifa_api_id,
    t.team_long_name,
    t.team_short_name,
    DATE(ta.`date`) AS attribute_date,
    ta.buildUpPlaySpeed,
    ta.buildUpPlaySpeedClass,
    ta.buildUpPlayDribbling,
    ta.buildUpPlayDribblingClass,
    ta.buildUpPlayPassing,
    ta.buildUpPlayPassingClass,
    ta.buildUpPlayPositioningClass,
    ta.chanceCreationPassing,
    ta.chanceCreationPassingClass,
    ta.chanceCreationCrossing,
    ta.chanceCreationCrossingClass,
    ta.chanceCreationShooting,
    ta.chanceCreationShootingClass,
    ta.chanceCreationPositioningClass,
    ta.defencePressure,
    ta.defencePressureClass,
    ta.defenceAggression,
    ta.defenceAggressionClass,
    ta.defenceTeamWidth,
    ta.defenceTeamWidthClass,
    ta.defenceDefenderLineClass,
    ROUND((
        ta.buildUpPlaySpeed
        + ta.buildUpPlayPassing
        + COALESCE(ta.buildUpPlayDribbling, ta.buildUpPlayPassing)
    ) / 3.0, 2) AS buildup_score,
    ROUND((
        ta.chanceCreationPassing
        + ta.chanceCreationCrossing
        + ta.chanceCreationShooting
    ) / 3.0, 2) AS chance_creation_score,
    ROUND((
        ta.defencePressure
        + ta.defenceAggression
        + ta.defenceTeamWidth
    ) / 3.0, 2) AS defensive_shape_score
FROM stg_team_attributes AS ta
INNER JOIN dim_team AS t
    ON t.team_api_id = ta.team_api_id;


CREATE OR REPLACE VIEW vw_latest_team_attributes AS
SELECT
    ranked_teams.*
FROM (
    SELECT
        team_snapshots.*,
        ROW_NUMBER() OVER (
            PARTITION BY team_snapshots.team_api_id
            ORDER BY team_snapshots.attribute_date DESC
        ) AS snapshot_rank
    FROM vw_team_attribute_snapshots AS team_snapshots
) AS ranked_teams
WHERE snapshot_rank = 1;
