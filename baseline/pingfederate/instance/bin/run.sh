#!/usr/bin/env bash
### ====================================================================== ###
##                                                                          ##
##  PingFederate Bootstrap Script                                           ##
##                                                                          ##
### ====================================================================== ###

### $Id: run.sh,v 1.19.4.2 2004/12/15 16:54:03 starksm Exp $ ###

DIRNAME=`dirname "$0"`
PROGNAME=`basename "$0"`
GREP="grep"

# Use the maximum available, or set MAX_FD != -1 to use that
MAX_FD="maximum"

#
# Helper to complain.
#
warn() {
    echo "${PROGNAME}: $*"
}

#
# Helper to fail.
#
die() {
    warn $*
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false;
darwin=false;
linux=false;
sunos=false;
case "`uname`" in
    CYGWIN*)
        cygwin=true
        ;;

    Darwin*)
        darwin=true
        ;;

    Linux*)
        linux=true
        ;;

    SunOS*)
        sunos=true
        ;;
esac

# Read an optional running configuration file
if [ "x$RUN_CONF" = "x" ]; then
    RUN_CONF="$DIRNAME/run.conf"
fi
if [ -r "$RUN_CONF" ]; then
    . "$RUN_CONF"
fi

# For Cygwin, ensure paths are in UNIX format before anything is touched
if $cygwin ; then
    [ -n "$PF_HOME" ] &&
        PF_HOME=`cygpath --unix "$PF_HOME"`
    [ -n "$JAVA_HOME" ] &&
        JAVA_HOME=`cygpath --unix "$JAVA_HOME"`
fi

# Setup PF_HOME
if [ "x$PF_HOME" = "x" ]; then
    # get the full path (without any relative bits)
    PF_HOME=`cd "$DIRNAME/.."; pwd`
fi
export PF_HOME

# Set PF_HOME_ESC - this is PF_HOME but with spaces that are replaced with %20
PF_HOME_ESC=${PF_HOME// /%20}

PF_SERVER_HOME="$PF_HOME/server/default"

# Check for currently running instance of PingFederate
RUNFILE="$PF_HOME/bin/pingfederate.pid"
if [ ! -f "$RUNFILE" ] ; then
  touch "$RUNFILE"
  chmod 664 "$RUNFILE"
fi

CURRENT_PID=`cat "$RUNFILE"`
if [ -n "$CURRENT_PID" ] ; then
    kill -0 $CURRENT_PID 2>/dev/null
    if [ $? -eq 0 ] ; then
      /bin/echo "Another PingFederate instance with pid $CURRENT_PID is already running. Exiting."
      exit 1
    fi
fi

# Increase the maximum file descriptors if we can
if [ "$cygwin" = "false" ]; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ $? -eq 0 ]; then
    if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ]; then
        # use the system max
        MAX_FD="$MAX_FD_LIMIT"
    fi

        if [ "$darwin" = "false" ]; then
            ulimit -n $MAX_FD
            if [ $? -ne 0 ]; then
                 warn "Could not set maximum file descriptor limit: $MAX_FD"
            fi
        fi
    else
    warn "Could not query system maximum file descriptor limit: $MAX_FD_LIMIT"
    fi
fi

# Setup the JVM
if [ "x$JAVA" = "x" ]; then
    if [ "x$JAVA_HOME" != "x" ]; then
        if ! [ -n "$JAVA_HOME" ] || ! [ -x "$JAVA_HOME/bin/java" ];  then
            echo "No executable java found in JAVA_HOME, please correct and start PingFederate again. Exiting."
            exit 1
        fi
        JAVA="$JAVA_HOME/bin/java"
    else
        JAVA="java"
        warn "JAVA_HOME is not set.  Unexpected results may occur."
        warn "Set JAVA_HOME to the directory of your local JDK or JRE to avoid this message."
    fi
fi

JAVA_VERSION=`"$JAVA" -version 2>&1 | grep "version" | head -n 1 | cut -d\" -f 2 `
JAVA_MAJOR_VERSION=`echo ${JAVA_VERSION/_/.} | cut -d. -f 1`

# Setup the classpath
runjar="$PF_HOME/bin/run.jar"
if [ ! -f "$runjar" ]; then
    die "Missing required file: $runjar"
fi
pfrunjar="$PF_HOME/bin/pf-startup.jar"
if [ ! -f "$pfrunjar" ]; then
    die "Missing required file: $pfrunjar"
fi
jettystartjar="$PF_HOME/bin/jetty-start.jar"
if [ ! -f "$jettystartjar" ]; then
    die "Missing required file: $jettystartjar"
fi
xmlbeans="$PF_HOME/server/default/lib/xmlbeans.jar"
if [ ! -f "$xmlbeans" ]; then
    die "Missing required file: $xmlbeans"
fi
pfxml="$PF_HOME/server/default/lib/pf-xml.jar"
if [ ! -f "$pfxml" ]; then
    die "Missing required file: $pfxml"
fi

pf_console_util="$PF_HOME/bin/pf-consoleutils.jar"
pf_crypto_luna="$PF_HOME/server/default/lib/pf-crypto-luna.jar"

PF_BOOT_CLASSPATH="$runjar:$pfrunjar:$jettystartjar:$pf_console_util:$xmlbeans:$pfxml:$pf_crypto_luna"

if [ "x$PF_CLASSPATH" = "x" ]; then
    PF_CLASSPATH="$PF_BOOT_CLASSPATH"
else
    PF_CLASSPATH="$PF_CLASSPATH:$PF_BOOT_CLASSPATH"
fi

# If JAVA_OPTS is not set try check for Hotspot
if [ "x$JAVA_OPTS" = "x" ]; then

    # Check for SUN(tm) JVM w/ HotSpot support
    if [ "x$HAS_HOTSPOT" = "x" ]; then
    HAS_HOTSPOT=`$JAVA -version 2>&1 | $GREP -i HotSpot`
    fi

    # Enable -server if we have Hotspot, unless we can't
    if [ "x$HAS_HOTSPOT" != "x" ]; then
    # MacOS does not support -server flag
    if [ "$darwin" != "true" ]; then
        JAVA_OPTS="-server"
    fi
    fi
fi

# JVM Optimizations
# To configure JVM options please edit jvm-memory.options in
# <install-dir>/pingfederate/bin

jvmmemoryopts="$PF_HOME/bin/jvm-memory.options"

# Check for jvm-memory.options (used by PingFederate to set JVM memory settings)
if [ ! -f "$jvmmemoryopts" ]; then
    die "Missing $jvmmemoryopts"
fi

#Setup JVM Heap optimizations
JVM_MEMORY_OPTS=$( awk '/^-X/ { {printf "%s%1s\n", $0, ""}; }' "${jvmmemoryopts}" | tr -d '\n' )

JAVA_OPTS="$JAVA_OPTS $JVM_MEMORY_OPTS"

# Setup PingFederate specific properties
JAVA_OPTS="$JAVA_OPTS -Dprogram.name=$PROGNAME"

RANDOM_SOURCE="-Djava.security.egd=file:/dev/./urandom"
JAVA_OPTS="$JAVA_OPTS $RANDOM_SOURCE"

# Workaround for nCipher HSM to support Java 8
# Remove this when nCipher officially supports Java 8

JAVA_OPTS="$JAVA_OPTS -Dcom.ncipher.provider.announcemode=on"

# JAVA_OPTS="-Djetty51.encode.cookies=CookieName1,CookieName2 $JAVA_OPTS"

# Debugger arguments
#JAVA_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,address=8787,server=y,suspend=y $JAVA_OPTS"

# disable use of preallocated exceptions and always show the full stacktrace
JAVA_OPTS="$JAVA_OPTS -XX:-OmitStackTraceInFastThrow"

# Setup the java endorsed dirs
PF_ENDORSED_DIRS="$PF_HOME/lib/endorsed"

#comment out to disable java crash logs
ERROR_FILE="-XX:ErrorFile=$PF_HOME_ESC/log/java_error%p.log"

#uncomment to enable Memory Dumps
#HEAP_DUMP="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$PF_HOME_ESC/log"

# For Cygwin, switch paths to Windows format before running java
if $cygwin; then
    PF_HOME=`cygpath --path --windows "$PF_HOME"`
    JAVA_HOME=`cygpath --path --windows "$JAVA_HOME"`
    PF_CLASSPATH=`cygpath --path --windows "$PF_CLASSPATH"`
    PF_ENDORSED_DIRS=`cygpath --path --windows "$PF_ENDORSED_DIRS"`
fi

ENDORSED_DIRS_FLAG=``
if [ "$JAVA_MAJOR_VERSION" = "1" ]; then
    ENDORSED_DIRS_FLAG='-Djava.endorsed.dirs="$PF_ENDORSED_DIRS"'
fi

# Check for run.properties (used by PingFederate to configure ports, etc.)
runprops="$PF_HOME/bin/run.properties"
if [ ! -f "$runprops" ]; then
    warn "Missing run.properties; using defaults."
    runprops=""
fi

trap 'kill $PID; wait $PID; cat </dev/null 2>/dev/null >$RUNFILE' 1 2 3 6
trap 'kill -9 $PID; cat </dev/null >$RUNFILE 2>/dev/null' 15

STATUS=10
while [ $STATUS -eq 10 ]
do
# Execute the JVM
   "$JAVA" $JAVA_OPTS \
   	  $ERROR_FILE \
   	  $HEAP_DUMP \
      $ENDORSED_DIRS_FLAG \
   	  -Dlog4j2.AsyncQueueFullPolicy=Discard \
   	  -Dlog4j2.DiscardThreshold=INFO \
      -Dlog4j.configurationFile="$PF_HOME_ESC/server/default/conf/log4j2.xml" \
      -Drun.properties="$runprops" \
      -Dpf.home="$PF_HOME" \
      -Djetty.home="$PF_HOME" \
      -Djetty.base="$PF_HOME/bin" \
      -Djetty.server=com.pingidentity.appserver.jetty.PingFederateInit \
      -Dpf.server.default.dir="$PF_HOME"/server/default \
      -Dpf.java="$JAVA" \
      -Dpf.java.opts="$JAVA_OPTS -Drun.properties=$runprops" \
      -Dpf.classpath="$PF_CLASSPATH" \
      -classpath "$PF_CLASSPATH" \
      org.pingidentity.RunPF "$@" &
   PID=$!
   /bin/echo $PID 2>/dev/null >"$RUNFILE"
   wait $PID
   STATUS=$?

   cat </dev/null 2>/dev/null >"$RUNFILE"
   # if it doesn't work, you may want to take a look at this:
   #    http://developer.java.sun.com/developer/bugParade/bugs/4465334.html
done
