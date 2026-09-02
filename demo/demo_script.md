# Upstream Exploration Analytics

**Malaysia - Oil & Gas — Upstream Exploration**
Use case: Exploration Analytics

> Data-driven exploration for Malaysia's offshore basins — ML.FORECAST projects production curves, Iceberg enables JV partner access, and Cortex Agent answers subsurface questions.

## Why Snowflake

Snowflake unifies seismic, well, and production data across 8 offshore blocks — ML.FORECAST models decline curves, Cortex Search surfaces subsurface reports, and Iceberg sharing gives JV partners governed access without data copies

- **ML.FORECAST on production decline curves** - Only demo using ML.FORECAST for oil well decline projection — not demand or yield
- **Iceberg for JV partner access** - Only demo showing governed data sharing with joint venture partners via open table format
- **Cortex Search on subsurface documents** - Only demo indexing geological and well proposal documents for exploration intelligence
- **Malaysian upstream O&G context** - Petronas PSC framework, Malay/Sarawak Basin terminology, MYR economics
- **Prospect ranking with NPV** - Combines reserves, production, and cost data to rank exploration prospects economically
- **AWS SageMaker geophysical + Iceberg** - Only demo combining geophysical ML with Iceberg open table export for partners

## What is deployed

| | |
|---|---|
| Database | `MY_OIL_GAS_EXPLORATION` |
| Service | `MY_OIL_GAS_EXPLORATION_APP` |
| Compute pool | `SEA_DEMOS_MALAYSIA_POOL` |
| Dimension table | `RAW.MALAYSIA_OG_MACRO` (20 rows) |
| Fact table | `RAW.PRODUCTION_LOGS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | MYR (RM) |

Regions in play: Selangor, Johor, Penang, Sabah, Sarawak
Segments: Deepwater, Shallow Water, Onshore, Marginal Field

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh MY_OIL_GAS_EXPLORATION
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Exploration Wells | `12` | average per event |
| Success Rate | `42%` | average per event |
| Resources Added | `847 MMboe` | average per event |
| Seismic (km²) | `14,200` | total across Malaysia Og Macro |
| AI Prospect Score | `72%` | average per event |
| Seismic Coverage | `94%` | average per event |
| Drilling Cost/Well | `RM 84M` | average per event |


## Demo flow

1. Portfolio Overview
2. Production Analytics
3. Subsurface Intelligence
4. Ask AI
5. Architecture & Data

## Talking points

- **200 wells** - across 8 offshore blocks in Malay and Sarawak Basins
- **RM 4.2B** - annual production revenue
- **3 prospects** - above economic threshold (NPV > RM 800M)
- **120 subsurface docs** - indexed and searchable via Cortex Search
- **100K production logs** - daily readings across all active wells
- **18% decline rate** - accelerated decline in Block PM-3 wells
- **4 wells** - flagged for workover due to high water cut

## Business impact

- Malaysia produced 594,000 bbl/d of crude oil and 83.5 Bcm of natural gas in 2023 (EIA)
- PETRONAS reported RM 282.7B revenue in 2023 with upstream as the largest contributor (PETRONAS Annual Report)
- AI-enabled reservoir management can increase recovery by 5-8% per field (McKinsey Energy)
- Snowflake enables real-time data sharing across energy joint ventures (Snowflake Energy)

---
Generated from `generator/demo_specs/aws-malaysia-oil-gas-exploration.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-malaysia-oil-gas-exploration` instead.
