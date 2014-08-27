#!/bin/bash
# #######################################################################
# NAME: OSBrepo.sh
#
# DESC: Linux bash script to run RCU script to setup repository DB for OSB.
#       The RCU software zip file should be located in the same directory as this main script.
#       It will be automatically extracted and removed once installation is completed.
#       Requires the following environment variable to be provided as risk mitigation
#       against using passwords in files:
#
#       SYSPWD     - SYS user password.
#       SCHEMA_PWD - Password to be used for all schemas created in this run
#
# USAGE:
# ${SCRIPT} [OPTION]
#
# OPTIONS
# -h [home]
#   Location of the expanded RCU files (should have a bin sub-directory
#  
# -d [dbconn]
#   Oracle DB connection string in the format: <hostname>:<port>:<service>
#    
# -p [prefix]
#   Schema prefix to be applied to schema names. Defaults to 'SBX' if none is specified.
#   A prefix is useful for multiple OSB domains or environments sharing a single database.
#
# $HeadURL$
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
#
# LOG:
# yyyy/mm/dd [user]: [version] [notes]
# 2014/02/07 cgwong: [v1.0.0] Initial creation from notes.
# 2014/02/17 cgwong - [v1.0.1] Use basename instead of readlink.
# 2014/02/28 cgwong - [v1.0.2] Updated comments, usage function and messages.
# 2014/03/04 cgwong - [v1.0.3] Corrected TEMP tablespace syntax issue.
# 2014/03/20 cgwong - [v1.1.0] Added RCU software installation setup.
#                     Updated comments and script usage.
# 2014/03/21 cgwong - [v1.1.1] Corrected spacing.
# 2014/03/29 cgwong - [v1.1.2] Updated RCU syntax for tablespace for schemas.
# 2014/07/10 cgwong - [v1.1.3] Changed cmline option from -h to -l & updated usage verbiage
#                     to match.
#                     Added -r parameter to cleanup removal options.
#                     Added mkdir and sub-directory unzip to extract_software.
# #######################################################################

# -- Setup variables and process command line --
SCRIPT=`basename $0`
SCRIPT_PATH=$(dirname $SCRIPT)

PID=$$    # Script process ID
DT_STAMP=`date "+%Y%m%d%H%M%S"`   # Date/time stamp
LOGFILE=/tmp/`echo $SCRIPT | awk -F"." '{print $1}'`-${DT_STAMP}.log    # Log file
PWD_FILE=/tmp/.`echo $SCRIPT | awk -F"." '{print $1}'`-${DT_STAMP}.cred   # Temporary password file
TGT_HOST=`hostname`     # Target hostname
RCU_FILE="${SCRIPT_PATH}/rcu-11.1.1.7_linx64-custom.zip"   # RCU software file
ERR=1     # Error status
SUC=0     # Success status

# -- Functions -- #
msg ()
{ # Print message to screen and log file
  # Valid parameters:
  #   $1 - function name
  #   $2 - Message Type or status
  #   $3 - message
  #
  # Log format:
  #   Timestamp: [yyyy-mm-dd hh24:mi:ss]
  #   Component ID: [compID: ]
  #   Process ID (PID): [pid: ]
  #   Host ID: [hostID: ]
  #   User ID: [userID: ]
  #   Message Type: [NOTE | WARN | ERROR | INFO | DEBUG]
  #   Message Text: "Metadata Services: Metadata archive (MAR) not found."

  # Variables
  TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
  [[ -n "$LOGFILE" ]] && echo -e "[${TIMESTAMP}],PRC: ${1},PID: ${PID},HOST: ${TGT_HOST},USER: ${USER}, STATUS: ${2}, MSG: ${3}" | tee -a $LOGFILE
}

create_pwd_file ()
{
  msg create_pwd_file NOTE 'Creating temporary password file...'
  echo ${SYSPWD}      > $PWD_FILE   # SYS password
  echo ${SCHEMA_PWD} >> $PWD_FILE   # SOAINFRA password
#  echo ${SCHEMA_PWD} >> $PWD_FILE   # MDS password
#  echo ${SCHEMA_PWD} >> $PWD_FILE   # ORASDPM password
}

cleanup ()
{
  msg cleanup NOTE 'Cleaning up...'
  [[ -f "$PWD_FILE" ]] && rm -f ${PWD_FILE}
  unset SCHEMA_PWD
  unset SYSPWD
  [[ -d "$RCU_HOME" ]] && rm -rf ${RCU_HOME}
}

show_usage ()
{
  echo "
 ${SCRIPT} - Linux bash script to run RCU script to setup repository DB for OSB.
  The RCU software zip file should be located in the same directory as this main script.
  It will be automatically extracted and removed once installation is completed.
  Requires the following environment variable to be provided as risk mitigation
  against using passwords in files:

 SYSPWD     - SYS user password.
 SCHEMA_PWD - Password to be used for all schemas created in this run

 USAGE
 ${SCRIPT} [OPTION]
 
 OPTIONS
  -l [home]
    Location of the expanded RCU files or where the files should be extracted.
    For example, -l /tmp/rcuHome.
  
  -d [dbconn]
    Oracle DB connection string in the format: <hostname>:<port>:<service>
    
  -p [prefix]
    Schema prefix to be applied to schema names. Defaults to 'SBX' if none is specified.
    A prefix is useful for multiple OSB domains or environments sharing a single database.
"
}

create_tbs () 
{ # Create Oracle DB tablespaces for repository schemas
  # We assume certain parameters are set such as
  # default data file locations and Oracle Managed Files 
  msg create_tbs NOTE 'Creating OSB tablespaces...'
  $ORACLE_HOME/bin/sqlplus -S /nolog << EOF
  CONNECT "sys/${SYSPWD}@${DBCONN}" as sysdba
  CREATE TABLESPACE ${PREFIX}_SOAINFRA
    DATAFILE SIZE 1024M AUTOEXTEND ON MAXSIZE UNLIMITED LOGGING
    EXTENT MANAGEMENT LOCAL
    AUTOALLOCATE
    SEGMENT SPACE MANAGEMENT AUTO
  /
  CREATE TEMPORARY TABLESPACE SOA_TEMP
    TEMPFILE SIZE 256M AUTOEXTEND ON MAXSIZE UNLIMITED
    EXTENT MANAGEMENT LOCAL
  /
EOF
  
}

create_schemas ()
{
  # Create log directory as this is typically missing from the RCU package
  msg create_schema NOTE 'Creating OSB schemas...'
  [ -d ${RCU_HOME}/log ] && mkdir ${RCU_HOME}/log
  $RCU_HOME/bin/rcu -silent -createRepository -databaseType ORACLE -connectString ${DBCONN} -dbUser sys -dbRole SYSDBA -useSamePasswordForAllSchemaUsers -schemaPrefix ${PREFIX} -component SOAINFRA -tablespace ${PREFIX}_SOAINFRA -tempTablespace SOA_TEMP -component MDS -tablespace ${PREFIX}_SOAINFRA -tempTablespace SOA_TEMP -component ORASDPM -tablespace ${PREFIX}_SOAINFRA -tempTablespace SOA_TEMP -f < ${PWD_FILE}
}

extract_software ()
{ # Extract software
  [ ! -d ${RCU_HOME} ] && mkdir -p ${RCU_HOME} && unzip -oq ${RCU_FILE} -d ${RCU_HOME}/../
}

# -- MAIN -- #
# Process command line arguments
if [ $# -lt 1 ]; then
  msg MAIN ERROR "No arguments passed."
  show_usage
  exit $ERR
fi

while [ $# -gt 0 ] ; do
  case $1 in
  -l)   # RCU_HOME
    RCU_HOME=$2
    shift ;;
  -p)   # Schema prefix
    PREFIX=${2:-"SBX"}
    shift ;;
  -d)   # DB connection
    DBCONN=$2
    shift ;;
  -h|*)   # Print usage otherwise
    show_usage
    exit $ERR ;;
  esac
  shift
done

# Verify parameters
if [ -z "$RCU_HOME" ] ; then
  msg MAIN ERROR "A valid directory location is required for the -h parameter."
  show_usage
  exit $ERR
fi
if [ -z "$DBCONN" ] ; then
  msg MAIN ERROR "A valid DB connection string is required for the -d parameter."
  show_usage
  exit $ERR
fi

# Run processing
create_tbs
create_pwd_file
extract_software
create_schemas
cleanup

# END
