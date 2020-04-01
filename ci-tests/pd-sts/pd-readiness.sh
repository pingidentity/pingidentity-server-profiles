#!/usr/bin/env sh
ready=$(kubectl get sts/pingdirectory | grep pingdirectory | awk '{ print $2}' | awk -F'\' '{ print $1}')
requested=$(kubectl get sts/pingdirectory | grep pingdirectory | awk '{ print $2}' | awk -F'\' '{ print $2}')
test "$ready" = "$requested" ; 