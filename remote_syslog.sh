#!/bin/bash

### BEGIN INIT INFO
# Provides: remote_syslog
# Required-Start: $network $remote_fs $syslog
# Required-Stop: $network $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start and Stop
# Description: Runs remote_syslog
### END INIT INFO

#       /etc/init.d/remote_syslog
#
# Starts the remote_syslog daemon
#
# chkconfig: 345 90 5
# description: Runs remote_syslog
#
# processname: remote_syslog
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"|", "'$prefix'",vn, $2, $3);
      }
   }'
}

prog="remote_syslog"
config="/etc/log_files.yml"
pid_dir="/var/run"

IFS="|" read -a options <<< $(parse_yaml $config)

# echo $hosts_worldofescapes

EXTRAOPTIONS=""

pid_file="$pid_dir/$prog.pid"

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH

RETVAL=0

is_running(){
  # Do we have PID-file`s?
  for i in "${options[@]}"; do
    if [[ "$i" =~ hosts_([A-Za-z]+)=\"(.+)\" ]] && app=${BASH_REMATCH[1]}; then
      pid_file="$pid_dir/$prog.$app.pid"
      if [ -f "$pid_file" ]; then
        # Check if proc is running
        pid=`cat "$pid_file" 2> /dev/null`
        if [[ $pid != "" ]]; then
          exepath=`readlink /proc/"$pid"/exe 2> /dev/null`
          exe=`basename "$exepath"`
          if [[ $exe == "remote_syslog" ]] || [[ $exe == "remote_syslog (deleted)" ]]; then
            # Process is running
            return 0
          fi
        fi
      fi
    fi
  done
  return 1
}

start(){
  echo "Starting $prog"
  
  unset HOME MAIL USER USERNAME
  
  for i in "${options[@]}"; do
    if [[ "$i" =~ hosts_([A-Za-z]+)=\"(.+)\" ]] && app=${BASH_REMATCH[1]} && log=${BASH_REMATCH[2]}; then
      pid_file="$pid_dir/$prog.$app.pid"
      $prog -c $config --pid-file=$pid_file --hostname $app $log $EXTRAOPTIONS
    fi
  done  
  
  RETVAL=$?
  return $RETVAL
}

stop(){
  echo "Stopping $prog..."

  if is_running; then
    for i in "${options[@]}"; do
      if [[ "$i" =~ hosts_([A-Za-z]+)=\"(.+)\" ]] && app=${BASH_REMATCH[1]} && log=${BASH_REMATCH[2]}; then
        pid_file="$pid_dir/$prog.$app.pid"
        test -f $pid_file && nxt='' || continue
        kill -TERM `cat $pid_file` >/dev/null 2>&1
        sleep 1
        if is_running && sleep 1 &&
          is_running && sleep 3 &&
          is_running ; then
          test -f $pid_file && nxt='' || continue
          kill -KILL `cat $pid_file` >/dev/null 2>&1
          sleep 1
        fi

        if is_running; then
          echo "Failed to kill process"
          RETVAL=1
        else
          echo "Stopped"
          RETVAL=0
          rm -f $pid_file
        fi
      fi
    done
  else
    echo "Not running"
    RETVAL=0
  fi

  return $RETVAL
}

status(){
  if (is_running); then
    echo "Running"
    RETVAL=0
  else
    echo "Not running"
    RETVAL=3
  fi

  return $RETVAL
}

reload(){
  restart
}

restart(){
  stop
  start
}

condrestart(){
  is_running && restart
  return 0
}


# See how we were called.
case "$1" in
    start)
  start
  ;;
    stop)
  stop
  ;;
    status)
  status
  ;;
    restart)
  restart
  ;;
    reload)
  reload
  ;;
    condrestart)
  condrestart
  ;;
    *)
  echo $"Usage: $0 {start|stop|status|restart|condrestart|reload}"
  RETVAL=1
esac

exit $RETVAL