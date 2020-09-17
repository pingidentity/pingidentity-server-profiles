# Purpose
This directory contains the data that is required to cluster PingFederate using the NATIVE_S3_PING cluster discovery mechanism. This requires PingFederate Version 10 or later.  This is to address the specific use case of trying to cluster PingFederate using multiple kubernetes clusters.  This uses NATIVE_S3_PING as an alternative to DNS_PING.  This also implements regional adaptive clustering.This is an advanced use case that requires extensive AWS network setup beforehand, and additional required environment variables.

This profile is intended to be used as a layer with another profile on top, such as baseline, or getting-started. 

## Relevant Environment Variables

**S3_BUCKET_NAME**
Name of the AWS S3 bucket used to store the cluster list of PingFederate servers, this can be something like: 
`pf-cluster-list`

**S3_BUCKET_REGION**
The AWS region where the S3 bucket resides i.e. 'us-west-2'

**OPERATIONAL_MODE**
should be either `CLUSTERED_CONSOLE` or `CLUSTERED_ENGINE`

**PF_NODE_GROUP_ID**
Region identifier for adaptive clustering, could potentially line up with AWS regions like:
`us-west-2`

## Cautions and Additional Notes
When layering profiles, you may have files overwriting each other, beware of the implications of this and the order that you layer. For example, if you use this as a base layer and put another layer on top with a `run.properties.subst` file, that file should also be able to handle clustering. The baseline profile is an example where the `run.properties.subst` file is used to define external admin authentication and other LDAP specific functions, but it also has the `OPERATIONAL_MODE` variablized to not break clustering. 

