-- ============================================================
-- Staging Layer
-- Project: European Soccer Data Engineering
-- ============================================================

USE soccer_dw;

--Staging table for country data
CREATE TABLE stg_country (
    country_id BIGINT,
    country_name VARCHAR(100)
);