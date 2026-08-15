-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Semiconductor Yield Optimization & Defect Detection
-- Country: MALAYSIA | Currency: MYR
-- ============================================================================
USE DATABASE SEMICONDUCTOR_YIELD;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- FABS: 12 rows — Fabrication facilities (Penang + Kulim)
-- PRODUCTS: 8 rows — Wafer product types (Logic, Power, MEMS, RF, etc.)
-- EQUIPMENT: 120 rows — Critical manufacturing tools across all fabs
-- WAFER_LOTS: 5,000 rows — 90 days of lot production records with yield
-- EQUIPMENT_TELEMETRY: 500,000 rows — Sensor readings (pressure, temp, RF power, flow)
-- PROCESS_DOCUMENTS: 80 rows — SOPs, ECNs, quality alerts, investigation reports
-- WEATHER_PENANG: 365 rows — Ambient conditions (humidity/temp impact on yield)
-- ASEAN_MACRO: 8 rows — Malaysia semiconductor export context
