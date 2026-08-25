-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Semiconductor Yield Optimization & Defect Detection
-- ============================================================================
USE DATABASE SEMICONDUCTOR_YIELD;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_malaysia_semiconductor_yield_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: YIELD_CRITICAL_ALERT
CREATE OR REPLACE ALERT APP.YIELD_CRITICAL_ALERT
  WAREHOUSE = SEMI_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Yield below critical threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.FAB_YIELD_SUMMARY
  WHERE 1=1 -- Condition: AVG_YIELD_PCT < 85 for any fab
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_semiconductor_yield_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Semiconductor Yield Optimization & Defect Detection: Yield below critical threshold',
    'Yield below critical threshold'
  );

ALTER ALERT APP.YIELD_CRITICAL_ALERT RESUME;

-- Alert: EQUIPMENT_ALARM_ALERT
CREATE OR REPLACE ALERT APP.EQUIPMENT_ALARM_ALERT
  WAREHOUSE = SEMI_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Equipment alarm rate exceeding threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.FAB_YIELD_SUMMARY
  WHERE 1=1 -- Condition: ALARMS_48H > 10 for any equipment
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_semiconductor_yield_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Semiconductor Yield Optimization & Defect Detection: Equipment alarm rate exceeding threshold',
    'Equipment alarm rate exceeding threshold'
  );

ALTER ALERT APP.EQUIPMENT_ALARM_ALERT RESUME;

