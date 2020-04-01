#!/usr/bin/env sh
while true ; do 
  ready=$(kubectl get sts/pingdirectory | grep pingdirectory | awk '{ print $2}' | awk -F'\' '{ print $1}')
  requested=$(kubectl get sts/pingdirectory | grep pingdirectory | awk '{ print $2}' | awk -F'\' '{ print $3}')
  test "$ready" = "$requested" && break
  echo "not ready yet"
  sleep 5
done