USE soccer_dw;

SELECT COUNT(*) AS country_rows
FROM country;

SELECT COUNT(*) AS league_rows
FROM league;

SELECT COUNT(*) AS player_rows
FROM player;

SELECT COUNT(*) AS player_attribute_rows
FROM player_attributes;

SELECT COUNT(*) AS match_rows
FROM `match`;

SELECT COUNT(*) AS team_rows
FROM team;

SELECT COUNT(*) AS team_attribute_rows
FROM team_attributes;