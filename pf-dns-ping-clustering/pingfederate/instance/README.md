# Purpose
This directory contains the data that is required to cluster PingFederate using the DNS_PING cluster discovery mechanism. This requires PingFederate Version 10 or later.

This profile is intended to be used as a layer with another profile on top, such as baseline, or getting-started. 

Example [docker-compose.yaml](https://github.com/pingidentity/pingidentity-devops-getting-started/tree/master/11-docker-compose/05-pingfederate-cluster)

This layer can be used for docker-compose as well as kubernetes.
The environment variables you supply are dependent on which orchestration tool you are using. 

## Relevant Variables

**DNS_QUERY_LOCATION**
In kubernetes this should be something like: 
`{k8sServiceName}.{k8sNamespace}.svc.cluster.local`

In docker this should be just the service name:
`pingfederate-admin`

**OPERATIONAL_MODE**
should be either `CLUSTERED_CONSOLE` or `CLUSTERED_ENGINE`

## Cautions and Additional Notes
When layering profiles, you may have files overwriting each other, beware of the implications of this and the order that you layer. For example, if you use this as a base layer and put another layer on top with a `run.properties.subst` file, that file should also be able to handle clustering. The baseline profile is an example where the `run.properties.subst` file is used to define external admin authentication and other LDAP specific functions, but it also has the `OPERATIONAL_MODE` variablized to not break clustering. 

