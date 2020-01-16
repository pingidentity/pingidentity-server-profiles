# Purpose
This server profile aims at providing a richer featured PingFederate configuration 
that can also include deploying PingFederate Artifacts (Integration Kits).

## artifacts
PingFederate Artifacts (Integration Kits) can be deployed through the following file.

- artifacts/artifact-list.json

This requires an artifact repo available through the environment variable 
ARTIFACT_REPO_URL. The format of the artifact-list.json is as follows,

[
  {
    "name": "<ARTIFACT_1_NAME)>",
    "version": "<ARTIFACT_1_VERSION>>"
  },
  {
    "name": "<ARTIFACT_2_NAME>",
    "version": "<ARTIFACT_2_VERSION>"
  },
]

## hooks
This directory contains shell script example that are executed when the container 
comes up

## instance
This directory is intended to hold the minimal configuration needed to bring up
a tenant, it should not contain any 'customer centric' configuration such as
OAuth client definition or applications in PingAccess. It should contain the
minimal configuration needed to bring up PF using PD for admin authentication
and PA using the PF instance as token provider.