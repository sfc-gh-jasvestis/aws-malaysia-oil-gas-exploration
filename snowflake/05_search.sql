-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Upstream Exploration Analytics
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.SUBSURFACE_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, BLOCK_ID, PROSPECT_NAME, AUTHOR
  WAREHOUSE = OG_EXPLORE_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.EXPLORATION_DOCS
);
