-- ============================================================================
-- Semiconductor Yield Optimization & Defect Detection
-- Real-time yield monitoring across 12 Malaysian fabs — Snowflake ML detects degradation, classifies defect patterns, forecasts equipment failures, and alerts process engineers before excursions cascade.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS SEMICONDUCTOR_YIELD;
CREATE WAREHOUSE IF NOT EXISTS SEMI_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE SEMICONDUCTOR_YIELD;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE SEMI_WH;
