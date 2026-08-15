-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Semiconductor Yield Optimization & Defect Detection
-- ============================================================================
USE DATABASE SEMICONDUCTOR_YIELD;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.PROCESS_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, FAB_ID, AUTHOR
  WAREHOUSE = SEMI_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.PROCESS_DOCUMENTS
);
