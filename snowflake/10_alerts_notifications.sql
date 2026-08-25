-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Upstream Exploration Analytics
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_malaysia_oil_gas_exploration_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: PRODUCTION_DECLINE_ALERT
CREATE OR REPLACE ALERT APP.PRODUCTION_DECLINE_ALERT
  WAREHOUSE = OG_EXPLORE_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Well production declining faster than expected'
IF (EXISTS (
  SELECT 1 FROM CURATED.WELL_PERFORMANCE_SUMMARY
  WHERE 1=1 -- Condition: FORECAST_DECLINE_RATE > 15% for any well
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_oil_gas_exploration_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Upstream Exploration Analytics: Well production declining faster than expected',
    'Well production declining faster than expected'
  );

ALTER ALERT APP.PRODUCTION_DECLINE_ALERT RESUME;

-- Alert: PROSPECT_THRESHOLD_ALERT
CREATE OR REPLACE ALERT APP.PROSPECT_THRESHOLD_ALERT
  WAREHOUSE = OG_EXPLORE_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'New prospect exceeds economic threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.WELL_PERFORMANCE_SUMMARY
  WHERE 1=1 -- Condition: NPV > economic threshold for new prospect
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_oil_gas_exploration_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Upstream Exploration Analytics: New prospect exceeds economic threshold',
    'New prospect exceeds economic threshold'
  );

ALTER ALERT APP.PROSPECT_THRESHOLD_ALERT RESUME;

