-- Synthetic rig-day drilling observations for a fictional exploration and
-- appraisal operator offshore Malaysia. Nothing is seeded as a
-- prediction. Randomness is HASH-seeded, so every rebuild is reproducible:
-- per-rig drilling rate, rig age and NPT propensity, weekly drilling-rate
-- seasonality and a fast-drilling peak, wear between BOP pressure
-- tests, rig-type-weighted NPT causes, and two supply-base standby events.
-- Thresholds are internal demo thresholds, not regulatory or contractual limits.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.RIGS AS
WITH rigs AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS RIG_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 30))
), draws AS (
  SELECT RIG_INDEX,
         MOD(ABS(HASH(RIG_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(RIG_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(RIG_INDEX, 'insp')), 1000000) / 1e6 AS U_INSP,
         MOD(ABS(HASH(RIG_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(RIG_INDEX, 'capacity')), 1000000) / 1e6 AS U_CAPACITY
  FROM rigs
)
SELECT 'RG-' || LPAD(RIG_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic rig ' || LPAD(RIG_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (7 and 5 are coprime): every supply base and rig
       -- type is present, with the Miri and Kemaman supply bases largest.
       CASE MOD(RIG_INDEX, 7) WHEN 0 THEN 'Miri' WHEN 1 THEN 'Miri'
            WHEN 2 THEN 'Kemaman' WHEN 3 THEN 'Kemaman'
            WHEN 4 THEN 'Bintulu' ELSE 'Labuan' END AS REGION,
       CASE MOD(RIG_INDEX, 5) WHEN 0 THEN 'Jack-up Rig' WHEN 1 THEN 'Semi-submersible Rig'
            WHEN 2 THEN 'Tender-assist Rig' WHEN 3 THEN 'Drillship'
            ELSE 'Hydraulic Workover Unit' END AS CATEGORY,
       RIG_INDEX,
       ROUND(1 + U_AGE * 9, 1) AS AGE_YEARS,
       -- Base daily NPT probability 0.5%-3.5%; ~15% of rigs are chronic (x3).
       (0.005 + U_RATE * 0.03) * IFF(U_RATE > 0.85, 3, 1) AS BASE_NPT_RATE,
       7 * (1 + FLOOR(U_INSP * 3)) AS BOP_TEST_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS BOP_TEST_COMPLETION_PROB,
       -- Metres drilled per day at full rate, by rig type.
       ROUND(CASE MOD(RIG_INDEX, 5) WHEN 0 THEN 180 WHEN 1 THEN 150 WHEN 2 THEN 160
                  WHEN 3 THEN 140 ELSE 60 END * (0.8 + U_CAPACITY * 0.4)) AS DAILY_CAPACITY,
       -- Diesel use (m3 per metre drilled), synthetic and by rig type.
       CASE MOD(RIG_INDEX, 5) WHEN 0 THEN 0.15 WHEN 1 THEN 0.25 WHEN 2 THEN 0.12
            WHEN 3 THEN 0.30 ELSE 0.20 END * (0.9 + U_AGE * 0.2) AS FUEL_FACTOR,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.RIG_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), regional_events AS (
  -- Two supply-base-wide standby events in the window.
  SELECT * FROM VALUES (27, 'Kemaman', 'Monsoon weather standby', 6.0),
                       (64, 'Labuan', 'Supply vessel delay', 9.0)
    AS o(DAY_INDEX, REGION, EVENT_CAUSE, HOURS)
), base AS (
  SELECT s.ID AS ENTITY_ID, s.RIG_INDEX, s.CATEGORY, s.REGION, s.AGE_YEARS,
         s.BASE_NPT_RATE, s.BOP_TEST_INTERVAL_DAYS, s.BOP_TEST_COMPLETION_PROB,
         s.DAILY_CAPACITY, s.FUEL_FACTOR, d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         24.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + s.RIG_INDEX * 5, s.BOP_TEST_INTERVAL_DAYS) AS DAYS_SINCE_BOP_TEST,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'exc')), 1000000) / 1e6 AS U_EXC,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'inspdone')), 1000000) / 1e6 AS U_INSPDONE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'hit')), 1000000) / 1e6 AS U_HIT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'grv')), 1000000) / 1e6 AS U_GRV,
         e.EVENT_CAUSE, e.HOURS AS EVENT_HOURS
  FROM RAW.RIGS s CROSS JOIN days d
  LEFT JOIN regional_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = s.REGION
), loaded AS (
  SELECT *,
         IFF(DAYS_SINCE_BOP_TEST = 0, 1, 0) AS BOP_TEST_DUE,
         IFF(DAYS_SINCE_BOP_TEST = 0 AND U_INSPDONE < BOP_TEST_COMPLETION_PROB, 1, 0) AS BOP_TEST_DONE,
         -- Equipment wear rises between BOP tests; weak test discipline carries wear over.
         DAYS_SINCE_BOP_TEST / BOP_TEST_INTERVAL_DAYS + (1 - BOP_TEST_COMPLETION_PROB) AS WEAR,
         -- Hard-formation episode: 9 of every 28 days per rig (staggered).
         IFF(MOD(DAY_INDEX + RIG_INDEX * 11, 28) < 9, 1, 0) AS STRESS,
         -- Drilling rate: weekly low day and a fast-drilling peak on day 45 (+60%) easing over 3 days.
         ROUND(DAILY_CAPACITY * (0.70 + 0.25 * U_VOLUME)
               * IFF(MOD(DAY_INDEX, 7) = 6, 0.75, 1.0)
               * CASE DAY_INDEX - 45 WHEN 0 THEN 1.6 WHEN 1 THEN 1.4 WHEN 2 THEN 1.2 ELSE 1.0 END) AS METRES_DRILLED
  FROM base
), npt_events AS (
  SELECT *, METRES_DRILLED / DAILY_CAPACITY AS LOAD_RATIO,
         LEAST(0.5, BASE_NPT_RATE * (0.4 + 1.6 * WEAR) * (0.3 + METRES_DRILLED / DAILY_CAPACITY)
                    * (1 + AGE_YEARS / 20) * (1 + 2.5 * STRESS)) AS P_EXC
  FROM loaded
), counted AS (
  SELECT *,
         CASE WHEN EVENT_HOURS IS NOT NULL THEN 1
              WHEN U_EXC < P_EXC / 4 THEN 2
              WHEN U_EXC < P_EXC THEN 1
              ELSE 0 END AS NPT_EVENTS
  FROM npt_events
)
, timed AS (
  SELECT *,
         -- Non-productive hours: exponential, mean depends on rig type.
         CASE WHEN NPT_EVENTS = 0 THEN 0.0
              WHEN EVENT_HOURS IS NOT NULL THEN EVENT_HOURS
              ELSE LEAST(20.0, ROUND(NPT_EVENTS * (0.5 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Jack-up Rig' THEN 3.0 WHEN 'Semi-submersible Rig' THEN 2.0
                                 WHEN 'Tender-assist Rig' THEN 4.0 WHEN 'Drillship' THEN 2.5 ELSE 3.5 END), 1))
         END AS NPT_HOURS,
         -- Share of drilling-fluid (mud) checks within the internal demo specification.
         LEAST(0.995, GREATEST(0.50,
           CASE CATEGORY WHEN 'Jack-up Rig' THEN 0.955 WHEN 'Semi-submersible Rig' THEN 0.960
                         WHEN 'Tender-assist Rig' THEN 0.940 WHEN 'Drillship' THEN 0.935 ELSE 0.950 END
           - 0.025 * WEAR - 0.04 * GREATEST(0, LOAD_RATIO - 0.9) - 0.006 * U_NOISE
           - NPT_EVENTS * (0.08 + 0.12 * U_HIT))) AS IN_SPEC_RATE,
         12 + FLOOR(U_VOLUME * 13) AS MUD_CHECKS
  FROM counted
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, NPT_HOURS,
       PLANNED_HOURS - NPT_HOURS AS PRODUCTIVE_HOURS,
       NPT_EVENTS,
       CASE WHEN NPT_EVENTS = 0 THEN 'None'
            WHEN EVENT_CAUSE IS NOT NULL THEN EVENT_CAUSE
            WHEN CATEGORY = 'Jack-up Rig' THEN IFF(U_CAUSE < 0.5, 'Stuck pipe', IFF(U_CAUSE < 0.8, 'Mud losses', 'Top drive fault'))
            WHEN CATEGORY = 'Semi-submersible Rig' THEN IFF(U_CAUSE < 0.55, 'BOP control fault', 'Riser handling delay')
            WHEN CATEGORY = 'Tender-assist Rig' THEN IFF(U_CAUSE < 0.6, 'Mud pump failure', 'Crane downtime')
            WHEN CATEGORY = 'Drillship' THEN IFF(U_CAUSE < 0.6, 'Dynamic positioning alert', 'Wellbore instability')
            ELSE IFF(U_CAUSE < 0.6, 'Snubbing equipment fault', 'Wireline delay') END AS ROOT_CAUSE,
       BOP_TEST_DUE, BOP_TEST_DONE,
       MUD_CHECKS,
       FLOOR(MUD_CHECKS * IN_SPEC_RATE) AS CHECKS_IN_SPEC,
       METRES_DRILLED,
       ROUND(METRES_DRILLED * FUEL_FACTOR * (1 + 0.05 * U_NOISE + 0.03 * WEAR), 1) AS FUEL_M3,
       IFF(U_GRV < 0.005 + 0.02 * NPT_EVENTS + 0.005 * STRESS, 1, 0) AS KICKS,
       ROUND(160 + 30 * WEAR + 50 * GREATEST(0, LOAD_RATIO - 0.8) + 15 * STRESS + 45 * NPT_EVENTS + U_NOISE * 10, 1) AS SPP_BAR,
       ROUND(LEAST(100, 100 * LOAD_RATIO * (0.75 + 0.1 * U_NOISE) + 7 * STRESS + 4 * NPT_EVENTS), 1) AS HOOKLOAD_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM timed;

-- Current-well depth progress per rig (snapshot): planned versus drilled metres.
CREATE TABLE RAW.WELL_PROGRESS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Jack-up Rig' THEN 'Surface hole' WHEN 'Semi-submersible Rig' THEN 'Intermediate hole'
                     WHEN 'Tender-assist Rig' THEN 'Production hole' WHEN 'Drillship' THEN 'Reservoir section'
                     ELSE 'Completion' END AS WELL_PHASE,
       2000 + 25 * MOD(ABS(HASH(ID, 'req')), 81) AS PLANNED_DEPTH_M,
       FLOOR((2000 + 25 * MOD(ABS(HASH(ID, 'req')), 81)) * (0.30 + MOD(ABS(HASH(ID, 'avail')), 1000) / 1000 * 0.45)) AS DRILLED_DEPTH_M,
       MOD(ABS(HASH(ID, 'order')), 8) AS PENDING_CASING_STRINGS,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.RIGS;
