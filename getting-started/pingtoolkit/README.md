# Purpose
This repository serves as an example of how scripts and configuration can be stored and 
passed into a Ping Tool Kit container for runtime.

## Default Execution of Container
If the Ping Tool Kit is run with a default defition (i.e. no environment variables), the resulting container will be a simply Alpine container with the PingCommon hooks that prepare the container
like any Ping Docker Image.

### Example Run
```
docker run -d --name pingtoolkit pingidentity/pingtoolkit:edge

docker container ls
# CONTAINER ID   IMAGE                           ... NAMES
# ............   pingidentity/pingtoolkit:edge   ... pingtoolkit

docker container exec -it pingtoolkit sh
##################################################################################
#                Ping Identity DevOps Docker Image
#
#       Version: pingtoolkit-alpine-1.0.0-200224-...
#   DevOps User:
#      Hostname: ............
#       Started: Tue Feb 25 14:32:29 UTC 2020
##################################################################################
##################################################################################
#PingToolkit:............:/opt
#> 
```

## Initializing Ping Tool Kit with a Server Profile
Because the Ping Tool Kit are provided, those those profiles will be included into image.  You can
also have layers of server profiles.  More information that can be found at ____URL FOR LAYERS___

As with all Ping Docker images, the contents of the server profile will be placed into the 
containres `/opt/staging` directory.  There is a special directory, `instance`, that if 
found in the server profile at the top layer will be placed into the `/opt/out/instance` directory.

| Server Profile      | Container Directory |
|---------------------|---------------------|
| /*                  | /opt/staging        |
| /instance           | /opt/out/instance   |

### Example Server Profile
There is an example profile provided in the Ping Identity Server Profiles examples under
standalone/pingtoolkit location.

```
docker run -d --name pingtoolkit \
       --env SERVER_PROFILE_URL=https://github.com/pingidentity/pingidentity-server-profiles.git \
       --env SERVER_PROFILE_PATH=getting-started/pingtoolkit \
       pingidentity/pingtoolkit:edge

docker container exec -it pingtoolkit sh
# run following command in container

ls /opt/staging
# contents from your server profile is listed 
```

## Execution of commands in Ping Tool Kit Container
When the Ping Tool Kit container starts up, the default execution, if the environment variables ( `STARTUP_COMMAND` and `STARTUP_FOREGROUND_OPTS`) are not set, will be to place the container in a
holding state with a `tail -f /dev/null` command.  This will allow you to `docker exec ...` into
the container.

If the variables `STARTUP_COMMAND` and `STARTUP_FOREGROUND_OPTS` are set, they will be run 
when the container starts up and upon completion, the container will die.

| STARTUP Variables      | Execution           |
|----------------------------|---------------------|
| *** default ***            | tail -f /dev/null        |
| STARTUP_COMMAND=ls<br>STARTUP_FOREGROUND_OPTS="-l /opt"         | ls -l /opt   |

### Example Execution
The following example will startup a Ping Tool Kit and simply list the /opt directory and 
immediately die upon finishing the listing.

```
docker run \
       --env STARTUP_COMMAND=ls \
       --env STARTUP_FOREGROUND_OPTS="-l /opt" \
       pingidentity/pingtoolkit:edge
# ...
# ----- Starting hook: /opt/staging/hooks/50-before-post-start.sh
# 
# Starting server in foreground: (ls -l /opt)
# total 75200
# drwxrwxrwx    2 root     root          4096 Mar  5 16:50 backup
# -rwxrwxrwx    1 ping     identity      6175 Mar  3 23:00 bootstrap.sh
# -rwxrwxrwx    1 ping     identity      4493 Feb  4 16:48 entrypoint.sh
# ...
```

## Execution of script from Server Profile in Ping Tool Kit Container
To execute a script from a server profile in a Ping Tool Kit container, the combination 
`SERVER_PROFILE_...` and `STARTUP_...` variables can be used to achieve this.

The use case for this might be to have an init container perform some steps prior to a 
Deployment or StatefulSet set of containers in a Kubernetes cluster.


### Example Execution
The Ping Tool Kit Getting-Started Server Profile has a sample `hello.sh` that can be run
from the `/opt/out/instance/bin` directory int he container.  The example below shows 
how this can be acheived.

```
docker run \
       --env SERVER_PROFILE_URL=https://github.com/pingidentity/pingidentity-server-profiles.git \
       --env SERVER_PROFILE_PATH=getting-started/pingtoolkit \
       --env STARTUP_COMMAND=/opt/out/instance/bin/hello.sh \
       pingidentity/pingtoolkit:edge

# ...
########################################
# Hello from the Ping Tool Kit Container!
#
#     Date: Tue Feb 25 15:37:42 UTC 2020
# Hostname: *********
########################################
```