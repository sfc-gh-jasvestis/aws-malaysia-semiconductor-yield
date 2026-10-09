-- Synthetic tool-day observations for wafer-fab process tools. Nothing is seeded
-- as a prediction. Randomness is HASH-seeded, so every rebuild is reproducible:
-- per-tool age and excursion propensity, chamber wear between PM visits, missed
-- PM, category-weighted excursion causes, and two site-wide power dips.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.TOOLS AS
WITH tools AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS TOOL_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 24))
), draws AS (
  SELECT TOOL_INDEX,
         MOD(ABS(HASH(TOOL_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(TOOL_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(TOOL_INDEX, 'pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(TOOL_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(TOOL_INDEX, 'die')), 1000000) / 1e6 AS U_DIE
  FROM tools
)
SELECT 'TL-' || LPAD(TOOL_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic tool ' || LPAD(TOOL_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (8 and 5 are coprime): every site and step is present,
       -- with Penang the largest site as in the real corridor.
       CASE MOD(TOOL_INDEX, 8) WHEN 0 THEN 'Penang' WHEN 1 THEN 'Penang' WHEN 2 THEN 'Penang'
            WHEN 3 THEN 'Kulim' WHEN 4 THEN 'Kulim' WHEN 5 THEN 'Melaka' WHEN 6 THEN 'Ipoh'
            ELSE 'Kuching' END AS REGION,
       CASE MOD(TOOL_INDEX, 5) WHEN 0 THEN 'Lithography' WHEN 1 THEN 'Etch'
            WHEN 2 THEN 'Deposition' WHEN 3 THEN 'CMP' ELSE 'Ion Implant' END AS CATEGORY,
       TOOL_INDEX,
       ROUND(1 + U_AGE * 14, 1) AS AGE_YEARS,
       -- Base daily excursion probability 0.4%-3%; ~15% of tools are chronic offenders (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_EXCURSION_RATE,
       7 * (1 + FLOOR(U_PM * 3)) AS PM_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS PM_COMPLETION_PROB,
       ROUND(420 + U_DIE * 240) AS GROSS_DIE_PER_WAFER,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.TOOL_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), power_dips AS (
  -- Two site-wide utility power dips in the window.
  SELECT * FROM VALUES (27, 'Kulim', 3.5), (64, 'Penang', 2.0) AS o(DAY_INDEX, REGION, HOURS)
), base AS (
  SELECT t.ID AS ENTITY_ID, t.TOOL_INDEX, t.CATEGORY, t.REGION, t.AGE_YEARS,
         t.BASE_EXCURSION_RATE, t.PM_INTERVAL_DAYS, t.PM_COMPLETION_PROB, t.GROSS_DIE_PER_WAFER,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         24.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + t.TOOL_INDEX * 5, t.PM_INTERVAL_DAYS) AS DAYS_SINCE_PM,
         MOD(ABS(HASH(t.ID, d.DAY_INDEX, 'exc')), 1000000) / 1e6 AS U_EXC,
         MOD(ABS(HASH(t.ID, d.DAY_INDEX, 'down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(t.ID, d.DAY_INDEX, 'cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(t.ID, d.DAY_INDEX, 'pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(t.ID, d.DAY_INDEX, 'wafers')), 1000000) / 1e6 AS U_WAFERS,
         MOD(ABS(HASH(t.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(t.ID, d.DAY_INDEX, 'hit')), 1000000) / 1e6 AS U_HIT,
         p.HOURS AS DIP_HOURS
  FROM RAW.TOOLS t CROSS JOIN days d
  LEFT JOIN power_dips p ON p.DAY_INDEX = d.DAY_INDEX AND p.REGION = t.REGION
), pm AS (
  SELECT *,
         IFF(DAYS_SINCE_PM = 0, 1, 0) AS PM_DUE,
         IFF(DAYS_SINCE_PM = 0 AND U_PMDONE < PM_COMPLETION_PROB, 1, 0) AS PM_COMPLETED,
         -- Chamber wear rises between PM visits; weak PM discipline carries wear over.
         DAYS_SINCE_PM / PM_INTERVAL_DAYS + (1 - PM_COMPLETION_PROB) AS WEAR
  FROM base
), excursions AS (
  SELECT *,
         CASE WHEN DIP_HOURS IS NOT NULL THEN 1
              WHEN U_EXC < LEAST(0.5, BASE_EXCURSION_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 25)) / 4 THEN 2
              WHEN U_EXC < LEAST(0.5, BASE_EXCURSION_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 25)) THEN 1
              ELSE 0 END AS EXCURSION_COUNT
  FROM pm
), timed AS (
  SELECT *,
         -- Tool-down hours for containment: exponential, mean depends on step.
         CASE WHEN EXCURSION_COUNT = 0 THEN 0.0
              WHEN DIP_HOURS IS NOT NULL THEN DIP_HOURS
              ELSE LEAST(20.0, ROUND(EXCURSION_COUNT * (0.5 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Lithography' THEN 4.0 WHEN 'Etch' THEN 3.5
                                 WHEN 'Deposition' THEN 3.0 WHEN 'CMP' THEN 2.0 ELSE 2.5 END), 1))
         END AS DOWNTIME_HOURS
  FROM excursions
), output AS (
  SELECT *,
         PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
         ROUND((PLANNED_HOURS - DOWNTIME_HOURS) * (10 + U_WAFERS * 6)) AS WAFERS,
         -- Die yield: base by step, minus wear, minus the excursion hit.
         LEAST(0.99, GREATEST(0.55,
           CASE CATEGORY WHEN 'Lithography' THEN 0.955 WHEN 'Etch' THEN 0.962
                         WHEN 'Deposition' THEN 0.968 WHEN 'CMP' THEN 0.972 ELSE 0.965 END
           - 0.025 * WEAR - 0.004 * AGE_YEARS / 14 - 0.006 * U_NOISE
           - EXCURSION_COUNT * (0.06 + 0.10 * U_HIT))) AS DIE_YIELD
  FROM timed
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS, OPERATING_HOURS,
       EXCURSION_COUNT,
       CASE WHEN EXCURSION_COUNT = 0 THEN 'None'
            WHEN DIP_HOURS IS NOT NULL THEN 'Utility power dip'
            WHEN CATEGORY = 'Lithography' THEN IFF(U_CAUSE < 0.55, 'Focus drift', IFF(U_CAUSE < 0.85, 'Overlay error', 'Particle contamination'))
            WHEN CATEGORY = 'Etch' THEN IFF(U_CAUSE < 0.5, 'Chamber drift', IFF(U_CAUSE < 0.8, 'Particle contamination', 'Endpoint failure'))
            WHEN CATEGORY = 'Deposition' THEN IFF(U_CAUSE < 0.5, 'Film thickness drift', IFF(U_CAUSE < 0.85, 'Particle contamination', 'Chamber drift'))
            WHEN CATEGORY = 'CMP' THEN IFF(U_CAUSE < 0.6, 'Scratch', 'Pad wear')
            ELSE IFF(U_CAUSE < 0.6, 'Dose drift', 'Beam instability') END AS ROOT_CAUSE,
       PM_DUE, PM_COMPLETED,
       WAFERS,
       WAFERS * GROSS_DIE_PER_WAFER AS GROSS_DIE,
       FLOOR(WAFERS * GROSS_DIE_PER_WAFER * DIE_YIELD) AS GOOD_DIE,
       ROUND(WAFERS * (0.08 + 0.18 * WEAR + 1.4 * EXCURSION_COUNT + 0.05 * U_NOISE)) AS DEFECT_COUNT,
       ROUND(0.6 + 2.2 * WEAR + 2.5 * EXCURSION_COUNT + U_NOISE * 0.6, 2) AS RF_DRIFT_PCT,
       ROUND(62 + 5 * WEAR + 4 * EXCURSION_COUNT + U_NOISE * 2, 1) AS CHAMBER_TEMP_C,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM output;

-- Chamber kit and consumable coverage per tool (snapshot).
CREATE TABLE RAW.SPARE_PARTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Lithography' THEN 'Reticle stage kit' WHEN 'Etch' THEN 'Chamber liner kit'
                     WHEN 'Deposition' THEN 'Showerhead' WHEN 'CMP' THEN 'Polishing pad'
                     ELSE 'Ion source' END AS PART_TYPE,
       1 + MOD(ABS(HASH(ID, 'req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'hand')), 5) AS ON_HAND_QTY,
       IFF(MOD(ABS(HASH(ID, 'hand')), 5) < 1 + MOD(ABS(HASH(ID, 'req')), 4),
           MOD(ABS(HASH(ID, 'order')), 3), 0) AS ON_ORDER_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.TOOLS;
