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

SPO datastream_diag_archive_log_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL NAME FOR A520
COL IS_RECOVERY_DEST_FILE FOR A3
COL COMPRESSED FOR A3
COL DICTIONARY_BEGIN FOR A3
COL DICTIONARY_END FOR A3
COL STATUS FOR A1
COL DELETED FOR A3
COL APPLIED FOR A9
COL ARCHIVED FOR A3
COL STANDBY_DEST FOR A3
COL CREATOR FOR A7
COL REGISTRAR FOR A7
COL FIRST_TIME FOR A22
COL NEXT_TIME FOR A22
COL COMPLETION_TIME FOR A22

-- header
SELECT 'RECID',
       'STAMP',
       'NAME',
       'DEST_ID',
       'THREAD#',
       'SEQUENCE#',
       'FIRST_CHANGE#',
       'FIRST_TIME',
       'NEXT_CHANGE#',
       'NEXT_TIME',
       'BLOCKS',
       'BLOCK_SIZE',
       'CREATOR',
       'REGISTRAR',
       'STANDBY_DEST',
       'ARCHIVED',
       'APPLIED',
       'DELETED',
       'STATUS',
       'COMPLETION_TIME',
       'DICTIONARY_BEGIN',
       'DICTIONARY_END',
       'BACKUP_COUNT',
       'ARCHIVAL_THREAD#',
       'ACTIVATION#',
       'IS_RECOVERY_DEST_FILE',
       'COMPRESSED'
  FROM DUAL
/

-- data
SELECT
    RECID,
    STAMP,
    NAME,
    DEST_ID,
    THREAD#,
    SEQUENCE#,
    FIRST_CHANGE#,
    TO_CHAR(FIRST_TIME,'&&dod_date_format.') as FIRST_TIME,
    NEXT_CHANGE#,
    TO_CHAR(NEXT_TIME,'&&dod_date_format.') as NEXT_TIME,
    BLOCKS,
    BLOCK_SIZE,
    CREATOR,
    REGISTRAR,
    STANDBY_DEST,
    ARCHIVED,
    APPLIED,
    DELETED,
    STATUS,
    TO_CHAR(COMPLETION_TIME,'&&dod_date_format.') as COMPLETION_TIME,
    DICTIONARY_BEGIN,
    DICTIONARY_END,
    BACKUP_COUNT,
    ARCHIVAL_THREAD#,
    ACTIVATION#,
    IS_RECOVERY_DEST_FILE,
    COMPRESSED
FROM
    V$ARCHIVED_LOG
ORDER BY
    COMPLETION_TIME
/
SPO OFF;

---------------------------------------------------------------------------------------

COL STATUS FOR A16

SPO datastream_diag_redo_log_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

SELECT 'GROUP#',
       'THREAD#',
       'SEQUENCE#',
       'BYTES',
       'BLOCKSIZE',
       'MEMBERS',
       'ARCHIVED',
       'STATUS',
       'FIRST_CHANGE#',
       'FIRST_TIME',
       'NEXT_CHANGE#',
       'NEXT_TIME'
FROM DUAL
/

SELECT
    GROUP#,
    THREAD#,
    SEQUENCE#,
    BYTES,
    BLOCKSIZE,
    MEMBERS,
    ARCHIVED,
    STATUS,
    FIRST_CHANGE#,
    TO_CHAR(FIRST_TIME,'&&dod_date_format.') AS FIRST_TIME,
    NEXT_CHANGE#,
    TO_CHAR(NEXT_TIME,'&&dod_date_format.') AS NEXT_TIME
FROM
    V$LOG
/

---------------------------------------------------------------------------------------

SPO OFF;
SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;
