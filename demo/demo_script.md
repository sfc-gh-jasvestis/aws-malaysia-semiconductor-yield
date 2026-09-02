# Semiconductor Yield Optimization & Defect Detection

**Malaysia - Semiconductor & Electronics Manufacturing**
Use case: Yield Optimization

> Real-time yield monitoring across 12 Malaysian fabs — Snowflake ML detects degradation, classifies defect patterns, forecasts equipment failures, and alerts process engineers before excursions cascade.

## Why Snowflake

Snowflake detects yield degradation across 12 fabs, classifies wafer defects with AI, forecasts equipment failures, and alerts engineers — all native SQL, no external ML platform needed

- **ML.ANOMALY_DETECTION on semiconductor yield** - Only demo using anomaly detection for wafer yield — not demand or financial data
- **Cortex Complete (multimodal) for wafer images** - Only demo analyzing manufacturing images natively in Snowflake
- **Equipment-to-yield correlation** - Connects IoT telemetry drift directly to yield loss via Dynamic Tables
- **Malaysian semiconductor context** - RM 450B industry with Penang corridor-specific company names and fab data
- **80 process documents classified + searchable** - AI_CLASSIFY + Cortex Search on semiconductor SOPs and ECNs
- **AWS IoT Core + SageMaker vision** - Only demo combining IoT sensor ingestion with computer vision for manufacturing

## What is deployed

| | |
|---|---|
| Database | `MY_SEMICONDUCTOR_YIELD` |
| Service | `MY_SEMICONDUCTOR_YIELD_APP` |
| Compute pool | `SEA_DEMOS_MALAYSIA_POOL` |
| Dimension table | `RAW.PRODUCTS` (20 rows) |
| Fact table | `RAW.EQUIPMENT_TELEMETRY` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | MYR (RM) |

Regions in play: Selangor, Johor, Penang, Sabah, Sarawak
Segments: Particle Defect, Scratch, Pattern Defect, Edge Defect

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh MY_SEMICONDUCTOR_YIELD
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Wafer Yield (Avg) | `94.2%` | average per event |
| Die Yield | `87.8%` | average per event |
| Defect Density | `0.12/cm²` | average per event |
| Wafers Processed (MTD) | `42K` | total across Products |
| Killer Defect Rate | `2.1%` | average per event |
| Inline Pass Rate | `98.7%` | average per event |
| DPPM | `84` | average per event |


## Demo flow

1. Executive Cockpit
2. Yield Analytics
3. Equipment Health
4. Ask AI
5. Architecture & Data

## Talking points

- **RM 200M** - annual yield loss across 12 fabs (US$47M)
- **4 of 12 fabs** - below target yield (CRITICAL status)
- **17 equipment alarms** - in the last 48 hours
- **7 of 14 days** - anomalous for FAB-002 (ML.ANOMALY_DETECTION)
- **2,847 defects** - classified by Cortex AI
- **12 process documents** - flagged CRITICAL by AI classification
- **3 tools** - predicted to fail within 72 hours (ML.FORECAST)

## Business impact

- Malaysia semiconductor exports reached RM 450B (US$98B) in 2023, representing 18.4% of GDP (MIDA)
- AI-powered yield optimization improves fab yield 2-5% — worth $50-100M annually per fab (McKinsey Semiconductors)
- Predictive maintenance in semiconductor fabs reduces unplanned downtime by 30-50% (Deloitte Smart Factory)
- Yamaha Motor achieved real-time manufacturing intelligence on Snowflake (Snowflake Customers)

---
Generated from `generator/demo_specs/aws-malaysia-semiconductor-yield.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-malaysia-semiconductor-yield` instead.
