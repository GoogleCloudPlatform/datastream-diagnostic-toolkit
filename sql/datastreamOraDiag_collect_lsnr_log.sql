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

SPO datastream_diag_lsnr_log_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL ORIGINATING_TIMESTAMP FOR A21;
COL INST_ID FOR 999;
COL HOST_ID FOR A67;
COL HOST_ADDRESS FOR A49;
COL DETAILED_LOCATION FOR A163;
COL MODULE_ID FOR A67;
COL CLIENT_ID FOR A67;
COL PROCESS_ID FOR A35;
COL USER_ID FOR A30;
COL MESSAGE_ID FOR A67;
COL MESSAGE_GROUP FOR A67;
COL MESSAGE_TEXT FOR A500;

-- header
SELECT 'ORIGINATING_TIMESTAMP',
       'INST_ID',
       'HOST_ID',
       'HOST_ADDRESS',
       'DETAILED_LOCATION',
       'MODULE_ID',
       'CLIENT_ID',
       'PROCESS_ID',
       'USER_ID',
       'MESSAGE_ID',
       'MESSAGE_GROUP',
       'MESSAGE_TEXT'
  FROM DUAL
/

-- data
SELECT
    TO_CHAR(originating_timestamp,'&&dod_date_format.') as originating_timestamp,
    host_id,
    host_address,
    detailed_location,
    module_id,
    client_id,
    process_id,
    SUBSTR(user_id,1,30) as user_id,
    message_id,
    message_group,
    SUBSTR(message_text,1,500) as message_text,
    filename
FROM
    V$DIAG_ALERT_EXT
WHERE
    TRIM(component_id) = 'tnslsnr'
    AND originating_timestamp BETWEEN TRUNC(NVL(TO_DATE('&&dod_coll_date_from_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI'), sysdate -(1 / 24 / 30)))
        AND TRUNC(NVL(TO_DATE('&&dod_coll_date_to_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI') + 1, sysdate +1))
ORDER BY
    originating_timestamp
/


---------------------------------------------------------------------------------------

SPO OFF;
SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;
