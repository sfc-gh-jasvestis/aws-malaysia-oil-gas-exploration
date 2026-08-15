-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Upstream Exploration Analytics
-- Country: MALAYSIA | Currency: MYR
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- WELLS: 200 rows — Exploration and production wells across 8 offshore blocks
-- SEISMIC_SURVEYS: 50 rows — 2D/3D seismic survey metadata and interpretation results
-- PRODUCTION_LOGS: 100,000 rows — Daily production logs (oil, gas, water) for all active wells
-- RESERVES: 500 rows — Proved, probable, and possible reserves estimates by block
-- EXPLORATION_DOCS: 120 rows — Subsurface reports, well proposals, geological assessments, PSC summaries
-- MALAYSIA_OG_MACRO: 10 rows — Malaysia O&G production context and Brent/Tapis pricing
