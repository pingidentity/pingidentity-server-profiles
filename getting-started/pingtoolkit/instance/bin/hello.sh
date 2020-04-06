#!/usr/bin/env sh

echo "
##########################################
# Hello from the Ping Tool Kit Container!
#
#     Date: $(date)
# Hostname: $(hostname)
##########################################
"

set -e
aws --version
kubectl version --client
kustomize version
set +e