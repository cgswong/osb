#!/bin/bash
######################################################
# NAME: OSBinst.sh
#
# DESC: Installs Oracle Service Bus (OSB) software.
#
# USAGE:
# ${SCRIPT} [OPTION]
#
# $HeadURL$
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# 
# LOG:
# yyyy/mm/dd [user] - [notes]
# 2014/02/09 cgwong - [v1.0.0] Creation.
# 2014/02/17 cgwong - [v1.0.1] Use basename instead of readlink.
# 2014/03/04 cgwong - [v1.1.0] Updated patching to be more verbose.
#                     Updated header comments and included usage function.
#                     Updated variables and command processing.
# 2014/03/20 cgwong - [v1.2.0] Updated environment file name.
#                     Updated variable names.
#                     Removed repository creation code.
# 2014/03/21 cgwong - [v1.3.0] Updated msg to use double ticks.
#                     Included command line argument.
#                     Other improvements and bug fixes.
# 2014/03/25 cgwong - [v1.4.0] Updated empty directory check.
#                     Removed WL installation.
#                     Added response file processing.
#                     Integrate patching into installation (via silent response file).
# 2014/03/25 cgwong - [v1.4.1] Included inventory update for WL and JVM.
#                     Updated runInstaller and patching logic
# 2014/04/18 cgwong: [v1.4.2] Various minor code improvements.
######################################################

SCRIPT=`basename $0`
SCRIPT_PATH=$(dirname $SCRIPT)
SETUP_FILE=${SCRIPT_PATH}/OSBenv-inst.sh

##. ${SETUP_FILE}

# -- Variables -- #
PID=$$
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
  [[ -n $LOGFILE ]] && echo -e "[${TIMESTAMP}],PRC: ${1},PID: ${PID},HOST: ${TGT_HOST},USER: ${USER}, STATUS: ${2}, MSG: ${3}" | tee -a $LOGFILE
}

show_usage ()
{ # Show script usage
  echo "
 ${SCRIPT} - Linux shell script to install Oracle Service Bus 11g software.
  Specifically, the following steps are done:
  
  1. Install the specified OSB 11g software release
  2. Apply any patches as specified to OSB installation
  
  The default environment setup file, ${SETUP_FILE}, is assumed to be in the same directory
  as this script. The -f parameter can be used to specify another file or location. It is 
  assumed that the dependent JRockit and WLS have already installed and patched with any 
  required patches for OSB.

 USAGE
 ${SCRIPT} [OPTION]
 
 OPTIONS
  -f [path/file]
    Full path and file name for OSB settings file to be used. 
  
  -h
    Display this help screen.    
"
}

create_silent_install_files() 
{ # Create/setup installation response files
  # Setup OSB response file
  if [ -f "${OSB_RSP_FILE}" ]; then
    msg create_silent_install_file INFO "Creating OSB silent install files..."
    cat ${OSB_RSP_FILE} | sed "/ORACLE_HOME=/c\ORACLE_HOME=${OSB_HOME}" | sed "/MIDDLEWARE_HOME=/c\MIDDLEWARE_HOME=${MW_HOME}" | sed "/WL_HOME=/c\WL_HOME=${WL_HOME}" | sed "/SOFTWARE_UPDATES_DOWNLOAD_LOCATION=/c\SOFTWARE_UPDATES_DOWNLOAD_LOCATION=${PB_DIR}" > ${STG_DIR}/`basename ${OSB_RSP_FILE}`
    ## Need to add code for updating patch location ##
    OSB_RSP_FILE=${STG_DIR}/`basename ${OSB_RSP_FILE}`    # Reset variable to new value for easier referencing in script
  else
    msg create_silent_install_file ERROR "Missing silent install file: ${OSB_RSP_FILE}"
    exit $ERR
  fi
  
  # Process inventory file
  if [ ! -f "${ORAINV_PTR_FILE}" ]; then
    msg create_silent_install_files INFO "Creating temporary Oracle Inventory file..."
    echo "inventory_loc=${ORAINV_HOME}" > ${STG_DIR}/`basename ${ORAINV_PTR_FILE}`
    echo "inst_group=${OINST_GRP}"     >> ${STG_DIR}/`basename ${ORAINV_PTR_FILE}`
    ORAINV_PTR_FILE=${STG_DIR}/`basename ${ORAINV_PTR_FILE}` ; export ORAINV_PTR_FILE
    msg create_silent_install_files NOTE "Ensure ${ORAINV_PTR_FILE} is put under /etc and owned by root with permissions 770."
  else
    msg create_silent_install_files NOTE "Oracle Inventory file ${ORAINV_PTR_FILE} exists."
    msg create_silent_install_files INFO "${ORAINV_PTR_FILE}: `cat ${ORAINV_PTR_FILE}`"
  fi
}

install_osb ()
{ # Install OSB software
  # Check if software has already been extracted
  if [ -f ${INSTALL_DIR}/runInstaller ]; then
    msg install_osb INFO "Running software installation."
  else                          # Need to install software
    msg install_osb INFO "Extracting software..."
    unzip -oq ${OSB_FILE} -d ${SLIB_DIR}
  fi
  ${INSTALL_DIR}/runInstaller -jreLoc ${JAVA_HOME} -silent -responseFile ${OSB_RSP_FILE} -invPtrLoc ${ORAINV_PTR_FILE} ORACLE_HOME_NAME=${OSB_HOME_NAME} -waitforcompletion
  
  # Attach WLS component and JDK to Oracle inventory
  msg install_osb INFO "Attaching WLS and JVM homes to Oracle inventory."
  ${OSB_HOME}/oui/bin/runInstaller -attachHome ORACLE_HOME=${WL_HOME} ORACLE_HOME_NAME=${WL_HOME_NAME}
  ${OSB_HOME}/oui/bin/runInstaller -attachHome ORACLE_HOME=${JAVA_HOME} ORACLE_HOME_NAME=${JVM_HOME_NAME}
}

patch_osb ()
{ # Apply patches to OSB
  if [ `ls ${PB_DIR}/*.zip 2>/dev/null | wc -l` -gt 0 ]; then   # Not empty directory
    # Apply latest OPatch first
    if [ `ls ${PB_DIR}/p6880880*.zip 2>/dev/null | wc -l` -gt 0 ]; then   # File exists
      msg patch_osb INFO "Applying latest OPatch in repository to ${OSB_HOME}."
      unzip -oq ${PB_DIR}/p6880880*.zip -d ${OSB_HOME}
    fi
    
    # Apply other patches
    if [ ! -d ${PB_CACHE_DIR} ]; then
      msg patch_osb INFO "Creating cache dir: ${PB_CACHE_DIR}"
      mkdir -p ${PB_CACHE_DIR}
    fi

    CURR_DIR=${PWD}   # Save current directory
    msg patch_osb INFO "Applying OSB patches in repository."
    for fname in `ls -1 ${PB_DIR}/p1*.zip 2>/dev/null`; do
      unzip -oq ${fname} -d ${PB_CACHE_DIR}
      patchname=`basename ${fname} | cut -d 'p' -f2 | cut -d '_' -f1`
      cd ${PB_CACHE_DIR}/${patchname}
      ${OSB_HOME}/OPatch/opatch apply -oh ${OSB_HOME} -jdk ${JAVA_HOME} -jre ${JAVA_HOME}/jre -silent -ocmrf ${OCM_RSP_FILE}
    done
    
    cd ${CURR_DIR}    # Return to original directory
    msg patch_osb INFO "Cleaning up cache dir: ${PB_CACHE_DIR}"
    rm -rf ${PB_CACHE_DIR}
  else    # Empty directory
    msg patch_osb INFO "No zipped patches found to apply in ${PB_DIR}."
  fi
}

# -- Main Code -- #
# Process command line
while [ $# -gt 0 ] ; do
  case $1 in
  -f)   # Different OSB setup file
    SETUP_FILE=$2
    if [ -z "$SETUP_FILE" ] || [ ! -f "$SETUP_FILE" ]; then
      echo "ERROR: Invalid -f option."
      show_usage
      exit $ERR
    fi
    shift ;;
  -h)   # Print help and exit
    show_usage
    exit $SUC ;;
  *)   # Print help and exit
    show_usage
    exit $ERR ;;
  esac
  shift
done

# Setup environment
. ${SETUP_FILE}

LOGFILE=${LOG_DIR}/`echo $SCRIPT | awk -F"." '{print $1}'`.log

RUN_DT=`date "+%Y%m%d-%H%M%S"`
STG_DIR=${STG_DIR}/install-${RUN_DT}
[ ! -d "${STG_DIR}" ] && mkdir -p ${STG_DIR}

create_silent_install_files
install_osb
patch_osb

# END
