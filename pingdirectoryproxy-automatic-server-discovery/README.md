# PingDirectoryProxy automatic server discovery

This directory contains a server profile for PingDirectoryProxy that includes an example configuration of [automatic server discovery](https://docs.pingidentity.com/r/en-us/pingdirectory-93/pd_proxy_auto_server_discovery). To use this profile, use the following environment variables:

```
SERVER_PROFILE_URL: https://github.com/pingidentity/pingidentity-server-profiles.git
SERVER_PROFILE_PATH: pingdirectoryproxy-automatic-server-discovery/pingdirectoryproxy
```

This profile uses example configuration values that assume a base DN of `dc=example,dc=com`.

See the [DevOps documentation](https://devops.pingidentity.com/deployment/deployPDProxyBackendDiscovery/) for more details on how to enable automatic server discovery.
