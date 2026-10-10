-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TELEMETRY.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic drilling NPT-response knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.WELL_SOP_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, s.CATEGORY
  FROM RAW.RIG_DAILY r JOIN RAW.RIGS s ON s.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.NPT_EVENTS > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' NPT response' AS TITLE,
  'Synthetic demo SOP. Rig type: ' || CATEGORY || '. NPT cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: the driller makes the well safe, informs the toolpusher and company representative, and logs the event in the daily drilling report. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%stuck%' THEN 'work the string within the agreed overpull limits, keep circulation if possible and review hole-cleaning and mud weight before any jarring.'
       WHEN ROOT_CAUSE ILIKE '%losses%' THEN 'reduce pump rate, measure the loss rate, and pump the planned lost-circulation material pill before resuming.'
       WHEN ROOT_CAUSE ILIKE '%top drive%' OR ROOT_CAUSE ILIKE '%pump%' OR ROOT_CAUSE ILIKE '%snubbing%' THEN 'switch to backup equipment where fitted, isolate the faulty unit and raise a maintenance work order with the rig mechanic.'
       WHEN ROOT_CAUSE ILIKE '%bop%' THEN 'confirm the alternate control pod is available, function-test the affected functions and do not drill ahead until the subsea engineer signs off.'
       WHEN ROOT_CAUSE ILIKE '%riser%' OR ROOT_CAUSE ILIKE '%crane%' THEN 'stop lifting operations, re-check the lift plan and weather limits, and resume only after the deck crew briefing.'
       WHEN ROOT_CAUSE ILIKE '%positioning%' THEN 'move to the planned disconnect readiness level, review thruster status and hold operations until positioning is stable.'
       WHEN ROOT_CAUSE ILIKE '%instability%' THEN 'review mud weight and trip speeds with the drilling engineer, and ream the affected interval before tripping out.'
       WHEN ROOT_CAUSE ILIKE '%wireline%' THEN 'confirm tool and crew availability with the service company and resequence the programme to keep the rig productive.'
       WHEN ROOT_CAUSE ILIKE '%monsoon%' OR ROOT_CAUSE ILIKE '%vessel%' THEN 'secure the well, apply the weather or logistics standby plan and agree a restart window with the supply base.'
       ELSE 'record the issue, make the well safe and escalate to the drilling superintendent.'
     END
  || ' Step 3: if standpipe pressure stays above 260 bar or hookload above 90% of rating after the response, keep the rig on the watch list and inform the drilling superintendent. '
  || 'Step 4: confirm that mud checks are back within the internal specification and record the root cause in the NPT register.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.WELL_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.WELL_SOP_DOCS);

-- ---------- Standpipe pressure anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.SPP_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, SPP_BAR::FLOAT AS SPP
FROM RAW.RIG_DAILY;
CREATE OR REPLACE VIEW ML.SPP_TRAIN AS
SELECT * FROM ML.SPP_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.SPP_SERIES);
CREATE OR REPLACE VIEW ML.SPP_DETECT AS
SELECT * FROM ML.SPP_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.SPP_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.SPP_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.SPP_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'SPP',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.SPP_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS SPP, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.SPP_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.SPP_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'SPP'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.DRILLING_ANALYTICS
  TABLES (
    rigs AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'rigs', 'drilling units', 'fleet')
      COMMENT = 'One row per drilling rig or workover unit (entity), 90-day totals',
    risk AS ML.NPT_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day NPT-event probability per rig',
    causes AS CURATED.NPT_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Non-productive time (NPT) events by root cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Fleet-wide totals per day'
  )
  RELATIONSHIPS (risk_rig AS risk (ENTITY_ID) REFERENCES rigs)
  FACTS (
    rigs.checks_in_spec_f AS CHECKS_IN_SPEC,
    rigs.mud_checks_f AS MUD_CHECKS,
    rigs.metres_drilled_f AS METRES_DRILLED,
    rigs.fuel_m3_f AS FUEL_M3,
    rigs.kicks_f AS KICKS,
    rigs.npt_events_f AS NPT_EVENTS,
    rigs.npt_hours_f AS NPT_HOURS,
    rigs.productive_hours_f AS PRODUCTIVE_HOURS,
    rigs.planned_hours_f AS PLANNED_HOURS,
    risk.npt_prob_f AS NPT_PROB_7D,
    causes.cause_npt_events_f AS NPT_EVENTS,
    causes.cause_off_spec_f AS CHECKS_OFF_SPEC,
    causes.cause_hours_f AS NPT_HOURS,
    daily.day_in_spec_f AS CHECKS_IN_SPEC,
    daily.day_checks_f AS MUD_CHECKS,
    daily.day_fuel_f AS FUEL_M3,
    daily.day_npt_events_f AS NPT_EVENTS
  )
  DIMENSIONS (
    rigs.rig_id AS ENTITY_ID WITH SYNONYMS = ('rig', 'entity', 'entity id', 'rig id'),
    rigs.rig_name AS ENTITY_NAME,
    rigs.supply_base AS REGION WITH SYNONYMS = ('supply base', 'region', 'base', 'city') COMMENT = 'Malaysian supply-base city',
    rigs.rig_type AS CATEGORY WITH SYNONYMS = ('rig type', 'unit type', 'category'),
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    rigs.rig_count AS COUNT(rigs.rig_id) WITH SYNONYMS = ('number of entities', 'entity count', 'number of rigs'),
    rigs.mud_in_spec_pct AS 100 * SUM(rigs.checks_in_spec_f) / NULLIF(SUM(rigs.mud_checks_f), 0)
      WITH SYNONYMS = ('mud checks within spec', 'drilling fluid quality') COMMENT = 'Mud checks within the internal demo specification / mud checks',
    rigs.total_npt_events AS SUM(rigs.npt_events_f) WITH SYNONYMS = ('NPT events', 'non-productive time events'),
    rigs.diesel_l_per_m AS 1000 * SUM(rigs.fuel_m3_f) / NULLIF(SUM(rigs.metres_drilled_f), 0)
      WITH SYNONYMS = ('diesel intensity', 'fuel intensity') COMMENT = 'Litres of diesel per metre drilled',
    rigs.total_diesel_m3 AS SUM(rigs.fuel_m3_f) WITH SYNONYMS = ('diesel used', 'fuel used'),
    rigs.total_metres AS SUM(rigs.metres_drilled_f) WITH SYNONYMS = ('metres drilled', 'footage'),
    rigs.total_kicks AS SUM(rigs.kicks_f) WITH SYNONYMS = ('kicks', 'well-control kicks'),
    rigs.productive_time_share_pct AS 100 * SUM(rigs.productive_hours_f) / NULLIF(SUM(rigs.planned_hours_f), 0)
      WITH SYNONYMS = ('productive time', 'rig uptime'),
    rigs.total_npt_hours AS SUM(rigs.npt_hours_f) WITH SYNONYMS = ('NPT hours', 'non-productive hours'),
    risk.avg_npt_prob AS AVG(risk.npt_prob_f),
    causes.cause_npt_event_total AS SUM(causes.cause_npt_events_f),
    causes.cause_checks_off_spec AS SUM(causes.cause_off_spec_f),
    causes.cause_npt_hour_total AS SUM(causes.cause_hours_f),
    daily.daily_in_spec_pct AS 100 * SUM(daily.day_in_spec_f) / NULLIF(SUM(daily.day_checks_f), 0),
    daily.daily_diesel_m3 AS SUM(daily.day_fuel_f),
    daily.daily_npt_event_total AS SUM(daily.day_npt_events_f)
  )
  COMMENT = 'Synthetic Malaysia offshore exploration drilling analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.DRILLING_AGENT
  COMMENT = 'Drilling operations assistant over a synthetic Malaysian offshore exploration operator'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic and that thresholds are internal demo thresholds. Give rig IDs and numbers with units."
  orchestration: "Use drilling_analyst for productive time, NPT events and hours, mud checks within spec, metres drilled, diesel use and intensity, kicks, rigs, supply bases, risk and root causes. Use sop_search for NPT response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: drilling_analyst
      description: "Productive time, non-productive time (NPT) events and hours, mud checks within the internal specification, metres drilled, diesel use and intensity, well-control kicks, root causes and NPT-risk scores per rig"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic NPT-response SOPs by rig type and cause"
tool_resources:
  drilling_analyst:
    semantic_view: __DEMO_DB__.APP.DRILLING_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.WELL_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), RIG_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, SPP_BAR FLOAT, HOOKLOAD_PCT FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION MY_OIL_GAS_EXPLORATION_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (RIG_ID, EVENT_TS, SPP_BAR, HOOKLOAD_PCT, SOP_HINT)
    SELECT t.RIG_ID, t.EVENT_TS, t.SPP_BAR, t.HOOKLOAD_PCT,
           'Check ' || s.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.RIGS s ON s.ID = t.RIG_ID
    LEFT JOIN ML.NPT_RISK_SCORES r ON r.ENTITY_ID = t.RIG_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.RIG_ID = t.RIG_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('MY_OIL_GAS_EXPLORATION_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Malaysia exploration drilling rig-floor alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.RIG_ID = t.RIG_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.NPT_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.NPT_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.NPT_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.NPT_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'SPP_BAR', SPP_BAR,
             'HOOKLOAD_PCT', HOOKLOAD_PCT, 'SPP_7D', SPP_7D, 'NPT_EVENTS_30D', NPT_EVENTS_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:NPT::FLOAT, 4) AS NPT_PROB_7D,
         CASE WHEN PRED:probability:NPT::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:NPT::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
