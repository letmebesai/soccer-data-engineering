-- ============================================================
-- Staging Data Load
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

-- Clear previous staging data before a full refresh
TRUNCATE TABLE stg_country;
TRUNCATE TABLE stg_league;
TRUNCATE TABLE stg_team;
TRUNCATE TABLE stg_player;

-- Reload from raw tables
INSERT INTO stg_country
SELECT *
FROM country;

INSERT INTO stg_league
SELECT *
FROM league;

INSERT INTO stg_team
SELECT *
FROM team;

INSERT INTO stg_player
SELECT *
FROM player;