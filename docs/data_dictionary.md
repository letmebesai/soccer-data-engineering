# Data Dictionary

## Warehouse Tables

### dim_country

**Grain:** One row per country.

| Column | Description |
|---|---|
| `country_key` | Surrogate warehouse key. |
| `country_id` | Source/natural country identifier. |
| `country_name` | Country name. |
| `created_at` | Warehouse record creation timestamp. |

### dim_league

**Grain:** One row per soccer league.

| Column | Description |
|---|---|
| `league_key` | Surrogate warehouse key. |
| `league_id` | Source/natural league identifier. |
| `country_key` | Foreign key to `dim_country`. |
| `country_id` | Source country identifier. |
| `league_name` | League name. |
| `created_at` | Warehouse record creation timestamp. |

### dim_team

**Grain:** One row per soccer team.

| Column | Description |
|---|---|
| `team_key` | Surrogate warehouse key. |
| `team_api_id` | Source/business team identifier used by match data. |
| `team_fifa_api_id` | FIFA team identifier. |
| `team_long_name` | Full team name. |
| `team_short_name` | Short team name. |
| `created_at` | Warehouse record creation timestamp. |

### dim_player

**Grain:** One row per soccer player.

| Column | Description |
|---|---|
| `player_key` | Surrogate warehouse key. |
| `player_api_id` | Source/business player identifier. |
| `player_fifa_api_id` | FIFA player identifier. |
| `player_name` | Player name. |
| `birthday` | Player date of birth. |
| `height_cm` | Player height in centimeters. |
| `weight_lbs` | Player weight in pounds. |
| `created_at` | Warehouse record creation timestamp. |

### dim_date

**Grain:** One row per calendar date.

| Column | Description |
|---|---|
| `date_key` | Integer date key in `YYYYMMDD` format. |
| `full_date` | Calendar date. |
| `year` | Calendar year. |
| `quarter` | Calendar quarter. |
| `month` | Month number. |
| `month_name` | Month name. |
| `day` | Day of month. |
| `day_name` | Day name. |
| `day_of_week` | Numeric day-of-week value. |
| `week_of_year` | Calendar week number. |
| `is_weekend` | Weekend flag. |
| `soccer_season` | Associated soccer season where available. |

### fact_match

**Grain:** One row per individual soccer match.

| Column | Description |
|---|---|
| `match_key` | Surrogate warehouse key. |
| `match_api_id` | Source/business match identifier. |
| `source_match_id` | Source row identifier. |
| `date_key` | Foreign key to `dim_date`. |
| `country_key` | Foreign key to `dim_country`. |
| `league_key` | Foreign key to `dim_league`. |
| `home_team_key` | Foreign key to `dim_team` representing the home team. |
| `away_team_key` | Foreign key to `dim_team` representing the away team. |
| `match_date` | Match date and time. |
| `season` | Soccer season. |
| `stage` | Competition stage/round. |
| `home_team_goal` | Goals scored by the home team. |
| `away_team_goal` | Goals scored by the away team. |
| `total_goals` | Total goals scored in the match. |
| `goal_difference` | Home goals minus away goals. |
| `match_result` | `H`, `D`, or `A`. |
| `home_team_points` | League points earned by the home team. |
| `away_team_points` | League points earned by the away team. |
| `is_clean_sheet_home` | Whether the home team conceded zero goals. |
| `is_clean_sheet_away` | Whether the away team conceded zero goals. |
| `*_odds` | Historical bookmaker odds retained from the source. |
| `*_xml` | Detailed match-event XML feeds retained from the source. |

## Source-to-Warehouse Mapping

```text
stg_country
    ↓
dim_country

stg_league
    ↓
dim_league

stg_team
    ↓
dim_team

stg_player
    ↓
dim_player

stg_match
    ↓
fact_match

stg_match.date
    ↓
dim_date