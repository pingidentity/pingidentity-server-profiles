# Purpose
This server profile aims at providing a richer featured PingDirectory configuration that can them be used with PingFederate

## config
This directory contains various config batch fragments that are assembled and applied together to set the instance up

## data
This directory contains data to get a sample data set ready as soon as the container is up and running

## extensions
Extensions should come from an artifact repository that's accessible over https. The artifact repo should be plugged into a
file with extension .remote.list under the extensions directory.

## hooks
This directory contains shell script example that are executed when the container comes up

## instance
This directory may be used to apply any other file directly to the instance.
See [the basic server profile](https://github.com/pingidentity/server-profile-pingdirectory-basic) for details