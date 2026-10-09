# Semiconductor Yield

**Malaysia - Wafer Fab Manufacturing**
Use case: Yield monitoring and excursion risk

> Yield monitoring for a synthetic fleet of 24 process tools across 5 Malaysian fab sites: dynamic tables, a holdout-evaluated excursion-risk classifier, a die-yield forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile die yield, defects and availability from RAW tool data, with checks in `run_core.py`
- **Excursion-risk classification** gives a holdout-evaluated next-7-day excursion probability per tool
- **Die-yield forecast** projects 14 days of fab-wide die yield with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.TOOLS` (24 rows) |
| Fact table | `RAW.TOOL_DAILY` (2,160 tool-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `EXCURSION_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.EXCURSION_RISK_SCORES`, `ML.EXCURSION_RISK_HOLDOUT_METRICS`, `ML.YIELD_FORECAST`, `ML.RF_DRIFT_ANOMALIES` |

Sites: Penang, Kulim, Melaka, Ipoh, Kuching.
Process steps: Lithography, Etch, Deposition, CMP, Ion Implant.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Die Yield | 93.5% |
| Yield Excursions | 152 |
| Defects per Wafer | 0.30 |
| Wafer Moves | 672,556 |
| Tool Availability | 99.1% |
| Tools Monitored | 24 |
| Chamber Kit Coverage | 47.0% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily die yield, die lost by root cause, tool table
2. Predictive: holdout metrics, risk bands, 14-day die-yield forecast, RF power drift anomalies
3. Tool Health: availability, chamber kit coverage, PM compliance against die yield, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Per-tool die yield ranges from 91.5% to 95.2%. Melaka is the lowest site, at 92.2%.
- Scratches cost the most die of the 10 excursion causes.
- The risk model is evaluated on a time-based holdout: precision 0.59 and recall 0.42 at 0.5, against a 0.26 base rate. Present it as triage, not a guarantee.
- Site-wide utility power dips are excluded from excursion labels, because they are not tool-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
