----------------------------------------------------------------------------------------
--
-- File name:   datastreamOraDiag_collect_user_info.sql (2022-08-22)
--
-- Purpose:     Collect User data for Datastream Diagnosis
--
-- Author:      Shane Borden
--
-- Warning:     Requires a license for the Oracle Diagnostics Pack
--
---------------------------------------------------------------------------------------
--

SET TERM OFF ECHO OFF FEED OFF VER OFF HEA OFF PAGES 0 COLSEP '~' LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;

---------------------------------------------------------------------------------------

SPO datastream_diag_user_sys_privs_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL USERNAME FOR A130
COL PRIVILEGE FOR A40
COL ADMIN_OPTION FOR A3

-- header
SELECT 'USERNAME',
       'PRIVILEGE',
       'ADMIN_OPTION'
FROM 
  DUAL
/

-- data
SELECT
    USERNAME,
    PRIVILEGE,
    ADMIN_OPTION
FROM
    DBA_SYS_PRIVS
WHERE
  USERNAME = '&&dod_username.'
/

SPO OFF;
---------------------------------------------------------------------------------------
SPO datastream_diag_user_role_privs_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL GRANTED_ROLE FOR A130
COL DEFAULT_ROLE FOR A3

-- header
SELECT 'USERNAME',
       'GRANTED_ROLE',
       'ADMIN_OPTION',
       'DEFAULT_ROLE'
  FROM DUAL
/

-- data
SELECT
    USERNAME,
    GRANTED_ROLE,
    ADMIN_OPTION,
    DEFAULT_ROLE
FROM
    DBA_ROLE_PRIVS
WHERE
  USERNAME = '&&dod_username.'
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
