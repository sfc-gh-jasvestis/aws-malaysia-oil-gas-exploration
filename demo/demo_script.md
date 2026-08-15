# Demo Script: Upstream Exploration Analytics
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake unifies seismic, well, and production data across 8 offshore blocks — ML.FORECAST models decline curves, Cortex Search surfaces subsurface reports, and Iceberg sharing gives JV partners governed access without data copies"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Dr. Kamal bin Mohamad** | VP Exploration | React App (SPCS) | Portfolio economics, prospect ranking, reserves replacement ratio, JV partner reporting |
| **Sarah Tan Wei Ling** | Geologist | Amazon QuickSight | Seismic interpretation, well correlation, reservoir characterisation, subsurface risk |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | WELLS (200), SEISMIC_SURVEYS (50), PRODUCTION_LOGS (100000), RESERVES (500), EXPLORATION_DOCS (120), MALAYSIA_OG_MACRO (10) |
| **CURATED** | 4 Dynamic Tables | WELL_PERFORMANCE_SUMMARY, PRODUCTION_TIMESERIES, BLOCK_ECONOMICS, RESERVES_MOVEMENT |
| **ML** | ML.FORECAST | Forecasting + anomaly detection |
| **AI** | SUMMARIZE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 120 documents indexed |
| **Agent** | EXPLORATION_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

Malaysia's offshore basins produce 600,000 barrels per day across hundreds of wells operated under Production Sharing Contracts with PETRONAS. A VP Exploration needs to rank prospects, forecast decline curves, and share data with JV partners — but subsurface intelligence is trapped in PDFs, production data sits in siloed systems, and partner reporting requires manual extracts.

---

## Script

### [0:00–0:45] PORTFOLIO OVERVIEW

**Show**: Portfolio Overview tab

> "Two hundred wells across 8 Production Sharing Contract blocks in the Malay and Sarawak Basins."

**Action**: Point at the RM 4.2B revenue KPI card

### [0:45–1:30] PRODUCTION ANALYTICS

**Show**: Production Analytics tab

> "Well MY-047 in Block PM-3 showing 18% annual decline — faster than type curve prediction."

**Action**: Click Well MY-047 in the well list

### [1:30–2:15] SUBSURFACE INTELLIGENCE

**Show**: Subsurface Intelligence tab

> "One hundred and twenty subsurface documents — well proposals, seismic interpretations, geological assessments."

**Action**: Search for 'Prospect Alpha reservoir quality'

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Dr. Kamal asks: 'Which prospects exceed our economic threshold?'"

**Action**: Type: 'Which prospects exceed our economic threshold?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.FORECAST on production decline curves** — Only demo using ML.FORECAST for oil well decline projection — not demand or yield
2. **Iceberg for JV partner access** — Only demo showing governed data sharing with joint venture partners via open table format
3. **Cortex Search on subsurface documents** — Only demo indexing geological and well proposal documents for exploration intelligence
4. **Malaysian upstream O&G context** — Petronas PSC framework, Malay/Sarawak Basin terminology, MYR economics
5. **Prospect ranking with NPV** — Combines reserves, production, and cost data to rank exploration prospects economically
6. **AWS SageMaker geophysical + Iceberg** — Only demo combining geophysical ML with Iceberg open table export for partners


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM OIL_GAS_EXPLORATION.RAW.WELLS` → 200
- [ ] `SELECT COUNT(*) FROM OIL_GAS_EXPLORATION.RAW.PRODUCTION_LOGS` → 100000
- [ ] `SELECT COUNT(DISTINCT BLOCK_ID) FROM OIL_GAS_EXPLORATION.CURATED.BLOCK_ECONOMICS` → 8

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM OIL_GAS_EXPLORATION.ML.PRODUCTION_DECLINE_RESULTS` → >0
- [ ] `SELECT COUNT(*) FROM OIL_GAS_EXPLORATION.ML.PRODUCTION_DECLINE_RESULTS WHERE FORECAST_DECLINE_RATE > 0.15` → >=3

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM OIL_GAS_EXPLORATION.AI.DOC_CLASSIFICATION WHERE MATURITY = 'DEVELOPMENT_READY'` → >=3

