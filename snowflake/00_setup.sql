-- ============================================================================
-- Upstream Exploration Analytics
-- Data-driven exploration for Malaysia's offshore basins — ML.FORECAST projects production curves, Iceberg enables JV partner access, and Cortex Agent answers subsurface questions.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS OIL_GAS_EXPLORATION;
CREATE WAREHOUSE IF NOT EXISTS OG_EXPLORE_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE OIL_GAS_EXPLORATION;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE OG_EXPLORE_WH;
