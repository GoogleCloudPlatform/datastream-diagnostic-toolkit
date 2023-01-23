/*
Copyright 2023 Google LLC

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

SET SERVEROUTPUT ON TERM OFF ECHO OFF FEED OFF VER OFF HEA OFF PAGES 0 LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;

---------------------------------------------------------------------------------------

SPO datastream_diag_user_fixup_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..sql;

DECLARE
    v_user_count number;
    v_version number;
    v_permission_count number;
BEGIN
    SELECT count(1) into v_user_count from dba_users where username = UPPER('&&dod_username.');
    SELECT to_number(substr(version,1,instr(version,'.',1)-1)) into v_version from v$instance;
    IF v_user_count = 0
    THEN
        dbms_output.put_line('/* User Missing use the following code to create the proper user */');
        dbms_output.put_line('');
        dbms_output.put_line('');
        dbms_output.put_line('CREATE USER &&dod_username. IDENTIFIED BY [password] DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP PROFILE DEFAULT;');
        dbms_output.put_line('GRANT EXECUTE_CATALOG_ROLE TO &&dod_username.;');
        dbms_output.put_line('GRANT CONNECT TO &&dod_username.;');
        dbms_output.put_line('GRANT CREATE SESSION TO &&dod_username.;');
        dbms_output.put_line('GRANT SELECT ON SYS.V_$DATABASE TO &&dod_username.;');
        dbms_output.put_line('GRANT SELECT ON SYS.V_$ARCHIVED_LOG TO &&dod_username.;');
        dbms_output.put_line('GRANT SELECT ON SYS.V_$LOGMNR_CONTENTS TO &&dod_username.;');
        dbms_output.put_line('GRANT EXECUTE ON DBMS_LOGMNR TO &&dod_username.;');
        dbms_output.put_line('GRANT EXECUTE ON DBMS_LOGMNR_D TO &&dod_username.;');
        dbms_output.put_line('GRANT SELECT ANY TRANSACTION TO &&dod_username.;');
        dbms_output.put_line('GRANT SELECT ANY TABLE TO &&dod_username.;');
        IF v_version >= 12 THEN
            dbms_output.put_line('GRANT LOGMINING TO &&dod_username.;');
        END IF;
        dbms_output.put_line('');
        dbms_output.put_line('');
        dbms_output.put_line('/* ---------------------------------------------------------- */');
    ELSE
        dbms_output.put_line('/* User Missing the following permissions */');
        dbms_output.put_line('');
        dbms_output.put_line('');
        SELECT count(1) into v_permission_count from dba_role_privs where GRANTEE = UPPER('&&dod_username.') and GRANTED_ROLE = 'EXECUTE_CATALOG_ROLE';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT EXECUTE_CATALOG_ROLE TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_role_privs where GRANTEE = UPPER('&&dod_username.') and GRANTED_ROLE = 'CONNECT';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT CONNECT TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_sys_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'CREATE SESSION';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT CREATE SESSION TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_sys_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'LOGMINING';
        IF v_permission_count = 0 and v_version >= 12 THEN
            dbms_output.put_line('GRANT LOGMINING TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_sys_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'SELECT ANY TABLE';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT SELECT ANY TABLE TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_sys_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'SELECT ANY TRANSACTION';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT SELECT ANY TRANSACTION TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_tab_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'V_$DATABASE';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT SELECT ON SYS.V_$DATABASE TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_tab_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'V_$ARCHIVED_LOG';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT SELECT ON SYS.V_$ARCHIVED_LOG TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_tab_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'V_$LOGMNR_CONTENTS';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT SELECT ON SYS.V_$LOGMNR_CONTENTS TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_tab_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'DBMS_LOGMNR';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT EXECUTE ON DBMS_LOGMNR TO &&dod_username.;');
        END IF;
        SELECT count(1) into v_permission_count from dba_tab_privs where GRANTEE = UPPER('&&dod_username.') and PRIVILEGE = 'DBMS_LOGMNR_D';
        IF v_permission_count = 0 THEN
            dbms_output.put_line('GRANT EXECUTE ON DBMS_LOGMNR_D TO &&dod_username.;');
        END IF;
        dbms_output.put_line('');
        dbms_output.put_line('');
        dbms_output.put_line('/* ---------------------------------------------------------- */');
    END IF;
END;
/

SPO OFF;

SPO datastream_diag_db_fixup_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..sql;

SET SERVEROUTPUT ON TERM OFF ECHO OFF FEED OFF VER OFF HEA OFF PAGES 0 COLSEP '~' LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;

BEGIN
    dbms_output.put_line(' ');
    dbms_output.put_line(' ');
END;
/
SELECT '**** !!!! Database is not in ARCHIVELOG Mode !!!! ****' from DUAL
WHERE NOT EXISTS (select 1 from v$database where LOG_MODE = 'ARCHIVELOG');

BEGIN
    dbms_output.put_line(' ');
    dbms_output.put_line(' ');
END;
/
SELECT 'ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;' from DUAL
WHERE NOT EXISTS (select 1 from v$database where SUPPLEMENTAL_LOG_DATA_MIN = 'YES');

BEGIN
    dbms_output.put_line(' ');
    dbms_output.put_line(' ');
    dbms_output.put_line('----------------------------------------------------------');
    dbms_output.put_line('BE SURE TO ENABLE SUPPLEMENTAL LOGGING AT THE TABLE LEVEL!');
    dbms_output.put_line('----------------------------------------------------------');
    dbms_output.put_line('ALTER TABLE [SCHEMA].[TABLE] ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS');
    dbms_output.put_line('OR');
    dbms_output.put_line('ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (all) COLUMNS;');
    dbms_output.put_line(' ');
    dbms_output.put_line(' ');
END;
/

BEGIN
    dbms_output.put_line(' ');
    dbms_output.put_line(' ');
    dbms_output.put_line('----------------------------------------------------------');
    dbms_output.put_line('CONSIDER SWITCHING LOGS AT A GIVEN INTERVAL');
    dbms_output.put_line('----------------------------------------------------------');
    dbms_output.put_line(q'[alter system set archive_lag_target=900 scope=both sid='*']');
    dbms_output.put_line(' ');
    dbms_output.put_line(' ');
END;
/

---------------------------------------------------------------------------------------

SPO OFF;
SET SERVEROUTPUT OFF TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;