-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes validated __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TELEMETRY.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic process-engineering knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.PROCESS_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, t.CATEGORY
  FROM RAW.TOOL_DAILY r JOIN RAW.TOOLS t ON t.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.EXCURSION_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' excursion response' AS TITLE,
  'Synthetic demo SOP. Process step: ' || CATEGORY || '. Excursion cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: place the tool on hold, quarantine in-process lots and notify the area process engineer. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%focus%' OR ROOT_CAUSE ILIKE '%overlay%' THEN 'run the focus-exposure and overlay qualification wafers and compare against the last good baseline.'
       WHEN ROOT_CAUSE ILIKE '%particle%' THEN 'run a particle monitor wafer, inspect the chamber and wafer handler, and perform a wet clean if counts exceed the control limit.'
       WHEN ROOT_CAUSE ILIKE '%chamber%' OR ROOT_CAUSE ILIKE '%endpoint%' THEN 'check RF power, chamber pressure and endpoint traces against the golden recipe and season the chamber.'
       WHEN ROOT_CAUSE ILIKE '%film%' THEN 'measure film thickness on monitor wafers at 49 points and adjust deposition time within the recipe window.'
       WHEN ROOT_CAUSE ILIKE '%scratch%' OR ROOT_CAUSE ILIKE '%pad%' THEN 'inspect the polishing pad, conditioner disk and slurry flow; replace the pad if wear exceeds tolerance.'
       WHEN ROOT_CAUSE ILIKE '%dose%' OR ROOT_CAUSE ILIKE '%beam%' THEN 'verify dose and beam current with a monitor wafer and retune the ion source.'
       WHEN ROOT_CAUSE ILIKE '%power%' THEN 'confirm facility power status, check UPS logs and re-qualify the tool before release.'
       ELSE 'inspect the affected module, record readings and escalate to the module engineer if readings are out of tolerance.'
     END
  || ' Step 3: if RF power drift exceeds 5% or chamber temperature exceeds 75 C after recovery, keep the tool on hold. '
  || 'Step 4: disposition the quarantined lots and record the root cause in the fab MES.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.PROCESS_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.PROCESS_DOCS);

-- ---------- RF power drift anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.RF_DRIFT_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, RF_DRIFT_PCT::FLOAT AS RF_DRIFT
FROM RAW.TOOL_DAILY;
CREATE OR REPLACE VIEW ML.RF_DRIFT_TRAIN AS
SELECT * FROM ML.RF_DRIFT_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.RF_DRIFT_SERIES);
CREATE OR REPLACE VIEW ML.RF_DRIFT_DETECT AS
SELECT * FROM ML.RF_DRIFT_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.RF_DRIFT_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.RF_DRIFT_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.RF_DRIFT_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'RF_DRIFT',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.RF_DRIFT_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS RF_DRIFT, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.RF_DRIFT_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.RF_DRIFT_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'RF_DRIFT'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.YIELD_ANALYTICS
  TABLES (
    tools AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per process tool, 90-day totals',
    risk AS ML.EXCURSION_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day yield excursion probability per tool',
    causes AS CURATED.EXCURSION_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Yield excursions by root cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Fab-wide totals per day'
  )
  RELATIONSHIPS (risk_tool AS risk (ENTITY_ID) REFERENCES tools)
  FACTS (
    tools.good_die_f AS GOOD_DIE,
    tools.gross_die_f AS GROSS_DIE,
    tools.wafers_f AS WAFERS,
    tools.defects_f AS DEFECT_COUNT,
    tools.excursions_f AS EXCURSION_COUNT,
    tools.downtime_hours_f AS DOWNTIME_HOURS,
    tools.operating_hours_f AS OPERATING_HOURS,
    tools.planned_hours_f AS PLANNED_HOURS,
    risk.excursion_prob_f AS EXCURSION_PROB_7D,
    causes.cause_excursions_f AS EXCURSION_COUNT,
    causes.cause_lost_die_f AS LOST_DIE,
    causes.cause_hours_f AS DOWNTIME_HOURS,
    daily.day_good_die_f AS GOOD_DIE,
    daily.day_gross_die_f AS GROSS_DIE,
    daily.day_excursions_f AS EXCURSION_COUNT
  )
  DIMENSIONS (
    tools.tool_id AS ENTITY_ID WITH SYNONYMS = ('tool', 'equipment id'),
    tools.tool_name AS ENTITY_NAME,
    tools.site AS REGION WITH SYNONYMS = ('fab', 'fab site', 'region') COMMENT = 'Malaysian fab site',
    tools.process_step AS CATEGORY WITH SYNONYMS = ('step', 'tool type', 'module'),
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    tools.die_yield_pct AS 100 * SUM(tools.good_die_f) / NULLIF(SUM(tools.gross_die_f), 0)
      COMMENT = 'Good die / gross die',
    tools.yield_excursions AS SUM(tools.excursions_f) WITH SYNONYMS = ('excursions', 'yield events'),
    tools.defects_per_wafer AS SUM(tools.defects_f) / NULLIF(SUM(tools.wafers_f), 0),
    tools.wafer_moves AS SUM(tools.wafers_f),
    tools.tool_availability_pct AS 100 * SUM(tools.operating_hours_f) / NULLIF(SUM(tools.planned_hours_f), 0),
    tools.total_downtime_hours AS SUM(tools.downtime_hours_f),
    risk.avg_excursion_prob AS AVG(risk.excursion_prob_f),
    causes.cause_excursions AS SUM(causes.cause_excursions_f),
    causes.cause_lost_die AS SUM(causes.cause_lost_die_f),
    causes.cause_downtime_hours AS SUM(causes.cause_hours_f),
    daily.daily_die_yield_pct AS 100 * SUM(daily.day_good_die_f) / NULLIF(SUM(daily.day_gross_die_f), 0),
    daily.daily_excursions AS SUM(daily.day_excursions_f)
  )
  COMMENT = 'Synthetic Malaysia wafer-fab yield analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.YIELD_AGENT
  COMMENT = 'Yield assistant over a synthetic Malaysian wafer-fab tool fleet'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give tool IDs and numbers with units."
  orchestration: "Use yield_analyst for die yield, excursions, defects, tools, sites, risk and root causes. Use sop_search for excursion response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: yield_analyst
      description: "Die yield, yield excursions, defects per wafer, tool availability, root causes and excursion-risk scores"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic excursion-response SOPs by process step and cause"
tool_resources:
  yield_analyst:
    semantic_view: __DEMO_DB__.APP.YIELD_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.PROCESS_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), TOOL_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, RF_DRIFT_PCT FLOAT, CHAMBER_TEMP_C FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION MY_SEMI_YIELD_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (TOOL_ID, EVENT_TS, RF_DRIFT_PCT, CHAMBER_TEMP_C, SOP_HINT)
    SELECT t.TOOL_ID, t.EVENT_TS, t.RF_DRIFT_PCT, t.CHAMBER_TEMP_C,
           'Check ' || tl.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.TOOLS tl ON tl.ID = t.TOOL_ID
    LEFT JOIN ML.EXCURSION_RISK_SCORES r ON r.ENTITY_ID = t.TOOL_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.TOOL_ID = t.TOOL_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('MY_SEMI_YIELD_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Malaysia fab tool alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.TOOL_ID = t.TOOL_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.EXCURSION_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.EXCURSION_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.EXCURSION_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.EXCURSION_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'RF_DRIFT_PCT', RF_DRIFT_PCT,
             'CHAMBER_TEMP_C', CHAMBER_TEMP_C, 'RF_DRIFT_7D', RF_DRIFT_7D, 'EXCURSIONS_30D', EXCURSIONS_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:EXCURSION::FLOAT, 4) AS EXCURSION_PROB_7D,
         CASE WHEN PRED:probability:EXCURSION::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:EXCURSION::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
