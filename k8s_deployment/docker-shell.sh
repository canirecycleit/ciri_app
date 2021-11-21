#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

# Define some environment variables
export IMAGE_NAME="deployment-app"
export BASE_DIR=$(pwd)
export GCP_PROJECT="ciri-329403" # Change to your GCP Project
export GCP_ZONE="us-east1-c"
export GCP_K8S_CLUSTER="ciri-k8s-cluster"
export GOOGLE_APPLICATION_CREDENTIALS=/secrets/ciri-cloud-deployment.json


# Build the image based on the Dockerfile
# docker build -t $IMAGE_NAME -f Dockerfile .

# Run the container
docker run --rm --name $IMAGE_NAME -ti \
-v /var/run/docker.sock:/var/run/docker.sock \
--mount type=bind,source=$BASE_DIR,target=/app \
--mount type=bind,source=$BASE_DIR/../,target=/project \
--mount type=bind,source=$BASE_DIR/../secrets/,target=/secrets \
--mount type=bind,source=$HOME/.ssh,target=/home/app/.ssh \
-e GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS \
-e GCP_PROJECT=$GCP_PROJECT \
-e GCP_CLUSTER_NAME=$GCP_K8S_CLUSTER \
-e GCP_ZONE=$GCP_ZONE $IMAGE_NAME

