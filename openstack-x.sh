#!/bin/bash

declare -a PROJECTS
declare -a SERVICES
CONFIG_FILE=~/.openstack_services.ini
PROG=$0
VERSION=0.1

RES_COL=60
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[1;39m"

function echo_result {
    $MOVE_TO_COL
    echo -n "["
    if [ $1 -eq 0 ]; then
        $SETCOLOR_SUCCESS
        echo -n $"  OK  "
    else
        $SETCOLOR_FAILURE
        echo -n $"FAILED"
    fi
    $SETCOLOR_NORMAL && echo -n "]"
    echo -ne "\n\r"
    return 0
}

function show_error {
    if [ "$2" = 'show_help' ]; then
        usages
        echo " "
    fi
    echo $1
    exit 1
}

function show {
    echo "config file: " $CONFIG_FILE
    cat $CONFIG_FILE
}

function parse_config {
    pcount=0
    scount=0
    while read line
    do
        if [ "${line:0:1}" = "[" ] && [ "${line:(-1):1}" = "]" ]; then
            PROJECTS[$pcount]=${line:1:${#line}-2}
            pcount=$[ $pcount + 1 ]
        elif [ "${line:0:1}" != "[" ] && [ "${line:(-1):1}" != "]" ]; then
            SERVICES[$scount]=${PROJECTS[$pcount-1]}@${line}
            scount=$[ $scount + 1 ]
        else
            echo "Check the format of config file $CONFIG_FILE : $line"
            exit 1
        fi
    done < $CONFIG_FILE
}

if [ ! -e $CONFIG_FILE ]; then
    # here we try to create the file
    touch $CONFIG_FILE
    echo "[keystone]" >> $CONFIG_FILE
    echo "keystone" >> $CONFIG_FILE
    echo "[glance]" >> $CONFIG_FILE
    echo "glance-api" >> $CONFIG_FILE
    echo "glance-registry" >> $CONFIG_FILE
    echo "[cinder]" >> $CONFIG_FILE
    echo "cinder-api" >> $CONFIG_FILE
    echo "cinder-volume" >> $CONFIG_FILE
    echo "cinder-scheduler" >> $CONFIG_FILE
    echo "[nova]" >> $CONFIG_FILE
    echo "nova-api" >> $CONFIG_FILE
    echo "nova-cert" >> $CONFIG_FILE
    echo "nova-compute" >> $CONFIG_FILE
    echo "nova-conductor" >> $CONFIG_FILE
    echo "nova-scheduler" >> $CONFIG_FILE
    echo "nova-novncproxy" >> $CONFIG_FILE
    echo "nova-consoleauth" >> $CONFIG_FILE
    echo "[other]" >> $CONFIG_FILE
    echo "httpd" >> $CONFIG_FILE
fi

parse_config

function usages {
    echo "This script is used for managing the openstack's services. Most of the time,"
    echo "we want to lanuch or check nova project or nova-api service, now you can use"
    echo "this script to complete the target!"
    echo ""
    echo "www.choudan.net     liuanaqi@gmail.com"
    echo ""
    echo "Usage: $0 [OPTION]..." 
    echo ""
    echo "   -h --help     print the help information"
    echo "   -s --show     show the config file"
    echo "   -v --version  show the version"
    echo "   --add-project add a new project to the ~/.openstack_services.ini"
    echo "   --del-project del a project in ~/.openstack_services.ini"
    echo "   --add-service add a new service to a project in ~/.openstack_services.ini"
    echo "   --del-service del a service in ~/.openstack_services.ini"
    echo ""
    echo "   [all|project|service] [start|stop|restart|status]"
    echo ""
    echo "   ATTENTION:"
    echo "   --add-service <group name> <service name | service name = args> # some services need more launch parameters,"
    echo "                 so we should specify in config file like this; service_name=--config-file /etc/XXX/XXX.ini"
    echo ""
    echo "" 
    echo "Example:"
    echo "openstack-x.sh all  start     # this will try to start all services in config file"
    echo "openstack-x.sh nova start     # this will try to start all nova services specified in config file" 
    echo "openstack-x.sh nova-api start # this just try to start  only nova-api services"
    echo "" 
    echo "openstack-x.sh --add-service neutron neutron-server=--config-file /etc/neutron/api-paste.ini --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini"
    echo ""
    echo "You can get the newest version from github"
}



function execute {
    service_name=`echo $1 | cut -d '=' -f 1`
    if [ -e "/etc/init.d/$1" ]; then
        service $service_name $2
    elif [ -e "/etc/init.d/openstack-$1" ]; then
        service openstack-$service_name $2
    else # we just launch it directly
        which $service_name > /dev/null
        if [ $? == 0 ]; then
            # now we try to get the argments!
            args=""
            if [ "$1" != "$service_name" ];then
                args=`echo $1 | cut -d '=' -f 2`
            fi
            ps -ef | grep $service_name | grep -v grep | grep -v $PROG > /dev/null
            result=$?
            if [ $result -ne 0 ] && [ "$2" = "start" ]; then
                echo -n "Starting $service_name:"
                nohup $service_name $args &>/dev/null 2>&1   
                echo_result $?
            elif [ $result -eq 0 ] && [ "$2" = "start" ]; then
                echo "$service_name is already running!"
            elif [ $result -ne 0 ] && [ "$2" = "stop" ]; then
                echo "$service_name is already stopped!"
            elif [ $result -eq 0 ] && [ "$2" = "stop" ]; then
                # now we try to stop this service
                echo -n "Stopping $service_name:"
                kill -9 `ps -ef | grep $service_name | grep -v grep | grep -v $PROG | awk '{print $2}'` > /dev/null 2>&1
                echo_result $?
            fi
        else
            show_error "ERROR: Are you should you have installed $1 correctly? "
        fi
    fi
}

function status {
    service_name=`echo $1 | cut -d '=' -f 1`
    if [ -e "/etc/init.d/$1" ]; then
        service $service_name status
    elif [ -e "/etc/init.d/openstack-$1" ]; then
        service openstack-$service_name status
    else
        ps -ef | grep $service_name | grep -v grep | grep -v $PROG > /dev/null
        result=$?
        if [ $result -eq 0 ];then
            echo "$service_name is running"
        else
            echo "$service_name is stopped"
        fi
    fi
}


function handle_command {
    case $2 in
        start | stop)
            execute $1 $2;;
        restart)
            execute $1 "stop"
            execute $1 "start"
            ;;
        status)
            status $1;;
        *)
            show_error "ERROR: Unexpected args!  [start | stop | restart | status]"
            exit 1
    esac
}

function all_services {
    for service in ${SERVICES[@]}; do
        handle_command `echo $service | cut -d '@' -f 2` ${1};
    done
}

function process_commands {
    if [ $# -ne 2 ]; then
        show_error "ERROR: You should provide two args! " "show_help"
    fi
    if [ "$1" = "all" ]; then
        all_services ${2};
    else
        for project in ${PROJECTS[@]} ; do
            if [ "$project" = "$1" ]; then # that means launch project
                for service in ${SERVICES[@]}; do
                    if [ `echo $service | cut -d '@' -f 1`  = "$project" ]; then
                        handle_command `echo $service | cut -d '@' -f 2` ${2};
                    fi
                done
                return
            fi
        done
        for service in ${SERVICES[@]}; do  
            serv=`echo $service | cut -d '@' -f 2`
            if [ "$serv" = "$1" ]; then
                handle_command $serv ${2}
                return
            fi
        done
        show_error "ERROR: Can't find $1 in config file!"
    fi
}

function addproject {
    if [ $# -ne 1 ]; then
        echo "Usage: --add-project"
        echo "  ./openstackX.sh --add-project <project name>"
        exit 1
    fi
    # first we should check wether this group is already exist
    # TODO
    for project in ${PROJECTS[@]}; do
        if [ "$project" = "$1" ];then
            echo "This project already exists!"
            return
        fi
    done
    # we try to add this to config file
    echo "[$1]" >> $CONFIG_FILE
}

function delservice {
    if [ $# -ne 1 ]; then
        echo "Usage: --del-service"
        echo "  ./openstack-x.sh --del-service <service name>"
        exit 1
    fi
     
    echo -n "Deleting service $1"
    sed -i "/^$1/d" $CONFIG_FILE > /dev/null 2>&1
    echo_result $?
}

function delproject {
    # we will delete all services belongs to this project
    if [ $# -ne 1 ]; then
        echo "Usage: --del-project"
        echo "  ./openstack-x.sh --del-project <project name>"
        exit 1
    fi
    echo -n "Deleting project $1"
    sed -i "/^\[$1\]/d" $CONFIG_FILE
    result=$?
    echo_result $result
    if [ $result -eq 0 ];then
        for service in ${SERVICES[@]}; do
            if [ `echo $service | cut -d '@' -f 1`  = "$1" ]; then
                delservice `echo $service | cut -d '@' -f 2`  > /dev/null    
            fi
        done
    fi
}

function addservice {
    if [ $# -lt 2 ]; then
        echo "Usage: --add-service"
        echo "  ./openstack-x.sh --add-service <project name> <service name | service_name=launch_parameters>"
        exit 1
    fi
    lineno=`grep -rn "\[$1\]" $CONFIG_FILE  | awk -F ':' '{print $1}'`
    if [ "$lineno" = "" ];then # creat the project then add the service
        echo -n "Adding `echo $2 | cut -d '=' -f 1` to $1"
        echo "[$1]" >> $CONFIG_FILE
        echo "${@:2}" >> $CONFIG_FILE
        echo_result $?
        return
    fi
    delservice `echo $2 | cut -d '=' -f 1` > /dev/null
    args=${@:2}
    echo -n "Adding `echo $2 | cut -d '=' -f 1` to $1"
    sed -i "$lineno s:$:\n$args:" $CONFIG_FILE > /dev/null 2>&1
    echo_result $?
}

case $1 in
    -h|--help | "") usages;;
    -v|--version) echo "version: $VERSION";;
    -s|--show) show;;
    --add-project)
        addproject ${@:2}
        ;;
    --del-project)
        delproject ${@:2}
        ;;
    --add-service)
        addservice ${@:2}
        ;;
    --del-service)
        delservice ${@:2}
        ;;
    *)
        process_commands ${@};;

esac

exit 0
