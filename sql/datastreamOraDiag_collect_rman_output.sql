----------------------------------------------------------------------------------------
--
-- File name:   datastreamOraDiag_collect_rman_output.sql (2022-08-22)
--
-- Purpose:     Collect ASH data for Datastream Diagnosis
--
-- Author:      Shane Borden
--
-- Warning:     Requires a license for the Oracle Diagnostics Pack
--
---------------------------------------------------------------------------------------
--

SET TERM OFF ECHO OFF FEED OFF VER OFF HEA OFF PAGES 0 COLSEP '~' LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;

---------------------------------------------------------------------------------------

SPO datastream_diag_rman_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL OUTPUT FOR A130

-- header
SELECT 'SID',
       'RECID',
       'STAMP',
       'SESSION_RECID',
       'SESSION_STAMP',
       'OUTPUT',
       'RMAN_STATUS_RECID',
       'RMAN_STATUS_STAMP',
       'SESSION_KEY'
  FROM DUAL
/

-- data
SELECT
    SID,
    RECID,
    STAMP,
    SESSION_RECID,
    SESSION_STAMP,
    OUTPUT,
    RMAN_STATUS_RECID,
    RMAN_STATUS_STAMP,
    SESSION_KEY
FROM
    V$RMAN_OUTPUT
/

SPO OFF;
---------------------------------------------------------------------------------------
SPO datastream_diag_rman_config_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL NAME FOR A65
COL VALUE FOR A200
-- header
SELECT 'NAME',
       'VALUE'
  FROM DUAL
/

-- data
SELECT
    NAME,
    TO_CHAR(SUBSTR(VALUE,1,200)) as VALUE
FROM
    V$RMAN_CONFIGURATION
/

---------------------------------------------------------------------------------------

SPO OFF;
SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;
