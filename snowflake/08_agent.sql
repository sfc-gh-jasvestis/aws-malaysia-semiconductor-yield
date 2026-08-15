-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Semiconductor Yield Optimization & Defect Detection
-- ============================================================================
USE DATABASE SEMICONDUCTOR_YIELD;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.YIELD_INTELLIGENCE_AGENT
  COMMENT = 'Semiconductor Yield Optimization & Defect Detection AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'SEMICONDUCTOR_YIELD.APP.SEMICONDUCTOR_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'SEMICONDUCTOR_YIELD.SEARCH.PROCESS_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Semiconductor & Electronics Manufacturing information')
  )
  SYSTEM_PROMPT = 'You are the Yield Intelligence Agent for 12 semiconductor fabs in Penang/Kulim, Malaysia.';
