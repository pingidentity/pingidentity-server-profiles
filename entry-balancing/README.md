# Entry Balancing Example Profile
These server profiles provide an example of an entry balanced deployment using PingDirectory and PingDirectoryProxy.

Entry balancing is only supported with version `2210` or later of the PingDirectory and PingDirectoryProxy Docker images.

Use these server profiles in combination with environment variables to deploy an example entry-balanced topology.

See [the corresponding Helm example](https://github.com/pingidentity/pingidentity-devops-getting-started/tree/master/30-helm/entry-balancing) for a full example of deploying a topology with entry balancing enabled.

In a real entry-balanced deployment, you will likely have to make modifications to both the PingDirectory and PingDirectoryProxy server profiles. For PingDirectoryProxy in particular, the `create-initial-proxy-config` tool will be useful to generate the final configuration.
