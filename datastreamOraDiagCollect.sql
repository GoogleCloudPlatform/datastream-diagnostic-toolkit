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

----------------------------------------------------------------------------------------
--
-- File name:   datastreamOraDiagCollect.sql (2022-08-22)
--
-- Purpose:     Collect Diag Information for Datastream (CPU, Memory, Disk and IO Perf, Alert Log, Rman Information)
--
-- Author:      Shane Borden
--
-- Usage:       Collects Requirements from AWR and ASH views on databases with the
--				Oracle Diagnostics Pack license
--
--              The output of this script can be used to diagnose issues with Datastream
--
-- Example:     # cd datastream-diagnostic-toolkit
--              # sqlplus / as sysdba
--              SQL> START sql/datastreamOraDiagCollect.sql
--
--  Notes:      Developed and tested on 11g,12c,19c
--
---------------------------------------------------------------------------------------
*/

SET TERM ON;
PRO Executing datastream_oracle_diag
PRO Please wait ...

SET ECHO OFF FEED OFF VER OFF
DEF dod_date_format = 'YYYY-MM-DD HH24:MI';
ALTER SESSION SET NLS_DATE_FORMAT = '&&dod_date_format.';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = '&&dod_date_format.';

-- set the collection date
COL dod_coll_date_from_yyyy_mm_dd_hh24_mi NEW_V dod_coll_date_from_yyyy_mm_dd_hh24_mi;
COL dod_coll_date_to_yyyy_mm_dd_hh24_mi NEW_V dod_coll_date_to_yyyy_mm_dd_hh24_mi;
COL dod_username NEW_V dod_username;

PRO Set the from collection date (required - format YYYY-MM-DD HH24:MI)
SELECT TO_CHAR(TO_DATE('&dod_coll_date_from_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI')) dod_coll_date_from_yyyy_mm_dd_hh24_mi FROM DUAL;
PRO Set the to collection date (required - format YYYY-MM-DD HH24:MI)
SELECT TO_CHAR(TO_DATE('&dod_coll_date_to_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI')) dod_coll_date_to_yyyy_mm_dd_hh24_mi FROM DUAL;
PRO Enter the Datastream Username (required)
SELECT '&dod_username.' dod_username FROM DUAL;

SET TERM OFF ECHO OFF FEED OFF VER OFF HEA OFF PAGES 0 COLSEP '~' LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;

DEF v_object_prefix = 'v$';

ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
ALTER SESSION SET NLS_SORT = 'BINARY';
ALTER SESSION SET NLS_COMP = 'BINARY';

DEF dod_collection_yyyymmdd = '';
COL dod_collection_yyyymmdd NEW_V dod_collection_yyyymmdd FOR A8;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') dod_collection_yyyymmdd FROM DUAL;

DEF dod_collection_yyyymmdd_hhmi = '';
COL dod_collection_yyyymmdd_hhmi NEW_V dod_collection_yyyymmdd_hhmi FOR A13;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HHMI') dod_collection_yyyymmdd_hhmi FROM DUAL;

-- get host name (up to 30, stop before first '.', no special characters)
DEF dod_host_name_short = '';
COL dod_host_name_short NEW_V dod_host_name_short FOR A30;
SELECT LOWER(SUBSTR(SYS_CONTEXT('USERENV', 'SERVER_HOST'), 1, 30)) dod_host_name_short FROM DUAL;
SELECT SUBSTR('&&dod_host_name_short.', 1, INSTR('&&dod_host_name_short..', '.') - 1) dod_host_name_short FROM DUAL;
SELECT TRANSLATE('&&dod_host_name_short.',
'abcdefghijklmnopqrstuvwxyz0123456789-_ ''`~!@#$%&*()=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'abcdefghijklmnopqrstuvwxyz0123456789-_') dod_host_name_short FROM DUAL;

-- get database name (up to 10, stop before first '.', no special characters)
COL dod_dbname_short NEW_V dod_dbname_short FOR A10;
SELECT LOWER(SUBSTR(SYS_CONTEXT('USERENV', 'DB_NAME'), 1, 10)) dod_dbname_short FROM DUAL;
SELECT SUBSTR('&&dod_dbname_short.', 1, INSTR('&&dod_dbname_short..', '.') - 1) dod_dbname_short FROM DUAL;
SELECT TRANSLATE('&&dod_dbname_short.',
'abcdefghijklmnopqrstuvwxyz0123456789-_ ''`~!@#$%&*()=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'abcdefghijklmnopqrstuvwxyz0123456789-_') dod_dbname_short FROM DUAL;

-- get dbid
COL dod_this_dbid NEW_V dod_this_dbid;
SELECT 'get_dbid', TO_CHAR(dbid) dod_this_dbid FROM &&v_object_prefix.database
/

-- get rdbms version
COL db_version NEW_V db_version;
SELECT version db_version FROM &&v_object_prefix.instance;

-- AWR collector
@@sql/datastreamOraDiag_collect_ash.sql
@@sql/datastreamOraDiag_collect_lsnr_log.sql
@@sql/datastreamOraDiag_collect_rdbms_log.sql
@@sql/datastreamOraDiag_collect_rman_output.sql
@@sql/datastreamOraDiag_collect_archive_log.sql
@@sql/datastreamOraDiag_collect_system_under_observation.sql
@@sql/datastreamOraDiag_collect_user_info.sql
@@sql/datastreamOraDiag_collect_supplemental_logging.sql
@@sql/datastreamOraDiag_comprehensive_db_check.sql

-- zip datastream diag output
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_ash_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_lsnr_log_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_rdbms_log_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_rman_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_rman_config_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_archive_log_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_redo_log_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_system_under_observation_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_patchset_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_user_sys_privs_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_user_role_privs_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_user_tab_privs_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_initparams_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_collect_supp_schema_logging_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_collect_supp_table_logging_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;
HOS zip -qmj datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip datastream_diag_comprehensive_db_check_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..txt;


SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;
PRO
PRO Generated datastream_diag_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..zip
PRO
