-- ============================================================
-- European Soccer Data Engineering Project
-- Script 07: Dimensional Warehouse Schema (DDL)
-- Target Database: soccer_dw
--
-- Description:
-- Creates the production dimensional star-schema data warehouse
-- consisting of five conformed dimension tables and one central
-- fact table.
--
-- Warehouse Architecture:
-- 1. dim_country  : Country dimension (Grain: 1 row per country)
-- 2. dim_league   : League dimension (Grain: 1 row per league)
-- 3. dim_team     : Team dimension (Grain: 1 row per team)
-- 4. dim_player   : Player dimension (Grain: 1 row per player)
-- 5. dim_date     : Calendar date dimension (Grain: 1 row per calendar day)
-- 6. fact_match   : Match fact table (Grain: 1 row per individual soccer match)
-- ============================================================

USE soccer_dw;

-- ============================================================
-- Step 1: Safely Drop Existing Warehouse Tables in Dependency Order
-- ============================================================

-- Disable foreign key checks during teardown to avoid dependency locking
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS fact_match;
DROP TABLE IF EXISTS dim_league;
DROP TABLE IF EXISTS dim_country;
DROP TABLE IF EXISTS dim_team;
DROP TABLE IF EXISTS dim_player;
DROP TABLE IF EXISTS dim_date;

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- Step 2: Create Dimension Tables
-- ============================================================

-- ------------------------------------------------------------
-- Dimension: dim_country
-- Source Table: stg_country
-- Grain: One row per Country (11 countries in European Soccer DB)
-- Description: Stores standardized geographic country details.
-- ------------------------------------------------------------
CREATE TABLE dim_country (
    country_key         INT AUTO_INCREMENT NOT NULL,
    country_id          INT NOT NULL,                  -- Natural / Source key (stg_country.id)
    country_name        VARCHAR(100) NOT NULL,         -- Source: stg_country.name
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_dim_country PRIMARY KEY (country_key),
    CONSTRAINT uq_dim_country_id UNIQUE (country_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Country dimension: Grain is one row per country';


-- ------------------------------------------------------------
-- Dimension: dim_league
-- Source Table: stg_league
-- Grain: One row per Soccer League (11 leagues)
-- Description: Stores European league hierarchies and names.
-- ------------------------------------------------------------
CREATE TABLE dim_league (
    league_key          INT AUTO_INCREMENT NOT NULL,
    league_id           INT NOT NULL,                  -- Natural / Source key (stg_league.id)
    country_key         INT NOT NULL,                  -- Foreign Key to dim_country.country_key
    country_id          INT NOT NULL,                  -- Source reference (stg_league.country_id)
    league_name         VARCHAR(150) NOT NULL,         -- Source: stg_league.name
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_dim_league PRIMARY KEY (league_key),
    CONSTRAINT uq_dim_league_id UNIQUE (league_id),
    CONSTRAINT fk_dim_league_country FOREIGN KEY (country_key)
        REFERENCES dim_country (country_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='League dimension: Grain is one row per soccer league';

CREATE INDEX idx_dim_league_country ON dim_league (country_key);


-- ------------------------------------------------------------
-- Dimension: dim_team
-- Source Table: stg_team
-- Grain: One row per Soccer Team (299 teams)
-- Description: Stores team profiles, API identifiers, and names.
-- ------------------------------------------------------------
CREATE TABLE dim_team (
    team_key            INT AUTO_INCREMENT NOT NULL,
    team_api_id         INT NOT NULL,                  -- Natural / Business Key used in match records (stg_team.team_api_id)
    team_fifa_api_id    INT NULL,                      -- FIFA ID (stg_team.team_fifa_api_id)
    team_long_name      VARCHAR(150) NOT NULL,         -- Source: stg_team.team_long_name
    team_short_name     VARCHAR(10) NULL,              -- Source: stg_team.team_short_name
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_dim_team PRIMARY KEY (team_key),
    CONSTRAINT uq_dim_team_api_id UNIQUE (team_api_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Team dimension: Grain is one row per soccer club/team';

CREATE INDEX idx_dim_team_long_name ON dim_team (team_long_name);
CREATE INDEX idx_dim_team_fifa_id ON dim_team (team_fifa_api_id);


-- ------------------------------------------------------------
-- Dimension: dim_player
-- Source Table: stg_player
-- Grain: One row per Soccer Player (11,060 players)
-- Description: Stores player biographical data, names, birthdays,
--              height, and weight.
-- Transformations:
--   - birthday (TEXT 'YYYY-MM-DD HH:MM:SS') -> birthday (DATE)
--   - height (DOUBLE) -> height_cm (DECIMAL(5,2))
--   - weight (BIGINT lbs) -> weight_lbs (INT)
-- ------------------------------------------------------------
CREATE TABLE dim_player (
    player_key          INT AUTO_INCREMENT NOT NULL,
    player_api_id       INT NOT NULL,                  -- Natural / Business Key (stg_player.player_api_id)
    player_fifa_api_id  INT NULL,                      -- FIFA Player ID (stg_player.player_fifa_api_id)
    player_name         VARCHAR(150) NOT NULL,         -- Source: stg_player.player_name
    birthday            DATE NULL,                     -- Converted from stg_player.birthday
    height_cm           DECIMAL(5,2) NULL,             -- Player height in cm (stg_player.height)
    weight_lbs          INT NULL,                      -- Player weight in lbs (stg_player.weight)
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_dim_player PRIMARY KEY (player_key),
    CONSTRAINT uq_dim_player_api_id UNIQUE (player_api_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Player dimension: Grain is one row per player';

CREATE INDEX idx_dim_player_name ON dim_player (player_name);
CREATE INDEX idx_dim_player_fifa_id ON dim_player (player_fifa_api_id);
CREATE INDEX idx_dim_player_birthday ON dim_player (birthday);


-- ------------------------------------------------------------
-- Dimension: dim_date
-- Source: Generated conformed calendar date dimension
-- Grain: One row per calendar day
-- Description: Supports time-series analytics, match scheduling,
--              seasonality, and rolling performance analysis.
-- ------------------------------------------------------------
CREATE TABLE dim_date (
    date_key            INT NOT NULL,                  -- Integer surrogate key in YYYYMMDD format (e.g. 20080817)
    full_date           DATE NOT NULL,                 -- Full calendar date
    year                SMALLINT NOT NULL,             -- e.g. 2008
    quarter             TINYINT NOT NULL,              -- 1, 2, 3, 4
    month               TINYINT NOT NULL,              -- 1 to 12
    month_name          VARCHAR(15) NOT NULL,          -- 'January', 'August', etc.
    day                 TINYINT NOT NULL,              -- Day of month (1 to 31)
    day_name            VARCHAR(15) NOT NULL,          -- 'Monday', 'Saturday', etc.
    day_of_week         TINYINT NOT NULL,              -- 1 (Sunday) to 7 (Saturday) or ISO 1 (Monday) to 7 (Sunday)
    week_of_year        TINYINT NOT NULL,              -- 1 to 53
    is_weekend          TINYINT(1) NOT NULL,           -- 1 = Weekend (Saturday/Sunday), 0 = Weekday
    soccer_season       VARCHAR(10) NULL,              -- European soccer season (e.g. '2008/2009')

    CONSTRAINT pk_dim_date PRIMARY KEY (date_key),
    CONSTRAINT uq_dim_date_full_date UNIQUE (full_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Date dimension: Grain is one row per calendar day';

CREATE INDEX idx_dim_date_year_month ON dim_date (year, month);
CREATE INDEX idx_dim_date_soccer_season ON dim_date (soccer_season);


-- ============================================================
-- Step 3: Create Central Fact Table
-- ============================================================

-- ------------------------------------------------------------
-- Fact Table: fact_match
-- Source Table: stg_match (25,979 matches)
-- Grain: One row per individual soccer match
-- Description: Central fact table storing match outcomes, goals,
--              derived performance points, clean sheets, starting
--              lineups, pitch tactical coordinates, betting market
--              odds (10 bookmakers), and detailed XML match feeds.
-- ------------------------------------------------------------
CREATE TABLE fact_match (
    -- Surrogate & Source Keys
    match_key               INT AUTO_INCREMENT NOT NULL,
    match_api_id            INT NOT NULL,                  -- Natural business key (stg_match.match_api_id)
    source_match_id         INT NOT NULL,                  -- Source row identifier (stg_match.id)

    -- Conformed Dimension Foreign Keys
    date_key                INT NOT NULL,                  -- FK -> dim_date.date_key (YYYYMMDD)
    country_key             INT NOT NULL,                  -- FK -> dim_country.country_key
    league_key              INT NOT NULL,                  -- FK -> dim_league.league_key
    home_team_key           INT NOT NULL,                  -- FK -> dim_team.team_key (home team)
    away_team_key           INT NOT NULL,                  -- FK -> dim_team.team_key (away team)

    -- Degenerate Dimensions & Source Business Attributes
    country_id              INT NOT NULL,                  -- Source country identifier (stg_match.country_id)
    league_id               INT NOT NULL,                  -- Source league identifier (stg_match.league_id)
    home_team_api_id        INT NOT NULL,                  -- Source home team API ID (stg_match.home_team_api_id)
    away_team_api_id        INT NOT NULL,                  -- Source away team API ID (stg_match.away_team_api_id)
    match_date              DATETIME NOT NULL,             -- Match timestamp (stg_match.date)
    season                  VARCHAR(10) NOT NULL,          -- Season label (e.g. '2008/2009', stg_match.season)
    stage                   SMALLINT NOT NULL,             -- Competition round/stage (1-38, stg_match.stage)

    -- Core Match Measures & Derived Metrics
    home_team_goal          SMALLINT NOT NULL,             -- Goals scored by home team (stg_match.home_team_goal)
    away_team_goal          SMALLINT NOT NULL,             -- Goals scored by away team (stg_match.away_team_goal)
    total_goals             SMALLINT NOT NULL,             -- Derived: home_team_goal + away_team_goal
    goal_difference         SMALLINT NOT NULL,             -- Derived: home_team_goal - away_team_goal
    match_result            ENUM('H', 'D', 'A') NOT NULL,  -- Derived: H = Home Win, D = Draw, A = Away Win
    home_team_points        TINYINT NOT NULL,              -- Derived: 3 (Win), 1 (Draw), 0 (Loss)
    away_team_points        TINYINT NOT NULL,              -- Derived: 3 (Win), 1 (Draw), 0 (Loss)
    is_clean_sheet_home     TINYINT(1) NOT NULL,           -- Derived: 1 if away_team_goal = 0, else 0
    is_clean_sheet_away     TINYINT(1) NOT NULL,           -- Derived: 1 if home_team_goal = 0, else 0

    -- Starting Lineup Player References (Preserved as Nullable Source API IDs without 22 FK constraints)
    home_player_1           INT NULL,                      -- stg_match.home_player_1 (Goalkeeper)
    home_player_2           INT NULL,                      -- stg_match.home_player_2
    home_player_3           INT NULL,                      -- stg_match.home_player_3
    home_player_4           INT NULL,                      -- stg_match.home_player_4
    home_player_5           INT NULL,                      -- stg_match.home_player_5
    home_player_6           INT NULL,                      -- stg_match.home_player_6
    home_player_7           INT NULL,                      -- stg_match.home_player_7
    home_player_8           INT NULL,                      -- stg_match.home_player_8
    home_player_9           INT NULL,                      -- stg_match.home_player_9
    home_player_10          INT NULL,                      -- stg_match.home_player_10
    home_player_11          INT NULL,                      -- stg_match.home_player_11

    away_player_1           INT NULL,                      -- stg_match.away_player_1 (Goalkeeper)
    away_player_2           INT NULL,                      -- stg_match.away_player_2
    away_player_3           INT NULL,                      -- stg_match.away_player_3
    away_player_4           INT NULL,                      -- stg_match.away_player_4
    away_player_5           INT NULL,                      -- stg_match.away_player_5
    away_player_6           INT NULL,                      -- stg_match.away_player_6
    away_player_7           INT NULL,                      -- stg_match.away_player_7
    away_player_8           INT NULL,                      -- stg_match.away_player_8
    away_player_9           INT NULL,                      -- stg_match.away_player_9
    away_player_10          INT NULL,                      -- stg_match.away_player_10
    away_player_11          INT NULL,                      -- stg_match.away_player_11

    -- Pitch Tactical Coordinates: X-coordinates (Horizontal pitch positions)
    home_player_X1          SMALLINT NULL,                 -- stg_match.home_player_X1
    home_player_X2          SMALLINT NULL,                 -- stg_match.home_player_X2
    home_player_X3          SMALLINT NULL,                 -- stg_match.home_player_X3
    home_player_X4          SMALLINT NULL,                 -- stg_match.home_player_X4
    home_player_X5          SMALLINT NULL,                 -- stg_match.home_player_X5
    home_player_X6          SMALLINT NULL,                 -- stg_match.home_player_X6
    home_player_X7          SMALLINT NULL,                 -- stg_match.home_player_X7
    home_player_X8          SMALLINT NULL,                 -- stg_match.home_player_X8
    home_player_X9          SMALLINT NULL,                 -- stg_match.home_player_X9
    home_player_X10         SMALLINT NULL,                 -- stg_match.home_player_X10
    home_player_X11         SMALLINT NULL,                 -- stg_match.home_player_X11

    away_player_X1          SMALLINT NULL,                 -- stg_match.away_player_X1
    away_player_X2          SMALLINT NULL,                 -- stg_match.away_player_X2
    away_player_X3          SMALLINT NULL,                 -- stg_match.away_player_X3
    away_player_X4          SMALLINT NULL,                 -- stg_match.away_player_X4
    away_player_X5          SMALLINT NULL,                 -- stg_match.away_player_X5
    away_player_X6          SMALLINT NULL,                 -- stg_match.away_player_X6
    away_player_X7          SMALLINT NULL,                 -- stg_match.away_player_X7
    away_player_X8          SMALLINT NULL,                 -- stg_match.away_player_X8
    away_player_X9          SMALLINT NULL,                 -- stg_match.away_player_X9
    away_player_X10         SMALLINT NULL,                 -- stg_match.away_player_X10
    away_player_X11         SMALLINT NULL,                 -- stg_match.away_player_X11

    -- Pitch Tactical Coordinates: Y-coordinates (Vertical pitch positions)
    home_player_Y1          SMALLINT NULL,                 -- stg_match.home_player_Y1
    home_player_Y2          SMALLINT NULL,                 -- stg_match.home_player_Y2
    home_player_Y3          SMALLINT NULL,                 -- stg_match.home_player_Y3
    home_player_Y4          SMALLINT NULL,                 -- stg_match.home_player_Y4
    home_player_Y5          SMALLINT NULL,                 -- stg_match.home_player_Y5
    home_player_Y6          SMALLINT NULL,                 -- stg_match.home_player_Y6
    home_player_Y7          SMALLINT NULL,                 -- stg_match.home_player_Y7
    home_player_Y8          SMALLINT NULL,                 -- stg_match.home_player_Y8
    home_player_Y9          SMALLINT NULL,                 -- stg_match.home_player_Y9
    home_player_Y10         SMALLINT NULL,                 -- stg_match.home_player_Y10
    home_player_Y11         SMALLINT NULL,                 -- stg_match.home_player_Y11

    away_player_Y1          SMALLINT NULL,                 -- stg_match.away_player_Y1
    away_player_Y2          SMALLINT NULL,                 -- stg_match.away_player_Y2
    away_player_Y3          SMALLINT NULL,                 -- stg_match.away_player_Y3
    away_player_Y4          SMALLINT NULL,                 -- stg_match.away_player_Y4
    away_player_Y5          SMALLINT NULL,                 -- stg_match.away_player_Y5
    away_player_Y6          SMALLINT NULL,                 -- stg_match.away_player_Y6
    away_player_Y7          SMALLINT NULL,                 -- stg_match.away_player_Y7
    away_player_Y8          SMALLINT NULL,                 -- stg_match.away_player_Y8
    away_player_Y9          SMALLINT NULL,                 -- stg_match.away_player_Y9
    away_player_Y10         SMALLINT NULL,                 -- stg_match.away_player_Y10
    away_player_Y11         SMALLINT NULL,                 -- stg_match.away_player_Y11

    -- Betting Odds: Bet365 (B365)
    b365_home_odds          DECIMAL(6,2) NULL,             -- stg_match.B365H
    b365_draw_odds          DECIMAL(6,2) NULL,             -- stg_match.B365D
    b365_away_odds          DECIMAL(6,2) NULL,             -- stg_match.B365A

    -- Betting Odds: Bet&Win / Bwin (BW)
    bw_home_odds            DECIMAL(6,2) NULL,             -- stg_match.BWH
    bw_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.BWD
    bw_away_odds            DECIMAL(6,2) NULL,             -- stg_match.BWA

    -- Betting Odds: Interwetten (IW)
    iw_home_odds            DECIMAL(6,2) NULL,             -- stg_match.IWH
    iw_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.IWD
    iw_away_odds            DECIMAL(6,2) NULL,             -- stg_match.IWA

    -- Betting Odds: Ladbrokes (LB)
    lb_home_odds            DECIMAL(6,2) NULL,             -- stg_match.LBH
    lb_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.LBD
    lb_away_odds            DECIMAL(6,2) NULL,             -- stg_match.LBA

    -- Betting Odds: Pinnacle Sports (PS)
    ps_home_odds            DECIMAL(6,2) NULL,             -- stg_match.PSH
    ps_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.PSD
    ps_away_odds            DECIMAL(6,2) NULL,             -- stg_match.PSA

    -- Betting Odds: William Hill (WH)
    wh_home_odds            DECIMAL(6,2) NULL,             -- stg_match.WHH
    wh_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.WHD
    wh_away_odds            DECIMAL(6,2) NULL,             -- stg_match.WHA

    -- Betting Odds: Stan James / Sportingbet (SJ)
    sj_home_odds            DECIMAL(6,2) NULL,             -- stg_match.SJH
    sj_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.SJD
    sj_away_odds            DECIMAL(6,2) NULL,             -- stg_match.SJA

    -- Betting Odds: VC Bet / BetVictor (VC)
    vc_home_odds            DECIMAL(6,2) NULL,             -- stg_match.VCH
    vc_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.VCD
    vc_away_odds            DECIMAL(6,2) NULL,             -- stg_match.VCA

    -- Betting Odds: Gamebookers (GB)
    gb_home_odds            DECIMAL(6,2) NULL,             -- stg_match.GBH
    gb_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.GBD
    gb_away_odds            DECIMAL(6,2) NULL,             -- stg_match.GBA

    -- Betting Odds: Blue Square (BS)
    bs_home_odds            DECIMAL(6,2) NULL,             -- stg_match.BSH
    bs_draw_odds            DECIMAL(6,2) NULL,             -- stg_match.BSD
    bs_away_odds            DECIMAL(6,2) NULL,             -- stg_match.BSA

    -- Detailed XML Feeds (Preserved as LONGTEXT)
    goal_xml                LONGTEXT NULL,                 -- stg_match.goal
    shoton_xml              LONGTEXT NULL,                 -- stg_match.shoton
    shotoff_xml             LONGTEXT NULL,                 -- stg_match.shotoff
    foulcommit_xml          LONGTEXT NULL,                 -- stg_match.foulcommit
    card_xml                LONGTEXT NULL,                 -- stg_match.card
    cross_xml               LONGTEXT NULL,                 -- stg_match.cross
    corner_xml              LONGTEXT NULL,                 -- stg_match.corner
    possession_xml          LONGTEXT NULL,                 -- stg_match.possession

    -- Audit Metadata
    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT pk_fact_match PRIMARY KEY (match_key),
    CONSTRAINT uq_fact_match_api_id UNIQUE (match_api_id),

    CONSTRAINT fk_fact_match_date FOREIGN KEY (date_key)
        REFERENCES dim_date (date_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fact_match_country FOREIGN KEY (country_key)
        REFERENCES dim_country (country_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fact_match_league FOREIGN KEY (league_key)
        REFERENCES dim_league (league_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fact_match_home_team FOREIGN KEY (home_team_key)
        REFERENCES dim_team (team_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fact_match_away_team FOREIGN KEY (away_team_key)
        REFERENCES dim_team (team_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Central match fact table: Grain is one row per soccer match';

-- ============================================================
-- Step 4: Add Supporting Performance Indexes for Fact Table
-- ============================================================

CREATE INDEX idx_fact_match_date_key ON fact_match (date_key);
CREATE INDEX idx_fact_match_league_season ON fact_match (league_key, season);
CREATE INDEX idx_fact_match_home_team ON fact_match (home_team_key);
CREATE INDEX idx_fact_match_away_team ON fact_match (away_team_key);
CREATE INDEX idx_fact_match_season_stage ON fact_match (season, stage);
CREATE INDEX idx_fact_match_result ON fact_match (match_result);
CREATE INDEX idx_fact_match_date ON fact_match (match_date);
