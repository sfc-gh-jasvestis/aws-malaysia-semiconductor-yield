-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Semiconductor Yield Optimization & Defect Detection
-- ============================================================================
USE DATABASE SEMICONDUCTOR_YIELD;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.SEMICONDUCTOR_ANALYTICS
  COMMENT = 'Semiconductor yield, defect, and equipment analytics'
AS
  TABLES (
    CURATED.FAB_YIELD_SUMMARY AS fab_yield_summary,CURATED.YIELD_TIMESERIES AS yield_timeseries,CURATED.EQUIPMENT_HEALTH AS equipment_health,CURATED.DEFECT_PARETO AS defect_pareto
  );
