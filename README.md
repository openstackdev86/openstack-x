openstack-x
===========

### Overview
============
OpenStack-X is a simple openstack tool for controlling the openstack's services conveniently. 

A simple example:

* `./openstack-x.sh all restart` - This command will restart all the service in your config file

This script will create a config file `~/openstack_services.ini`. You can configure this file through editing this file directly or using this script.

### Usage
===========

This script is used for managing the openstack's services. Most of the time,we want to lanuch, start, restart or check nova project or nova-api service, or maybe the whole openstack simplely! Now you can use this script to complete the target!

    Usage: $0 [OPTION]...

        -h --help     print the help information
        -s --show     show the config file
        -v --version  show the version
        --add-project add a new project to the ~/.openstack_services.ini
        --del-project del a project in ~/.openstack_services.ini
        --add-service add a new service to a project in ~/.openstack_services.ini
        --del-service del a service in ~/.openstack_services.ini

        [all|project|service] [start|stop|restart|status]

        Example:
        openstack-x.sh all  start     # this will try to start all services in config file
        openstack-x.sh nova start     # this will try to start all nova services specified in config file
        openstack-x.sh nova-api start # this just try to start  only nova-api services
