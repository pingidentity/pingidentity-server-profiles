# Purpose
This directory contains the data that is required to customize PingFederate containers to 
taste. The file system structure must follow that of a PingFederate instance. These files 
are laid over a vanilla installation of PingFederate.

The files in instance/server/default/conf are configured to support clustering PingFederate
using the DNS_PING mechanism which was introduced in PingFederate Version 10. These files
are comparible with running a standalone PingFederate 10 instance but will break earlier
versions of PingFederate due to an incompatible change to hivemodule.xml.

# Variables

variable | Where Set
:------------------ | :-------------------------------------------------------------
USER_BASE_DN | pingdirectory/env_vars
OPERATIONAL_MODE | pingfederate/cluster/deployment.yaml
 | pingfederate/cluster/statefulset.yaml
PF_DNS_PING_CLUSTER |  pingfederate/cluster/env_vars
PF_DNS_PING_NAMESPACE | pingfederate/cluster/deployment.yaml
 | pingfederate/cluster/statefulset.yaml
