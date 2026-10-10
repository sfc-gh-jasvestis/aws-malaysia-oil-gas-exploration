# Malaysia Offshore Exploration Drilling

**Malaysia - Offshore Oil and Gas Exploration**
Use case: Rig productivity and non-productive time (NPT) risk

> Drilling operations analytics for a fictional exploration operator with 30 synthetic rigs and units working from 4 Malaysian supply bases: dynamic tables, a holdout-evaluated NPT-risk classifier, a diesel-use forecast and grounded AI answers. Thresholds and specifications are internal demo values.

## Why Snowflake

- **Dynamic tables** reconcile productive time, NPT events, mud checks within spec and diesel intensity from RAW rig data, with checks in `run_core.py`
- **NPT-risk classification** gives a holdout-evaluated next-7-day NPT probability per rig
- **Diesel forecast** projects 14 days of fleet-wide diesel use (m3) with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.RIGS` (30 rows) |
| Fact table | `RAW.RIG_DAILY` (2,700 rig-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `NPT_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.NPT_RISK_SCORES`, `ML.NPT_RISK_HOLDOUT_METRICS`, `ML.FUEL_FORECAST`, `ML.SPP_ANOMALIES` |

Supply bases: Miri, Kemaman, Bintulu, Labuan.
Rig types: Jack-up Rig, Semi-submersible Rig, Tender-assist Rig, Drillship, Hydraulic Workover Unit.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Mud Checks Within Spec | 87.9% |
| NPT Events | 378 |
| Diesel Intensity | 209.5 L/m |
| Diesel Used (m3) | 64,354 |
| Productive Time | 97.8% |
| Rigs Monitored | 30 |
| Current-Well Depth Progress | 57.0% |
| Well-Control Kicks | 25 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily mud checks within spec, NPT hours by root cause, rig table
2. Predictive: holdout metrics, risk bands, 14-day diesel forecast, standpipe-pressure anomalies
3. Rig Health: rigs monitored, current-well depth progress, BOP pressure-test completion against mud checks within spec, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Per-rig productive time ranges from 90.7% to 100%. Labuan is the lowest supply base, at 96.7%.
- Snubbing equipment faults cost the most NPT hours (281.1) of the 13 NPT causes.
- Drillships carry the highest diesel intensity (313.5 L/m in the synthetic factors); tender-assist rigs are lowest at 131.7 L/m.
- The risk model is evaluated on a time-based holdout: precision 0.54 and recall 0.61 at 0.5, against a 0.39 base rate. Present it as triage, not a guarantee.
- The Kemaman monsoon weather standby and Labuan supply vessel delay are excluded from NPT labels, because they are supply-base events, not rig-driven.
- No figure is a finding about any real operator, rig or field; all thresholds are internal to the demo.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
