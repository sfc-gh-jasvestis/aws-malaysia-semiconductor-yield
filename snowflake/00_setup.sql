-- Generated from generator/demo_specs/aws-malaysia-semiconductor-yield.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-malaysia-semiconductor-yield
-- This is the schema that is actually deployed for MY_SEMICONDUCTOR_YIELD.

-- MY_SEMICONDUCTOR_YIELD  (Semiconductor Yield Optimization & Defect Detection)
-- generated from generator/demo_specs/aws-malaysia-semiconductor-yield.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS MY_SEMICONDUCTOR_YIELD;
CREATE SCHEMA IF NOT EXISTS MY_SEMICONDUCTOR_YIELD.RAW;
CREATE SCHEMA IF NOT EXISTS MY_SEMICONDUCTOR_YIELD.CURATED;
CREATE SCHEMA IF NOT EXISTS MY_SEMICONDUCTOR_YIELD.APP;
USE DATABASE MY_SEMICONDUCTOR_YIELD;

-- 5 real regions; entity names carry their region so the two always agree
