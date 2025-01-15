#!/bin/bash
# GitHub Action: Check Deployment Pods Readiness

check_deployment_readiness() {
    deployment_name=$deployment_name
    namespace=$STUDENT_NAMESPACE
    timeout_sec=500

    # Start time
    start_time=$(date +%s)

    # Check pod readiness
    while true; do
        elapsed_time=$(( $(date +%s) - start_time ))
        [ "$elapsed_time" -ge "$timeout_sec" ] && {
            echo "Timeout reached. Exiting with failure."; exit 1;
        }

        ready_replicas=$(kubectl get deployment "$deployment_name" -n "$namespace" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        desired_replicas=$(kubectl get deployment "$deployment_name" -n "$namespace" -o jsonpath='{.status.replicas}' 2>/dev/null)

        [ "$ready_replicas" = "$desired_replicas" ] && {
            echo "Deployment '$deployment_name' is ready."; exit 0;
        }

        echo "Waiting for pods to become ready... Ready: ${ready_replicas:-0}, Desired: ${desired_replicas:-0}";
        sleep 5
    done
}

# Call the function
check_deployment_readiness