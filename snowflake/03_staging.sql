-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.RIG_DAILY
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.RIG_DAILY observation
    LEFT JOIN RAW.RIGS rig ON rig.ID = observation.ENTITY_ID
    WHERE rig.ID IS NULL OR observation.PLANNED_HOURS <= 0
       OR observation.PRODUCTIVE_HOURS < 0 OR observation.NPT_HOURS < 0
       OR observation.PRODUCTIVE_HOURS + observation.NPT_HOURS <> observation.PLANNED_HOURS
       OR observation.CHECKS_IN_SPEC < 0 OR observation.CHECKS_IN_SPEC > observation.MUD_CHECKS
       OR observation.METRES_DRILLED < 0 OR observation.KICKS < 0 OR observation.FUEL_M3 < 0
       OR observation.BOP_TEST_DONE > observation.BOP_TEST_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
