# Purpose
This directory provides a minimal PingFederate installation using PingDirectory as the
LDAP provider.The directory layout within the 'instance' directory needs to mirror the
structure of the pingfederate directory within the PingFederate install as its contents
overlays that of the vanilla installation.

This configuration is compatible with PingFederate Version 10.

# Parameters
The following environment variables are used to configure PingFederate

## bin/run.properties

OPERATIONAL_MODE: Used to select the operational mode for this instance,
see run.properties for details.

## server/default/conf/log4j2.xml

PF_LOG_LEVEL: Set the loging level for PingFederate, this is read via native
log4j code and does not need substitution.

## bin/ldap.properties

LDAP_PASSWORD::q


USER_BASE_DN:	

