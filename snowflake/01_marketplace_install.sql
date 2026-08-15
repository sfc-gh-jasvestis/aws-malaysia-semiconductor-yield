-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Semiconductor Yield Optimization & Defect Detection
-- ============================================================================
USE DATABASE SEMICONDUCTOR_YIELD;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): CEIC ASEAN Macro
--   Real data: https://app.snowflake.com/marketplace/listing/GZTSZRC7HPI
--   Using mock table: ASEAN_MACRO
CREATE TABLE IF NOT EXISTS RAW.ASEAN_MACRO (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Paid listing (mock): OnPoint Historical Weather
--   Real data: https://app.snowflake.com/marketplace/listing/GZSOZBT22EH
--   Using mock table: WEATHER_PENANG
CREATE TABLE IF NOT EXISTS RAW.WEATHER_PENANG (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

