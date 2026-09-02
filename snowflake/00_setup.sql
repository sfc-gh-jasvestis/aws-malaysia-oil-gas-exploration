-- Generated from generator/demo_specs/aws-malaysia-oil-gas-exploration.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-malaysia-oil-gas-exploration
-- This is the schema that is actually deployed for MY_OIL_GAS_EXPLORATION.

-- MY_OIL_GAS_EXPLORATION  (Upstream Exploration Analytics)
-- generated from generator/demo_specs/aws-malaysia-oil-gas-exploration.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS MY_OIL_GAS_EXPLORATION;
CREATE SCHEMA IF NOT EXISTS MY_OIL_GAS_EXPLORATION.RAW;
CREATE SCHEMA IF NOT EXISTS MY_OIL_GAS_EXPLORATION.CURATED;
CREATE SCHEMA IF NOT EXISTS MY_OIL_GAS_EXPLORATION.APP;
USE DATABASE MY_OIL_GAS_EXPLORATION;

-- 5 real regions; entity names carry their region so the two always agree
