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

SPO datastream_diag_user_sys_privs_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL GRANTEE FOR A130
COL PRIVILEGE FOR A40
COL ADMIN_OPTION FOR A3

-- header
SELECT 'GRANTEE',
       'PRIVILEGE',
       'ADMIN_OPTION'
FROM 
  DUAL
/

-- data
SELECT
    GRANTEE,
    PRIVILEGE,
    ADMIN_OPTION
FROM
    DBA_SYS_PRIVS
WHERE
  GRANTEE = '&&dod_username.'
/

SPO OFF;
---------------------------------------------------------------------------------------
SPO datastream_diag_user_role_privs_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL GRANTED_ROLE FOR A130
COL DEFAULT_ROLE FOR A3

-- header
SELECT 'GRANTEE',
       'GRANTED_ROLE',
       'ADMIN_OPTION',
       'DEFAULT_ROLE'
  FROM DUAL
/

-- data
SELECT
    GRANTEE,
    GRANTED_ROLE,
    ADMIN_OPTION,
    DEFAULT_ROLE
FROM
    DBA_ROLE_PRIVS
WHERE
  GRANTEE = '&&dod_username.'
/

SPO OFF;

---------------------------------------------------------------------------------------
SPO datastream_diag_user_tab_privs_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL GRANTEE FOR A130
COL OWNER FOR A35
COL TABLE_NAME FOR A35
COL GRANTOR FOR A130
COL PRIVILEGE FOR A45

-- header
SELECT 'GRANTEE',
       'OWNER',
       'TABLE_NAME',
       'GRANTOR',
       'PRIVILEGE'
  FROM DUAL
/

-- data
SELECT
    GRANTEE,
    SUBSTR(OWNER,1,30) OWNER,
    SUBSTR(TABLE_NAME,1,30) TABLE_NAME,
    GRANTOR,
    PRIVILEGE
FROM
    DBA_TAB_PRIVS
WHERE
  GRANTEE = '&&dod_username.'
/

---------------------------------------------------------------------------------------

SPO OFF;
SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;
