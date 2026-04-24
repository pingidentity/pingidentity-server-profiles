# PingDirectoryProxy automatic server discovery

This directory contains a server profile for PingDirectoryProxy that includes an example configuration of [automatic server discovery](https://docs.pingidentity.com/r/en-us/pingdirectory-93/pd_proxy_auto_server_discovery). To use this profile, use the following environment variables:

```text
SERVER_PROFILE_URL: https://github.com/pingidentity/pingidentity-server-profiles.git
SERVER_PROFILE_PATH: pingdirectoryproxy-automatic-server-discovery/pingdirectoryproxy
```

This profile uses example configuration values that assume a base DN of `dc=example,dc=com`.

For multi-region automatic discovery deployments, this profile also includes a startup hook that derives PingDirectoryProxy location failover settings from `K8S_CLUSTERS` and `K8S_CLUSTER`.

- The local proxy location is `K8S_CLUSTER`.
- By default, each non-local cluster listed in `K8S_CLUSTERS` is ensured as a peer location and added to the local location as a `preferred-failover-location`.
- Set `PREFERRED_FAILOVER_LOCATIONS` to use an explicit ordered subset of the non-local clusters in `K8S_CLUSTERS`.
- The hook only runs when `JOIN_PD_TOPOLOGY=true` and both `K8S_CLUSTERS` and `K8S_CLUSTER` are set.
- The hook connects to the local proxy with `localhost` for `dsconfig`, while preserving external `K8S_POD_HOSTNAME_*` values for topology and advertised server names.
- The hook is intended to be idempotent across restarts so the local proxy location converges back to the declared failover order.

See the [DevOps documentation](https://devops.pingidentity.com/deployment/deployPDProxyBackendDiscovery/) for more details on how to enable automatic server discovery.
