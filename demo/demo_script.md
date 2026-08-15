# Demo Script: Semiconductor Yield Optimization & Defect Detection
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake detects yield degradation across 12 fabs, classifies wafer defects with AI, forecasts equipment failures, and alerts engineers — all native SQL, no external ML platform needed"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Dr. Tan Wei Lin** | VP Manufacturing | React App (SPCS) | Yield trends, equipment uptime, capacity planning, cost of yield loss |
| **Ahmad bin Ismail** | Process Engineer | Amazon QuickSight | Defect root cause, equipment alarms, corrective actions, process parameter drift |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 8 tables | FABS (12), PRODUCTS (8), EQUIPMENT (120), WAFER_LOTS (5000), EQUIPMENT_TELEMETRY (500000), PROCESS_DOCUMENTS (80), WEATHER_PENANG (365), ASEAN_MACRO (8) |
| **CURATED** | 4 Dynamic Tables | FAB_YIELD_SUMMARY, YIELD_TIMESERIES, EQUIPMENT_HEALTH, DEFECT_PARETO |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE_MULTIMODAL, AI_CLASSIFY, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 80 documents indexed |
| **Agent** | YIELD_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

Malaysia's Penang-Kulim corridor is home to 12 semiconductor fabs producing chips for Intel, Infineon, Micron, and AMD. A 3.2% yield degradation across 4 fabs is costing RM 200M annually — but the root cause spans equipment drift, particle contamination, and process parameter changes that traditional monitoring tools detect too late.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "Two hundred million ringgit in annual yield loss across 12 fabs in the Penang-Kulim corridor."

**Action**: Point at the RM 200M yield loss KPI card

### [0:45–1:30] YIELD ANALYTICS

**Show**: Yield Analytics tab

> "FAB-002 running Intel's 7nm node — yield at 83.4%, thirteen points below target."

**Action**: Click FAB-002 in the fab list

### [1:30–2:15] EQUIPMENT HEALTH

**Show**: Equipment Health tab

> "Seventeen alarms in 48 hours. ML.FORECAST predicts three tools will exceed failure threshold within 72 hours."

**Action**: Point at equipment alarm table sorted by severity

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Dr. Tan doesn't write SQL. She asks: 'Which fab has the highest yield loss in ringgit?'"

**Action**: Type: 'Which fab has the highest yield loss in MYR?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Eight Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.ANOMALY_DETECTION on semiconductor yield** — Only demo using anomaly detection for wafer yield — not demand or financial data
2. **Cortex Complete (multimodal) for wafer images** — Only demo analyzing manufacturing images natively in Snowflake
3. **Equipment-to-yield correlation** — Connects IoT telemetry drift directly to yield loss via Dynamic Tables
4. **Malaysian semiconductor context** — RM 450B industry with Penang corridor-specific company names and fab data
5. **80 process documents classified + searchable** — AI_CLASSIFY + Cortex Search on semiconductor SOPs and ECNs
6. **AWS IoT Core + SageMaker vision** — Only demo combining IoT sensor ingestion with computer vision for manufacturing


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM SEMICONDUCTOR_YIELD.RAW.WAFER_LOTS` → 5000
- [ ] `SELECT COUNT(*) FROM SEMICONDUCTOR_YIELD.RAW.EQUIPMENT_TELEMETRY` → 500000
- [ ] `SELECT COUNT(DISTINCT FAB_ID) FROM SEMICONDUCTOR_YIELD.CURATED.FAB_YIELD_SUMMARY WHERE YIELD_STATUS = 'CRITICAL'` → 4

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM SEMICONDUCTOR_YIELD.ML.YIELD_FORECAST_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM SEMICONDUCTOR_YIELD.ML.YIELD_ANOMALY_RESULTS WHERE SERIES = 'FAB-002'` → >=5

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM SEMICONDUCTOR_YIELD.AI.DOC_CLASSIFICATION WHERE RISK_LEVEL = 'CRITICAL'` → ~12

