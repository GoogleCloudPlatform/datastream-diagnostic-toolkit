/* 
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

SET TERM OFF ECHO OFF FEED OFF VER OFF HEA OFF PAGES 0 COLSEP '~' LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;

---------------------------------------------------------------------------------------

SPO datastream_diag_collect_supp_schema_logging_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL SCHEMA_NAME FOR A130
COL ALLKEY_SUPLOG FOR A5
COL ALLOW_NOVALIDATE_PK FOR A5

-- header
SELECT 'SCHEMA_NAME',
       'ALLKEY_SUPLOG',
       'ALLOW_NOVALIDATE_PK'
  FROM DUAL
/

-- data
SELECT
    SCHEMA_NAME,
    ALLKEY_SUPLOG,
    ALLOW_NOVALIDATE_PK
FROM
    SYS.LOGMNR$SCHEMA_ALLKEY_SUPLOG
WHERE
  SCHEMA_NAME IN (SELECT DISTINCT OWNER FROM DBA_SEGMENTS) ORDER BY 1
/

SPO OFF;

---------------------------------------------------------------------------------------

SPO datastream_diag_collect_supp_table_logging_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL OWNER FOR A130
COL LOG_GROUP_NAME FOR A130
COL TABLE_NAME FOR A130
COL LOG_GROUP_TYPE FOR A20
COL ALWAYS FOR A12
COL GENERATED FOR A14

-- header
SELECT 'OWNER',
       'LOG_GROUP_NAME',
       'TABLE_NAME',
       'LOG_GROUP_TYPE',
       'ALWAYS',
       'GENERATED'
  FROM DUAL
/

-- data
SELECT
    OWNER,
    LOG_GROUP_NAME,
    TABLE_NAME,
    LOG_GROUP_TYPE,
    ALWAYS,
    GENERATED
FROM
    DBA_LOG_GROUPS
ORDER BY 1,2
/

---------------------------------------------------------------------------------------

SPO OFF;
SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;