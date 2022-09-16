----------------------------------------------------------------------------------------
--
-- File name:   datastreamOraDiag_collect_ash.sql (2022-08-22)
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

SPO datastream_diag_ash_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL SAMPLE_TIME FOR A18;
COL DATA_SOURCE FOR A4;
COL SQL_ID FOR A18;
COL PROGRAM FOR A30;
COL MODULE FOR A30;
COL ACTION FOR A30;
COL SESSION_TYPE FOR A10;
COL USERNAME FOR A30;
COL SQL_EXEC_START FOR A20;
COL SAMPLE_ET FOR A15;
COL EVENT FOR A30;
COL WAIT_CLASS FOR A30;
COL INST_ID FOR 999;
COL TOP_LEVEL_SQL_ID FOR A18;
COL SQL_PLAN_OPERATION FOR A64;
COL SQL_PLAN_OPTIONS FOR A64;
COL OWNER FOR A30;
COL OBJECT_NAME FOR A30;
COL OBJECT_TYPE FOR A30;
COL MACHINE FOR A50;
COL BLOCKING_INST_ID FOR 999;
COL BLOCKING_SESSION_STATUS FOR A11;
COL IN_PARSE FOR A1;
COL IN_HARD_PARSE FOR A1;
COL IN_SQL_EXECUTION FOR A1;
COL IN_PLSQL_EXECUTION FOR A1;
COL THE_SQL FOR A100;
COL TOP_SQL FOR A100;
COL PLAN_HASH_COUNT FOR 999;



-- header
SELECT 'SAMPLE_TIME',
       'DATA_SOURCE',
       'SQL_ID',
       'SQL_EXEC_ID',
       'PROGRAM',
       'MODULE',
       'ACTION',
       'SESSION_TYPE',
       'USERNAME',
       'SQL_EXEC_START',
       'SAMPLE_ET',
       'EXEC_ET_SECS',
       'ET_BETWEEN_SAMPLES',
       'TM_DELTA_TIME',
       'TM_DELTA_CPU_TIME',
       'TM_DELTA_DB_TIME',
       'TOT_TIME',
       'DIFTIME',
       'EVENT',
       'WAIT_CLASS',
       'INST_ID',
       'SESSION_ID',
       'SESSION_SERIAL#',
       'TOP_LEVEL_SQL_ID',
       'SQL_PLAN_HASH_VALUE',
       'SQL_PLAN_LINE_ID',
       'SQL_PLAN_OPERATION',
       'SQL_PLAN_OPTIONS',
       'OWNER',
       'OBJECT_NAME',
       'OBJECT_TYPE',
       'MAX_SAMPLE',
       'MACHINE',
       'PORT',
       'BLOCKING_SESSION',
       'BLOCKING_INST_ID',
       'BLOCKING_SESSION_STATUS',
       'IN_PARSE',
       'IN_HARD_PARSE',
       'IN_SQL_EXECUTION',
       'IN_PLSQL_EXECUTION',
       'THE_SQL',
       'TOP_SQL',
       'EXACT_MATCHING_SIGNATURE',
       'FORCE_MATCHING_SIGNATURE',
       'BLOCKING_HANGCHAIN_INFO',
       'AVG_EXEC',
       'MIN_EXEC',
       'MAX_EXEC',
       'STDDEV',
       'EXEC_COUNT',
       'PLAN_HASH_COUNT'
  FROM DUAL
/

-- data
SELECT
    *
FROM
    (
        SELECT
            b.*
        FROM
            (
                SELECT
                    a.*,
                    round(avg(exec_et_secs) over(
                        PARTITION BY sql_id
                    ),2) AS avg_exec,
                    MIN(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ) AS min_exec,
                    MAX(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ) AS max_exec,
                    round(STDDEV(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ),2) AS stddev,
                    count(distinct sql_exec_id) over(partition by sql_id) as exec_count,
                    count(distinct SQL_PLAN_HASH_VALUE) over (partition by sql_id) as plan_hash_count
                FROM
                    (
                        SELECT
                            ash.sample_time,
                            'AWR' as data_source,
                            ash.sql_id,
                            ash.sql_exec_id,
                            SUBSTR(ash.program,1,30) as program,
                            SUBSTR(ash.module,1,30) as module,
                            SUBSTR(ash.action,1,30) as action,
                            ash.session_type,
                            du.username,
                            TO_CHAR(ash.sql_exec_start, 'YYYY-MM-DD HH24:MI:SS') AS sql_exec_start,
                            substr(TO_CHAR(ash.sample_time - ash.sql_exec_start, 'HH:MM:SS.FF'), - 12) AS sample_et,
                            MAX(  (EXTRACT(HOUR FROM ash.sample_time - ash.sql_exec_start) * 3600) +
                            (EXTRACT(MINUTE FROM ash.sample_time - ash.sql_exec_start) * 60) +
                            EXTRACT(SECOND FROM ash.sample_time - ash.sql_exec_start)) OVER(
                                PARTITION BY ash.instance_number, ash.sql_exec_id, ash.sql_id, ash.session_id
                            ) AS exec_et_secs,
                            ash.sample_time - lag(ash.sample_time) over( partition by ash.instance_number, ash.session_id, ash.session_serial# order by ash.sample_time) as et_between_samples,
                            tm_delta_time,
                            tm_delta_cpu_time,
                            tm_delta_db_time,
                            (tm_delta_cpu_time/10000)+tm_delta_db_time as tot_time,
                            tm_delta_time - tm_delta_db_time as diftime,
                            SUBSTR(ash.event,1,30) as event,
                            SUBSTR(ash.wait_class,1,30) as wait_class,
                            ash.instance_number as inst_id,
                            ash.session_id,
                            ash.SESSION_SERIAL#,
                            top_level_sql_id,
                            sql_plan_hash_value,
                            sql_plan_line_id,
                            sql_plan_operation,
                            sql_plan_options,
                            o.owner,
                            o.object_name,
                            o.object_type,
                            MAX(ash.sample_time) OVER(
                                PARTITION BY ash.instance_number, ash.sql_exec_id, ash.sql_id, ash.session_id
                            ) AS max_sample,
                            SUBSTR(ash.machine,1,50) AS MACHINE,
                            ash.port,
                            ash.blocking_session,
                            ash.blocking_inst_id,
                            ash.blocking_session_status,
                            in_parse,
                            in_hard_parse,
                            in_sql_execution,
                            in_plsql_execution,
                            SUBSTR(TRANSLATE(sq.sql_text, chr(10)||chr(11)||chr(13)||chr(126)||chr(34)||chr(39), '    '),1,100) as the_sql,
                            SUBSTR(TRANSLATE(tsql.sql_text, chr(10)||chr(11)||chr(13)||chr(126)||chr(34)||chr(39), '    '),1,100) as top_sql,
                            sq.EXACT_MATCHING_SIGNATURE,
                            sq.FORCE_MATCHING_SIGNATURE,
                            ash.blocking_hangchain_info
                        FROM
                            dba_hist_active_sess_history   ash
                            LEFT OUTER JOIN gv$sql         sq ON ash.sql_id = sq.sql_id
                                                              AND ash.instance_number = sq.inst_id
                                                              AND ash.sql_child_number = sq.child_number
                            LEFT OUTER JOIN (
                                SELECT DISTINCT
                                    sql_id,
                                     to_char(dbms_lob.substr(sql_text,70,1)) as  sql_text
                                FROM
                                    dba_hist_sqltext
                            ) tsql ON ash.top_level_sql_id = tsql.sql_id
                            LEFT OUTER JOIN dba_users du on du.user_id = ash.user_id
                            LEFT OUTER JOIN dba_objects o on o.object_id = ash.current_obj#
                            WHERE  ash.sample_time BETWEEN   NVL(TO_DATE('&&dod_coll_date_from_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI'),
                                (SELECT MAX(sample_time)-(1/24) FROM dba_hist_active_sess_history))
                                AND NVL(TO_DATE('&&dod_coll_date_to_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI'), (SELECT MAX(sample_time)
                                FROM dba_hist_active_sess_history))
                    ) a
            ) b
)
/*ASHDATA*/
WHERE nvl(the_sql,'x') not like 'SELECT /* ash_recent_sessions */%'
UNION ALL
SELECT /* ash_recent_sessions */
    *
FROM
    (
        SELECT
            b.*
        FROM
            (
                SELECT
                    a.*,
                    round(avg(exec_et_secs) over(
                        PARTITION BY sql_id
                    ),2) AS avg_exec,
                    MIN(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ) AS min_exec,
                    MAX(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ) AS max_exec,
                    round(STDDEV(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ),2) AS stddev,
                    count(distinct sql_exec_id) over(partition by inst_id, session_id, SESSION_SERIAL#, sql_id) as exec_count,
                    count(distinct SQL_PLAN_HASH_VALUE) over (partition by sql_id) as plan_hash_count
                FROM
                    (
                        SELECT
                            ash.sample_time,
                            'ASH' as data_source,
                            ash.sql_id,
                            ash.sql_exec_id,
                            SUBSTR(ash.program,1,30) as program,
                            SUBSTR(ash.module,1,30) as module,
                            SUBSTR(ash.action,1,30) as action,
                            ash.session_type,
                            du.username,
                            TO_CHAR(ash.sql_exec_start, 'YYYY-MM-DD HH24:MI:SS') AS sql_exec_start,
                            substr(TO_CHAR(ash.sample_time - ash.sql_exec_start, 'HH:MM:SS.FF'), - 12) AS sample_et,
                            MAX(  (EXTRACT(HOUR FROM ash.sample_time - ash.sql_exec_start) * 3600) +
                            (EXTRACT(MINUTE FROM ash.sample_time - ash.sql_exec_start) * 60) +
                            EXTRACT(SECOND FROM ash.sample_time - ash.sql_exec_start)) OVER(
                                PARTITION BY ash.inst_id, ash.sql_exec_id, ash.sql_id, ash.session_id
                            ) AS exec_et_secs,
                            ash.sample_time - lag(ash.sample_time) over( partition by ash.inst_id, ash.session_id, ash.session_serial# order by ash.sample_time) as et_between_samples,
                            tm_delta_time,
                            tm_delta_cpu_time,
                            tm_delta_db_time,
                            (tm_delta_cpu_time/10000)+tm_delta_db_time as tot_time,
                            tm_delta_time - tm_delta_db_time as diftime,
                            SUBSTR(ash.event,1,30) as event,
                            SUBSTR(ash.wait_class,1,30) as wait_class,
                            ash.inst_id,
                            ash.session_id,
                            ash.SESSION_SERIAL#,
                            top_level_sql_id,
                            sql_plan_hash_value,
                            sql_plan_line_id,
                            sql_plan_operation,
                            sql_plan_options,
                            o.owner,
                            o.object_name,
                            o.object_type,
                            MAX(ash.sample_time) OVER(
                                PARTITION BY ash.inst_id, ash.sql_exec_id, ash.sql_id, ash.session_id
                            ) AS max_sample,
                            SUBSTR(ash.machine,1,50) AS MACHINE,
                            ash.port,
                            ash.blocking_session,
                            ash.blocking_inst_id,
                            ash.blocking_session_status,
                            in_parse,
                            in_hard_parse,
                            in_sql_execution,
                            in_plsql_execution,
                            SUBSTR(TRANSLATE(sq.sql_text, chr(10)||chr(11)||chr(13)||chr(126)||chr(34)||chr(39), '    '),1,100) as the_sql,
                            SUBSTR(TRANSLATE(tsql.sql_text, chr(10)||chr(11)||chr(13)||chr(126)||chr(34)||chr(39), '    '),1,100) as top_sql,
                            sq.EXACT_MATCHING_SIGNATURE,
                            sq.FORCE_MATCHING_SIGNATURE ,
                            ash.blocking_hangchain_info
                        FROM
                            gv$active_session_history   ash
                            LEFT OUTER JOIN gv$sql                      sq ON ash.sql_id = sq.sql_id
                                                         AND ash.inst_id = sq.inst_id
                                                         AND ash.sql_child_number = sq.child_number
                            LEFT OUTER JOIN (
                                SELECT DISTINCT
                                    sql_id,
                                    dbms_lob.substr(sql_text,75,1) as sql_text
                                FROM
                                    gv$sql
                            ) tsql ON ash.top_level_sql_id = tsql.sql_id
                            LEFT OUTER JOIN dba_users du on du.user_id = ash.user_id
                            LEFT OUTER JOIN dba_objects o on o.object_id = ash.current_obj#
                            LEFT OUTER JOIN gv$session gs on gs.inst_id = ash.inst_id and gs.sid = ash.session_id and gs.serial# = ash.session_serial#
                            where  ash.sample_time BETWEEN nvl(TO_DATE('&&dod_coll_date_from_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI'), sysdate-(1/24/30)) AND nvl(TO_DATE('&&dod_coll_date_to_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI'), sysdate)
                    ) a
            ) b
)
where nvl(the_sql,'x') not like 'SELECT /* ash_recent_sessions */%'
order by 1 desc
/


---------------------------------------------------------------------------------------

SPO OFF;
SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;
