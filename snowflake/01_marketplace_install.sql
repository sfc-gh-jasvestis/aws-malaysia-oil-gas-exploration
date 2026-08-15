-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Upstream Exploration Analytics
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): S&P Global Commodity Insights
--   Real data: https://app.snowflake.com/marketplace/listing/GZT0Z5I4XY0
--   Using mock table: MALAYSIA_OG_MACRO
CREATE TABLE IF NOT EXISTS RAW.MALAYSIA_OG_MACRO (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

