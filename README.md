# Datastream Diagnostic Toolkit v23.01 (2023-11) 
by Shane Borden (datastream-diagnostic-toolkit)

Scripts used to collect diagnostic information for the Google Datastream product

Datastream Diagnostic Toolkit is a "free to use" script (Covered buy the Apache 2.0 License) 
that collects Diagnostic Information from an Oracle Database used by the Datastream product. Since 
most of the metadata collected comes from DBA_HIST and ASH Views, the system where it runs must 
have a valid Oracle Diagnostics Pack License.

## Steps

1. Connect to a Host as oracle
2. Transfer and Unzip datastream-diagnostic-toolkit.zip or datastream-diagnostic-toolkit.tar.gz and navigate to datastream-diagnostic-toolkit directory
3. Source in the appropriate database
4. Connect into SQL*Plus as SYS or user with query access to the data dictionary (i.e. DBA),
   then execute the appropriate script for the target system:
   - Oracle: @datastreamOraDiagCollect.sql
5. Script will prompt for a timeframe.  At a minimum, please enter a time 15 minutes before the issue occurred
   until 15 minutes after in the following format:  YYYY-MM-DD HH24:MI  
      *** Note: Longer timeframes may require longer execution time
6. Provide to requestor all files generated by this script on current directory
   (i.e. datastream_diag_output_hostname_database_yyyymmdd_hh24mi.zip)
7.  Return the zipfile to support

## Limitations

1. The scripts are designed to run via SQLPlus and have not been tested with other tools such as SQLDeveloper.
