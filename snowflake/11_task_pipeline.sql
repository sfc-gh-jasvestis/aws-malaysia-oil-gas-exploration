-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Upstream Exploration Analytics
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_RETRAIN_DECLINE_MODELS
  WAREHOUSE = OG_EXPLORE_WH
  SCHEDULE = 'USING CRON 0 0 * * 0 UTC'
  COMMENT = 'Retrain production decline ML models weekly'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REFRESH_AI
  WAREHOUSE = OG_EXPLORE_WH
  AFTER APP.TASK_RETRAIN_DECLINE_MODELS
  COMMENT = 'Refresh AI document classifications'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REFRESH_ICEBERG
  WAREHOUSE = OG_EXPLORE_WH
  AFTER APP.TASK_REFRESH_AI
  COMMENT = 'Refresh Iceberg export for JV partner access'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_REFRESH_ICEBERG RESUME;
ALTER TASK APP.TASK_REFRESH_AI RESUME;
ALTER TASK APP.TASK_RETRAIN_DECLINE_MODELS RESUME;
