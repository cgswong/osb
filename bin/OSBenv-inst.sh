#!/bin/sh
######################################################
# NAME: OSBinst-env.sh
#
# DESC: Configures environment for Oracle Service Bus
#       (OSB) software installation.
#
# NOTE: Due to constraints of the shell in regard to environment
#       variables, the command MUST be prefaced with ".". If it
#       is not, then no permanent change in the user's environment
#       can take place.
#
# $HeadURL: $
# $LastChangedBy: cgwong $
# $LastChangedDate: $
# $LastChangedRevision: $
#
# LOG:
# yyyy/mm/dd [user] - [notes]
# 2014/03/04 cgwong - [v1.0.0] Creation.
# 2014/03/20 cgwong - [v1.1.0] Updated variables and formatting.
# 2014/03/21 cgwong - [v1.1.1] Corrected variable error for WL_HOME.
# 2014/03/25 cgwong - [v1.1.2] Updated JRockit JAVA_HOME.
#                     Removed WL variables.
#                     Corrected some variables.
# 2014/03/26 cgwong - [v1.1.3] Updated patch variables.
# 2014/04/18 cgwong: [v1.2.4] Removed unneeded variables and updated others. 
######################################################

# -- BASIC DIRECTORIES -- #
# Directory where the software to be installed is located
SLIB_DIR="/webtools/slib/osb" ; export SLIB_DIR

# The scripts create files that are placed in this directory
STG_DIR="/webtools/stage/osb" ; export STG_DIR

# Installation log directory
LOG_DIR="/webshare/weblogs/install" ; export LOG_DIR

# Directory from which installation is run
INSTALL_DIR=${SLIB_DIR}/Disk1 ; export INSTALL_DIR


# -- BASIC ORACLE VARIABLES -- #
# Base directory for installation
ORACLE_BASE="/www/web/product" ; export ORACLE_BASE

# Oracle inventory location
ORAINV_HOME="${ORACLE_BASE}/../oraInventory" ; export ORAINV_HOME

# Oracle inventory pointer file
ORAINV_PTR_FILE="/etc/oraInst.loc" ; export ORAINV_PTR_FILE

# Group under which the software needs to be installed
OINST_GRP="web" ; export OINST_GRP


# -- FMW STACK DIRECTORIES -- #
# Oracle Fusion Middleware software home
MW_HOME="${ORACLE_BASE}/fmw_1" ; export MW_HOME

# Oracle Service Bus (OSB) software home directory
# Append appropriate "_major.minor" version designation
OSB_HOME="${MW_HOME}/osb_11.1" ; export OSB_HOME

# OSB home name for Oracle inventory
OSB_HOME_NAME="OraHome1_osb11g"

# Oracle WebLogic Server (WLS) software home directory
# Append appropriate "_major.minor" version designation
WL_HOME="${MW_HOME}/wlserver_10.3" ; export WL_HOME

# WL home name for Oracle Inventory
WL_HOME_NAME="OraHome1_wls1036" ; export WL_HOME_NAME


# -- JVM INFO -- #
# Directory where the JVM will be run
JAVA_HOME="${ORACLE_BASE}/jrockit-jdk" ; export JAVA_HOME

# JVM home name for Oracle Inventory
JVM_HOME_NAME="OraHome1_JRockit6u45" ; export JVM_HOME_NAME


# -- DOMAIN INFO -- #
# Hostname of target installation server
TGT_HOST=`hostname -f` ; export TGT_HOST


# -- FILE INFO -- #
# Name of the OSB installation file
OSB_FILE=${SLIB_DIR}/ofm_osb_generic_11.1.1.7.0_disk1_1of1.zip ; export OSB_FILE

# Name of the OSB response installation file
OSB_RSP_FILE=${SLIB_DIR}/resp/osb11g-inst.rsp ; export OSB_RSP_FILE


# -- PATCH INFO -- #
# Patch bundle designation to apply
PB="osb_11117_pb1" ; export PB

# Patch bundle directory
PB_DIR=${SLIB_DIR}/patches/osb/${PB} ; export PB_DIR

# Patch cache directory
PB_CACHE_DIR=${PB_DIR}/cache_dir ; export PB_CACHE_DIR

# Name of the OCM response file
OCM_RSP_FILE=${SLIB_DIR}/resp/ocm.rsp ; export OCM_RSP_FILE
