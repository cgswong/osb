# ! /bin/sh
######################################################
# NAME: OSBenv.sh
#
# DESC: Configures environment for Oracle Service Bus
#       (OSB) access.
#
# NOTE: Due to constraints of the shell in regard to environment
#       variables, the command MUST be prefaced with ".". If it
#       is not, then no permanent change in the user's environment
#       can take place.
#
# LOG:
# yyyy/mm/dd [user] - [version] [notes]
# 2014/01/07 cgwong - Creation.
# 2014/01/08 cgwong - [v1.0.0] Completed updates with OSB information
# 2014/01/15 cgwong - [v1.1.0] Added dynamic MW_HOME and DOMAIN_HOME
# 2014/01/16 cgwong - [v1.1.1] Updated NOTSET variables
# 2014/02/28 cgwong - [v1.1.2] Updated header comment
# 2014/03/04 cgwong - [v1.1.3] Updated variables
######################################################

# Functions #
pathman ()
{
# Function used to add non-existent directory (given as argument)
# to PATH variable.
  if ! echo ${PATH} | /bin/egrep -q "(^|:)$1($|:)" ; then
    PATH=$1:${PATH} ; export PATH
  fi
}

# Middleware variables #
# Use default middlware home if MW_NAME is not set,
# otherwise use command line parameter
MW_HOME=${2:-$MW_HOME}
MW_HOME=${MW_HOME:-"/www/web/product/fmw_1"} ; export MW_HOME
WL_HOME=$MW_HOME/wlserver_10.3     ; export WL_HOME
# Configure JVM argument to avoid config UI issues
CONFIG_JVM_ARGS="-Djava.security.egd=file:/dev/./urandom" ; export CONFIG_JVM_ARGS

# Domain variables #
# Use default domain if DOMAIN_NAME is not set,
# otherwise use command line parameter
DOMAIN_NAME=${1:-$DOMAIN_NAME}
DOMAIN_NAME=${DOMAIN_NAME:-"dom_soa_com"}  ; export DOMAIN_NAME
DOMAIN_HOME=/webapps/domains/$DOMAIN_NAME  ; export DOMAIN_HOME
DOMAIN_PORT=${3:-$DOMAIN_PORT}
DOMAIN_PORT=${DOMAIN_PORT:-"3001"}         ; export DOMAIN_PORT
DOMAIN_HOST=`hostname -f`                  ; export DOMAIN_HOST

# Misc. #


# Put new JAVA_HOME in path and remove old one if present
# Ensure that OLD_JAVA_HOME is non-null and use to store current JAVA_HOME if any
OLD_JAVA_HOME=${JAVA_HOME:-NOTSET}
JAVA_HOME=/www/web/product/jrockit-jdk ; export JAVA_HOME
case "$PATH" in
  *$OLD_JAVA_HOME*)
    PATH=`echo $PATH | sed "s;${OLD_JAVA_HOME};${JAVA_HOME};g"` ; export PATH ;;
  *)
    pathman $JAVA_HOME/bin ;;
esac

# Put new OSB binaries in path and remove old one if present
# Ensure that OLD_ORACLE_HOME is non-null and use to store current ORACLE_HOME if any
OLD_ORACLE_HOME=${ORACLE_HOME:-NOTSET}
ORACLE_HOME=$MW_HOME/$ORACLE_HOME_NAME ; export ORACLE_HOME
case "$PATH" in
  *$OLD_ORACLE_HOME*)
    PATH=`echo $PATH | sed "s;${OLD_ORACLE_HOME};${ORACLE_HOME};g"` ; export PATH ;;
esac
pathman $ORACLE_HOME/bin
pathman $ORACLE_HOME/common/bin
pathman $ORACLE_HOME/OPatch

pathman $DOMAIN_HOME
pathman $DOMAIN_HOME/bin

# Cleanup
unset pathman
