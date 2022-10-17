# Entry Balancing Example Profile
This server profile provides an example of an entry balanced deployment using PingDirectory and PingDirectoryProxy.

Use this server profile in combination with environment variables to deploy an example entry balanced topology.

See the corresponding Helm example here for a full example of deploying a topology with entry balancing enabled.

In a real entry-balanced deployment, you will likely have to make modifications to both the PingDirectory and PingDirectoryProxy server profiles. For PingDirectoryProxy in particular, the `create-initial-proxy-config` tool will be useful to generate the correct configuration.
