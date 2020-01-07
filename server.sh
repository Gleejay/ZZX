#!/bin/sh
# -----------------------------------------------------------------------------
# Environment Variable Prerequisites
#   JAVA_HOME
#   CLASSPATH
# -----------------------------------------------------------------------------
PRG="$0"
PRGDIR=`dirname "$PRG"`
FULL_PATH=`cd "$PRGDIR" ; pwd`
NAME=`basename $FULL_PATH`
PID_FILE="$FULL_PATH/pid"
DEBUG_PORT=58998
DEBUG_SUSPEND="n"

start()
{
  # Make sure that the program is not running!
  pid=`cat $PID_FILE`
  search=`ps ho user,pid,start_time,%cpu,%mem,size,cmd -p$pid`
  if [ -n "$search" ]
  then
    echo -e "################################################\n#"
    echo -e "# $NAME is running, which pid is $pid!\n#"
    echo -e "################################################\n"
    echo $search
    exit
  fi
  JAVA="java -server -Xms128m -Xmx256m"
  if [ -n "$1" -a "$1" = "debug" ]; then
    JAVA="$JAVA -Xdebug -Xrunjdwp:transport=dt_socket,address=$DEBUG_PORT,server=y,suspend=$DEBUG_SUSPEND"
  fi 
  CLASSPATH=$FULL_PATH
  for file in deploy-libs/*.jar
  do
    CLASSPATH=$CLASSPATH:$file
  done
  JAVA="$JAVA -cp $CLASSPATH net.easyits.deployer.Run"
  echo "Starting $NAME ......"
  # java -cp $CLASSPATH net.easyits.deployer.Run net.easyits.gateway.StandGateServer > $FULL_PATH/day.log 2>&1 &
  # $JAVA -Xdebug -Xrunjdwp:transport=dt_socket,address=58989,server=y,suspend=n -cp $CLASSPATH net.easyits.deployer.Run net.easyits.gateway.StandGateServer > $FULL_PATH/day.log 2>&1 & 
  $JAVA net.easyits.streamserver.MediaServer > $FULL_PATH/day.log 2>&1 &
  echo $! > $PID_FILE
}

stop()
{
  echo $"Stopping $NAME ......"
  pid=`cat $PID_FILE`
  kill -9 $pid
  echo "stop "$pid
}

restart()
{
  stop
  sleep 5
  start
}

status()
{
  pid=`cat $PID_FILE`
  echo "pid : $pid"
  search=`ps ho user,pid,start_time,%cpu,%mem,size,cmd -p$pid`
  if [ -z "$search" ]
  then
    echo "stand is not running"
  else
    echo $search
  fi
}

check()
{
  # Make sure prerequisite enviroment variables are set
  if [ -z "$JAVA_HOME" -a -z "$JRE_HOME" ]; then
    echo "Neither the JAVA_HOME nor the JRE_HOME is defined."
    echo "At least one of these is needed to run this program."
    exit 1
  fi
  if [ -z "$JAVA_HOME" ]; then
    JAVA_HOME=$JRE_HOME
  fi
  if [ ! -x "$JAVA_HOME"/bin/java ]; then
    echo "The JAVA_HOME is not defined correctly!"
    exit 1
  fi
  JAVA=$JAVA_HOME/bin/java
}

case "$1" in
start)
  shift
  start "$@"
  ;;
stop)
  stop
  ;;
restart)
  restart
  ;;
status)
  status
  ;;
debug)
  start "debug"
  ;;
*)
  status
  echo $"Usage: $0 {start|stop|restart|debug}"
  exit 1
esac

