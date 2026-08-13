DROP TABLE IF EXISTS stg_country;
DROP TABLE IF EXISTS stg_league;
DROP TABLE IF EXISTS stg_team;
DROP TABLE IF EXISTS stg_player;
DROP TABLE IF EXISTS stg_match;
DROP TABLE IF EXISTS stg_player_attributes;
DROP TABLE IF EXISTS stg_team_attributes;

CREATE TABLE stg_country LIKE country;
CREATE TABLE stg_league LIKE league;
CREATE TABLE stg_team LIKE team;
CREATE TABLE stg_player LIKE player;
CREATE TABLE stg_match LIKE `match`;
CREATE TABLE stg_player_attributes LIKE player_attributes;
CREATE TABLE stg_team_attributes LIKE team_attributes;