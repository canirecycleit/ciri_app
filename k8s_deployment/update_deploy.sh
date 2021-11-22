#!/bin/bash

echo "Update deployment for $1"
vdep=$(kubectl get deployments|grep $1)

if [ -z "$vdep" ]; then   
    echo "Deploy $1"
    kubectl apply -f k8s_deployment/kompose/$1-deployment.yaml
    kubectl apply -f k8s_deployment/kompose/$1-service.yaml

else
    echo "Patch $1"
    kubectl patch deployment $1 -p "{\"spec\": {\"template\": {\"metadata\": { \"labels\": {  \"redeploy\": \"$(date +%s)\"}}}}}"
fi