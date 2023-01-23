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


set null "NULL VALUE"
SET TERM OFF ECHO OFF FEED OFF VER OFF HEA OFF PAGES 0 COLSEP '~' LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;

---------------------------------------------------------------------------------------

col table_name for a30
col column_name for a30
col data_type for a40
col object_type for a20
col constraint_type_desc for a30
col Owner format a15
col constraint_name format a40
col TABLE_TYPE format a30
col partitioning_type format a30
col "Avg Log Size" format 999,999,999,999

---------------------------------------------------------------------------------------

SPO datastream_diag_comprehensive_db_check_&&dod_host_name_short._&&dod_dbname_short._&&dod_collection_yyyymmdd_hhmi..txt;

Prompt - Please be sure to refer to the following documentation for known limitation and configuration information
Prompt - Refer to: https://cloud.google.com/datastream/docs/configure-your-source-oracle-database

set heading off

SELECT '------ Objects stored in Tablespaces with Compression are not supported ------ ' 
FROM dual;
set heading on

SELECT
	TABLESPACE_NAME,
	DEF_TAB_COMPRESSION
FROM 
	DBA_TABLESPACES
WHERE 
	DEF_TAB_COMPRESSION <> 'DISABLED'
ORDER BY
	TABLESPACE_NAME
/

set heading off
SELECT '------ Distinct Object Types and their Count By Schema: ------'
FROM dual;
set heading on

SELECT 
	owner, 
	object_type, 
	count(*) total
FROM
	all_objects
WHERE
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
GROUP BY 
	object_type, owner
ORDER BY
	owner
/

set heading off
SELECT '------ Distinct Column Data Types and their Count in the Schema: ------' 
FROM dual;
set heading on

SELECT 
	data_type, 
	count(*) total
FROM
	all_tab_columns
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
GROUP BY data_type
ORDER BY data_type
/

set heading off
SELECT '------ Tables With No Primary Key or Unique Index by Schema: ------' 
FROM dual;
set heading on
SELECT 
	owner,
	table_name
  FROM 
	all_tables
 WHERE 
	owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
MINUS
(SELECT
	user1.name,
	obj1.name
  FROM SYS.user$ user1,
       SYS.user$ user2,
       SYS.cdef$ cdef,
       SYS.con$ con1,
       SYS.con$ con2,
       SYS.obj$ obj1,
       SYS.obj$ obj2
 WHERE 
 	user1.name not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND user1.name not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
	AND cdef.type# = 2 
	AND con2.owner# = user2.user#(+)
	AND cdef.robj# = obj2.obj#(+)
	AND cdef.rcon# = con2.con#(+)
	AND obj1.owner# = user1.user#
	AND cdef.con# = con1.con#
	AND cdef.obj# = obj1.obj#
UNION
SELECT 
	distinct(owner), 
	idx.table_name
  FROM 
	all_indexes idx
 WHERE
	idx.owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND idx.owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
	AND idx.uniqueness = 'UNIQUE')
/

set heading off
SELECT '------ Tables with NOLOGGING setting ------' FROM dual;
SELECT '------ Missing Data Could Result ------' FROM dual;
set heading on
select 
	owner, 
	table_name, 
	' ' as partitioning_type, 
	logging 
from 
	DBA_TABLES
where 
	logging <> 'YES'
	and owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	and owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
UNION
select 
	owner, 
	table_name, 
	partitioning_type, 
	DEF_LOGGING "LOGGING" 
from 
	DBA_PART_TABLES
where 
	DEF_LOGGING != 'YES' 
	and owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC') 
	and owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
UNION
select 
	table_owner, 
	table_name, 
	PARTITION_NAME, 
	logging 
from 
	DBA_TAB_PARTITIONS
where 
	logging <> 'YES' 
	and table_owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC') 
	and table_owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
UNION
select 
	table_owner, 
	table_name, 
	PARTITION_NAME, 
	logging 
from 
	DBA_TAB_SUBPARTITIONS
where 
	logging <> 'YES' 
	and table_owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC') 
	and table_owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
ORDER BY 1
/

set heading off
SELECT '------ Tables with Deferred constraints. ' FROM dual;
SELECT '------ Deferred constraints may cause TRANDATA to chose an incorrect Key and should be researched further. ' FROM dual;
SELECT '------ Tables with Deferred PK constraints should be added using KEYCOLS in the trandata statement.'FROM dual;
set heading on
SELECT 
	c.OWNER,
	c.TABLE_NAME,
	c.CONSTRAINT_NAME,
	c.CONSTRAINT_TYPE,
	c.DEFERRABLE,
	c.DEFERRED,
	c.VALIDATED,
	c.STATUS,
	i.INDEX_TYPE,
	c.INDEX_NAME,
	c.INDEX_OWNER
FROM 
	dba_constraints c,
	dba_indexes i
WHERE
    i.TABLE_NAME   = c.TABLE_NAME
	AND i.OWNER        = c.OWNER
	AND  c.DEFERRED = 'DEFERRED'
	AND i.owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC') 
	AND i.owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
ORDER BY 1
/

set heading off
SELECT '------ Tables Defined with Rowsize > 3M in all Schemas ------'
FROM dual;
set heading on
SELECT
	owner,
	table_name, 
	sum(data_length) row_length_over_2M
FROM 
	all_tab_columns
WHERE 
	owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC') 
	AND owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
GROUP BY
	owner,
	table_name
HAVING 
	sum(data_length) > 3000000
ORDER BY
	owner
/

set heading off
SELECT '------ Tables With CLOB, BLOB, LONG, NCLOB or LONG RAW Columns in ALL Schemas ------' 
FROM dual;
set heading on
SELECT 
	OWNER, 
	TABLE_NAME, 
	COLUMN_NAME, 
	DATA_TYPE
FROM 
	all_tab_columns
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
	AND data_type in ('CLOB', 'BLOB', 'LONG', 'LONG RAW', 'NCLOB')
ORDER BY
	OWNER
/

set heading off
SELECT '------ Tables With Columns of UNSUPPORTED Datatypes in ALL Schemas ------' 
FROM dual;
set heading on
SELECT 
	OWNER, 
	TABLE_NAME, 
	COLUMN_NAME, 
	DATA_TYPE
FROM 
	all_tab_columns
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
	AND (data_type in ('ORDDICOM', 'BFILE', 'TIMEZONE_REGION', 'BINARY_INTEGER', 'PLS_INTEGER', 'UROWID', 'URITYPE', 'MLSLABEL', 'TIMEZONE_ABBR', 'ANYDATA', 'ANYDATASET', 'ANYTYPE', 'CLOB', 'LONG', 'LONG RAW', 'NCLOB', 'UDT', 'UROWID', 'XMLTYPE')
	or data_type like 'INTERVAL%')
ORDER BY
	OWNER
/

set heading off
SELECT '------ Cluster, or Object Tables - ALL UNSUPPORTED - in ALL Schemas ------'
FROM dual;
set heading on
SELECT 
	OWNER, 
	TABLE_NAME, 
	CLUSTER_NAME, 
	TABLE_TYPE 
FROM 
	all_all_tables
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
	AND (cluster_name is NOT NULL or TABLE_TYPE is NOT NULL)
ORDER BY
	OWNER
/

set heading off 
Select '------ All tables that have compression enabled / test for proper Datastream support: ------'
from dual;
set heading on
select 
	owner, 
	table_name
from 
	DBA_TABLES
where 
	COMPRESSION = 'ENABLED'
	AND OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
ORDER BY
	OWNER
/

SET Heading off
Select '------ All tables (ppartitions) that have compression enabled / test for proper Datastream support: ------'
from dual;
SET Heading on
SELECT 
	TABLE_OWNER, 
	TABLE_NAME, 
	COMPRESSION
FROM 
	ALL_TAB_PARTITIONS
WHERE 
	(COMPRESSION = 'ENABLED')
	AND TABLE_OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND TABLE_OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
ORDER BY
	TABLE_OWNER
/

set heading off
SELECT '------ Index Organized Tables (IOT) - Not Supported: ------' 
FROM dual;
set heading on
SELECT 
	OWNER, 
	TABLE_NAME, 
	IOT_TYPE, 
	TABLE_TYPE 
FROM 
	all_all_tables
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC') 
	AND OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
	AND (IOT_TYPE is not null or TABLE_TYPE is NOT NULL)
ORDER BY
	OWNER
/

set heading off
SELECT '------ Tables with Domain or Context Indexes ------' 
FROM dual;
set heading on
SELECT 
	OWNER, 
	TABLE_NAME, 
	index_name, 
	index_type 
FROM 
	dba_indexes 
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC') 
	AND OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
	and index_type = 'DOMAIN'
ORDER BY
	OWNER
/

set heading off
SELECT '------ Types of Constraints on the Tables in ALL Schemas ------'
FROM dual;
set heading on
SELECT 
	OWNER,
	DECODE(constraint_type,'P','PRIMARY KEY','U','UNIQUE', 'C', 'CHECK', 'R', 'REFERENTIAL') constraint_type_desc, 
	count(*) total
FROM 
	all_constraints
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC') 
	AND OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y') 
GROUP BY 
	owner,
	constraint_type
ORDER BY
	owner
/

set heading off
SELECT '------ Cascading Deletes on the Tables in ALL Schemas - Could result in a "NO-OP" Condition ------' 
FROM dual;
set heading on
SELECT 
	owner, 
	table_name, 
	constraint_name
FROM 
	all_constraints
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')  
	AND OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y') 
	and constraint_type = 'R' and delete_rule = 'CASCADE'
ORDER BY
	OWNER
/

set heading off
SELECT '------ Tables Defined with Triggers:------ '
FROM dual;
set heading on
SELECT 
	owner,
	table_name, 
	COUNT(*) trigger_count
FROM 
	all_triggers
WHERE 
	OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')  
	AND OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y') 
GROUP BY 
	owner,
	table_name
ORDER BY
	owner
/

set heading off
SELECT '------ Tables with Reversed Primary Keys are not Supported: ------'
FROM dual;
col TABLE_OWNER format a10
col INDEX_TYPE format a12
col INDEX_NAME format a30
SET Heading on
SELECT 
	distinct(owner) as owner, 
	idx.table_name as table_name,
	idx.index_name as index_name,
	idx.index_type as index_type
FROM 
	all_indexes idx
WHERE
	idx.owner not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND idx.owner not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
	AND idx.uniqueness = 'UNIQUE'
	AND idx.index_type = 'NORMAL/REV'
	AND EXISTS (select 1 from all_constraints ac where idx.owner = ac.owner and idx.table_name = ac.table_name and idx.index_name = ac.index_name)
ORDER BY
	1
/

SET Heading off
SELECT '------ Sequence numbers - Sequences could be a issue for HA configurations ------'
FROM dual;

COLUMN SEQUENCE_OWNER FORMAT a15
COLUMN SEQUENCE_NAME FORMAT a30
COLUMN INCR FORMAT 999
COLUMN CYCLE FORMAT A5
COLUMN ORDER FORMAT A5
SET Heading on
SELECT 
	SEQUENCE_OWNER,
	SEQUENCE_NAME,
	MIN_VALUE,
	MAX_VALUE,
	INCREMENT_BY INCR,
	CYCLE_FLAG CYCLE,
	ORDER_FLAG "ORDER",
	CACHE_SIZE,
	LAST_NUMBER
FROM
	DBA_SEQUENCES
WHERE 
	SEQUENCE_OWNER not in ('SYS', 'SYSTEM', 'DBSNMP','SYSMAN','OUTLN','MDSYS','ORDSYS','EXFSYS','DMSYS','WMSYS','CTXSYS','ANONYMOUS','XDB','ORDPLUGINS','OLAPSYS','PUBLIC')
	AND SEQUENCE_OWNER not in (SELECT username from dba_users where ORACLE_MAINTAINED = 'Y')
ORDER BY
	SEQUENCE_OWNER
/
set linesize 180

set heading off
SELECT '------ Average Log Size ------'
FROM dual;

set heading on
select sum (BLOCKS) * max(BLOCK_SIZE)/ count(*) "Avg Log Size" From gV$ARCHIVED_LOG;

set heading off
SELECT '----- Frequency of Log Switches by hour and day ------'
FROM dual;
set heading on

SELECT 
	SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),1,5) DAY, 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'00',1,0)),'99') "00", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'01',1,0)),'99') "01", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'02',1,0)),'99') "02", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'03',1,0)),'99') "03", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'04',1,0)),'99') "04", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'05',1,0)),'99') "05", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'06',1,0)),'99') "06", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'07',1,0)),'99') "07", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'08',1,0)),'99') "08", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'09',1,0)),'99') "09", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'10',1,0)),'99') "10", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'11',1,0)),'99') "11", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'12',1,0)),'99') "12", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'13',1,0)),'99') "13", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'14',1,0)),'99') "14", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'15',1,0)),'99') "15", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'16',1,0)),'99') "16", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'17',1,0)),'99') "17", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'18',1,0)),'99') "18", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'19',1,0)),'99') "19", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'20',1,0)),'99') "20", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'21',1,0)),'99') "21", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'22',1,0)),'99') "22", 
	TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'23',1,0)),'99') "23" 
FROM
	V$LOG_HISTORY 
GROUP BY 
	SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),1,5) 
ORDER BY
	1
/
set heading off
SELECT '------ Summary of log volume processed in Mb by day for last 7 days: ------'
FROM dual
/
set heading on
select 
	to_char(first_time, 'mm/dd') ArchiveDate,
	round(sum(BLOCKS*BLOCK_SIZE/1024/1024),2) LOGMB
from 
	v$archived_log
where 
	first_time > sysdate - 7
group by 
	to_char(first_time, 'mm/dd')
order by 
	to_char(first_time, 'mm/dd')
/
set heading off
SELECT '------ Summary of log volume processed in Mb per hour for last 7 days: ------' 
FROM dual;
set heading on
select to_char(first_time, 'MM-DD-YYYY') ArchiveDate, 
       to_char(first_time, 'HH24') ArchiveHour,
       round(sum(BLOCKS*BLOCK_SIZE/1024/1024),2) LogMB
from 
	v$archived_log
where 
	first_time > sysdate - 7
group by 
	to_char(first_time, 'MM-DD-YYYY'), to_char(first_time, 'HH24')
order by 
	to_char(first_time, 'MM-DD-YYYY'), to_char(first_time, 'HH24')
/

---------------------------------------------------------------------------------------

SPO OFF;
SET TERM ON ECHO OFF FEED ON VER ON HEA ON PAGES 14 COLSEP ' ' LIN 80 TRIMS OFF TRIM ON TI OFF TIMI OFF ARRAY 15 NUM 10 SQLBL OFF BLO ON RECSEP WR;