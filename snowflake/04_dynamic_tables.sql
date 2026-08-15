-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Upstream Exploration Analytics
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA CURATED;

-- WELL_PERFORMANCE_SUMMARY: Well-level production rates, water cut, and decline metrics
-- Source: WELLS, PRODUCTION_LOGS
CREATE OR REPLACE DYNAMIC TABLE CURATED.WELL_PERFORMANCE_SUMMARY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = OG_EXPLORE_WH
AS
SELECT * FROM RAW.WELLS;
-- TODO: Replace with actual join/aggregation logic per demo

-- PRODUCTION_TIMESERIES: Daily production by well for ML.FORECAST input
-- Source: PRODUCTION_LOGS
CREATE OR REPLACE DYNAMIC TABLE CURATED.PRODUCTION_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = OG_EXPLORE_WH
AS
SELECT * FROM RAW.PRODUCTION_LOGS;
-- TODO: Replace with actual join/aggregation logic per demo

-- BLOCK_ECONOMICS: Block-level NPV, breakeven price, and prospect ranking
-- Source: WELLS, RESERVES, PRODUCTION_LOGS
CREATE OR REPLACE DYNAMIC TABLE CURATED.BLOCK_ECONOMICS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = OG_EXPLORE_WH
AS
SELECT * FROM RAW.WELLS;
-- TODO: Replace with actual join/aggregation logic per demo

-- RESERVES_MOVEMENT: Annual reserves booking and depletion by category
-- Source: RESERVES
CREATE OR REPLACE DYNAMIC TABLE CURATED.RESERVES_MOVEMENT
  TARGET_LAG = '5 minutes'
  WAREHOUSE = OG_EXPLORE_WH
AS
SELECT * FROM RAW.RESERVES;
-- TODO: Replace with actual join/aggregation logic per demo

