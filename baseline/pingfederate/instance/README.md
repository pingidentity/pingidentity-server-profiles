# Purpose
This directory contains the data that is required to customize PingFederate containers to 
taste. The file system structure must follow that of a PingFederate instance. These files 
are laid over a vanilla installation of PingFederate.

The files in instance/server/default/conf are configured to support clustering PingFederate
using the DNS_PING mechanism which was introduced in PingFederate Version 10. These files
are comparible with running a standalone PingFederate 10 instance but will break earlier
versions of PingFederate due to an incompatible change to hivemodule.xml.
