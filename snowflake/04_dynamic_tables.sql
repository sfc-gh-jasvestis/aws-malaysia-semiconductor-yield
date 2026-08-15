-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Semiconductor Yield Optimization & Defect Detection
-- ============================================================================
USE DATABASE SEMICONDUCTOR_YIELD;
USE SCHEMA CURATED;

-- FAB_YIELD_SUMMARY: Fab-level yield performance and loss calculation
-- Source: FABS, WAFER_LOTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.FAB_YIELD_SUMMARY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SEMI_WH
AS
SELECT * FROM RAW.FABS;
-- TODO: Replace with actual join/aggregation logic per demo

-- YIELD_TIMESERIES: Daily yield by fab for ML.FORECAST input
-- Source: WAFER_LOTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.YIELD_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SEMI_WH
AS
SELECT * FROM RAW.WAFER_LOTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- EQUIPMENT_HEALTH: Equipment status with alarm counts
-- Source: EQUIPMENT, EQUIPMENT_TELEMETRY
CREATE OR REPLACE DYNAMIC TABLE CURATED.EQUIPMENT_HEALTH
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SEMI_WH
AS
SELECT * FROM RAW.EQUIPMENT;
-- TODO: Replace with actual join/aggregation logic per demo

-- DEFECT_PARETO: Defect type distribution by fab
-- Source: WAFER_LOTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.DEFECT_PARETO
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SEMI_WH
AS
SELECT * FROM RAW.WAFER_LOTS;
-- TODO: Replace with actual join/aggregation logic per demo

