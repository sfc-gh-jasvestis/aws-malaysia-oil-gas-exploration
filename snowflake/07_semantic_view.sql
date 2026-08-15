-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Upstream Exploration Analytics
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.EXPLORATION_ANALYTICS
  COMMENT = 'Upstream exploration, production, and reserves analytics'
AS
  TABLES (
    CURATED.WELL_PERFORMANCE_SUMMARY AS well_performance_summary,CURATED.PRODUCTION_TIMESERIES AS production_timeseries,CURATED.BLOCK_ECONOMICS AS block_economics,CURATED.RESERVES_MOVEMENT AS reserves_movement
  );
