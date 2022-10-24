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

SPO datastream_diag_system_under_observation_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

WITH rac AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        COUNT(*) instances,
        CASE COUNT(*)
            WHEN 1 THEN
                'Single-instance'
            ELSE
                COUNT(*)
                || '-node RAC cluster'
        END      db_type
    FROM
        gv$instance
), hrac AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        CASE instances
            WHEN 1 THEN
                ' (historically Single-instance in AWR)'
            ELSE
                ' (historically 2-node RAC cluster in AWR)'
        END db_type
    FROM
        rac
    WHERE
        to_char(rac.instances) <> 2
), mem AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(value) target
    FROM
        gv$system_parameter2
    WHERE
        name = 'memory_target'
), sga AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(value) target
    FROM
        gv$system_parameter2
    WHERE
        name = 'sga_target'
), pga AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(value) target
    FROM
        gv$system_parameter2
    WHERE
        name = 'pga_aggregate_target'
), db_block AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        value bytes
    FROM
        v$system_parameter2
    WHERE
        name = 'db_block_size'
), db AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        name,
        platform_name
    FROM
        v$database
), inst AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        host_name,
        version db_version
    FROM
        v$instance
), data AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(bytes)          bytes,
        COUNT(*)            files,
        COUNT(DISTINCT ts#) tablespaces
    FROM
        v$datafile
), temp AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(bytes) bytes
    FROM
        v$tempfile
), log AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(bytes) * MAX(members) bytes
    FROM
        v$log
), control AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(block_size * file_size_blks) bytes
    FROM
        v$controlfile
), cell AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        COUNT(DISTINCT cell_name) cnt
    FROM
        v$cell_state
), core AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(value) cnt
    FROM
        gv$osstat
    WHERE
        stat_name = 'NUM_CPU_CORES'
), cpu AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(value) cnt
    FROM
        gv$osstat
    WHERE
        stat_name = 'NUM_CPUS'
), pmem AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        SUM(value) bytes
    FROM
        gv$osstat
    WHERE
        stat_name = 'PHYSICAL_MEMORY_BYTES'
), awr_settings AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        snap_interval,
        retention 
    FROM
        dba_hist_wr_control
), awr_snapshots AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        MIN(begin_interval_time) MIN_SNAPSHOT,
        MAX(begin_interval_time) MAX_SNAPSHOT
    FROM
        dba_hist_snapshot
), scn_data AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        TIMESTAMP_TO_SCN(NVL(TO_DATE('&&dod_coll_date_from_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI'), systimestamp)) MIN_SCN,
        TIMESTAMP_TO_SCN(NVL(TO_DATE('&&dod_coll_date_to_yyyy_mm_dd_hh24_mi.', 'YYYY-MM-DD HH24:MI'), systimestamp))  MAX_SCN
    FROM
        dual
), supplemental_logging AS (
    SELECT /*+  MATERIALIZE NO_MERGE  */
        supplemental_log_data_min,
        force_logging,
        log_mode
    FROM
        v$database
)
SELECT /*+  NO_MERGE  */
    'Database name:' system_item,
    db.name          system_value
FROM
    db
UNION ALL
SELECT
    'Oracle Database version:',
    inst.db_version
FROM
    inst
UNION ALL
SELECT
    'Database block size:',
    TRIM(to_char(db_block.bytes / power(2, 10),
                 '90'))
    || ' KB'
FROM
    db_block
UNION ALL
SELECT
    'Database size:',
    TRIM(to_char(round((data.bytes + temp.bytes + log.bytes + control.bytes) / power(10, 12),
                       3),
                 '999,999,990.000'))
    || ' TB'
FROM
    db,
    data,
    temp,
    log,
    control
UNION ALL
SELECT
    'Datafiles:',
    data.files
    || ' (on '
    || data.tablespaces
    || ' tablespaces)'
FROM
    data
UNION ALL
SELECT
    'Instance configuration:',
    rac.db_type
    || (
        SELECT
            hrac.db_type
        FROM
            hrac
    )
FROM
    rac
UNION ALL
SELECT
    'Database memory:',
    CASE
        WHEN mem.target > 0 THEN
                'MEMORY '
                || TRIM(to_char(round(mem.target / power(2, 30),
                                      1),
                                '999,990.0'))
                || ' GB, '
    END
    ||
    CASE
        WHEN sga.target > 0 THEN
                'SGA '
                || TRIM(to_char(round(sga.target / power(2, 30),
                                      1),
                                '999,990.0'))
                || ' GB, '
    END
    ||
    CASE
        WHEN pga.target > 0 THEN
                'PGA '
                || TRIM(to_char(round(pga.target / power(2, 30),
                                      1),
                                '999,990.0'))
                || ' GB, '
    END
    ||
    CASE
        WHEN mem.target > 0 THEN
                'AMM'
        ELSE
            CASE
                WHEN sga.target > 0 THEN
                            'ASMM'
                ELSE
                    'MANUAL'
            END
    END
FROM
    mem,
    sga,
    pga
UNION ALL
SELECT
    'Hardware:',
    CASE
        WHEN cell.cnt > 0 THEN
            'Engineered System '
            ||
            CASE
                WHEN 'Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz' LIKE '%5675%' THEN
                        'X2-2 '
            END
            ||
            CASE
                WHEN 'Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz' LIKE '%2690%' THEN
                        'X3-2 '
            END
            ||
            CASE
                WHEN 'Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz' LIKE '%2697%' THEN
                        'X4-2 '
            END
            ||
            CASE
                WHEN 'Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz' LIKE '%2699%' THEN
                        'X5-2 or X-6 '
            END
            ||
            CASE
                WHEN 'Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz' LIKE '%8160%' THEN
                        'X7-2 '
            END
            ||
            CASE
                WHEN 'Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz' LIKE '%8870%' THEN
                        'X3-8 '
            END
            ||
            CASE
                WHEN 'Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz' LIKE '%8895%' THEN
                        'X4-8 or X5-8 '
            END
            || 'with '
            || cell.cnt
            || ' storage servers'
        ELSE
            'Unknown'
    END
FROM
    cell
UNION ALL
SELECT
    'Processor:',
    'Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz'
FROM
    dual
UNION ALL
SELECT
    'Physical CPUs:',
    core.cnt
    || ' cores'
    ||
    CASE
        WHEN rac.instances > 0 THEN
                ', on ' || rac.db_type
    END
FROM
    rac,
    core
UNION ALL
SELECT
    'Oracle CPUs:',
    cpu.cnt
    || ' CPUs (threads)'
    ||
    CASE
        WHEN rac.instances > 0 THEN
                ', on ' || rac.db_type
    END
FROM
    rac,
    cpu
UNION ALL
SELECT
    'Physical RAM:',
    TRIM(to_char(round(pmem.bytes / power(2, 30),
                       1),
                 '999,990.0'))
    || ' GB'
    ||
    CASE
        WHEN rac.instances > 0 THEN
                ', on ' || rac.db_type
    END
FROM
    rac,
    pmem
UNION ALL
SELECT
    'Operating system:',
    db.platform_name
FROM
    db
UNION ALL
SELECT
    'AWR Settings:',
    'Snap Interval - '|| snap_interval || ' /  Snap Retention - ' || retention
FROM
    awr_settings
UNION ALL
SELECT
    'Available AWR Snapshot Range:',
    'Min Snap Date - '|| min_snapshot || ' /  Max Snap Date - ' || max_snapshot
FROM
    awr_snapshots
UNION ALL
SELECT
    'Selected SCN Range:',
    'Min SCN - '|| min_scn || ' /  Max SCN - ' || max_scn
FROM
    scn_data
UNION ALL
SELECT
    'Supplemental Log Data Min:',
    supplemental_log_data_min
FROM
    supplemental_logging
UNION ALL
SELECT
    'Force Logging:',
    force_logging
FROM
    supplemental_logging
UNION ALL
SELECT
    'Database Log Mode:',
    log_mode
FROM
    supplemental_logging
/
SPO OFF;

---------------------------------------------------------------------------------------

SPO datastream_diag_patchset_output_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..csv;

COL ACTION_TIME FOR A23
COL ACTION FOR A30
COL VERSION FOR A30
COL COMMENTS FOR A200

SELECT 'ACTION_TIME',
       'ACTION',
       'VERSION',
       'COMMENTS'
FROM DUAL
/

SELECT
    TO_CHAR(action_time,'&&dod_date_format.') as ACTION_TIME,
    action,
    version,
    SUBSTR(comments,1,200) as COMMENTS
FROM
    dba_registry_history
ORDER BY
    action_time NULLS FIRST
/

---------------------------------------------------------------------------------------

SPO OFF;
SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;
