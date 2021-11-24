# Can I Recycle It (CIRI) Application

Application for classification of objects as either "recyclable" or "not recyclable".

[![CIRI GKE Deployment](https://github.com/canirecycleit/ciri_app/actions/workflows/deployment.yml/badge.svg?branch=master)](https://github.com/canirecycleit/ciri_app/actions/workflows/deployment.yml)
![K8s](https://img.shields.io/badge/CIRI-Kubernetes-blue)

## Application Overview

The CIRI Application is composed of the following Kubernetes components:

| Services | Type | Description |
|-|-|-|
| [mlflow](k8s_deployment/kompose/mlflow-service.yaml) | LoadBalancer | Provides intra-cluster and external access to the [MLFlow](https://www.mlflow.org/) Experiment Tracking and Model Repository services. |
| [api](k8s_deployment/kompose/api-service.yaml) | NodePort | Provides backend APIs that enable IO operations on training data-set as well as execution of predictions.
| [ui](k8s_deployment/kompose/ui-service.yaml) | NodePort | Provides an HTML based front-end for user interaction with application.

| Deployments | Description |
|-|-|
| [mlflow](k8s_deployment/kompose/mlflow-deployment.yaml) | Deployment of [ciri_mlflow:latest](ghcr.io/canirecycleit/mlflow/ciri_mlflow:latest) Docker container. |
| [api](k8s_deployment/kompose/api-deployment.yaml) | Deployment of [ciri_apis:latest](ghcr.io/canirecycleit/backend_apis/ciri_apis:latest) Docker container.  |
| [ui](k8s_deployment/kompose/ui-deployment.yaml) | Deployment of [ciri_frontend:latest](ghcr.io/canirecycleit/frontend_ui/ciri_frontend:latest) Docker container.  |

| Pods | Description |
|-|-|
| model-pipeline | Deployment of model training pipeline via [ciri_model_pipeline:latest](ghcr.io/canirecycleit/model_training_pipeline/ciri_model_pipeline:latest) Docker container.  Pod runs one time and executes download of raw training images from Cloud Storage, processing/transformation of image files, training of model and registration of model in MLFlow model registry. |

## Kubernetes Infrastructure

Ingress to the Kubernetes-hosted application is provided via [Kubernetes ingress-nginx controller](https://kubernetes.github.io/ingress-nginx).  Controller mappings are provided via the following [definitions](k8s_deployment/kompose/ingress.yaml):

| Rule-Path | Service |
|-|-|
|/app/*| ui:8080|
|/api/*| api:8080|

Access to mlflow services is provided via external_ip:5000 as a hosted LoadBalancer component.

Application currently is designed for 2 node-pools to reflect a varied compute requirement for "always-on" application hosting vs. more intensive training:

| Node Pool | Description |
|-|-|
| default-pool | Always on pool that runs application services including mlflow, ui and api via default e2-medium instances.|
| training-pool | Transient pool of higher memory machines (e2-highmem-4) to execute training pipeline.|

The application also leverages two cloud storage resources:

| Cloud Storage | Name | Description |
|-|-|-|
| Image Store | canirecycleit-data | Provides storage of raw images used as input for training where "folders" reflect the classification. |
| Artifact Store | canirecycleit-artifactstore |Stores serialized metadata and model files from execution of model-pipeline. |

## Application Deployment & Updating

Individual deployment containers as well as deployment of Kubernetes application are automatically executed via [GitHub Actions](https://docs.github.com/en/actions).  K8s deployment Action can be found [here](.github/workflows/deployment.yml).

For individual Dockerized components (e.g. [ciri_apis:latest](ghcr.io/canirecycleit/backend_apis/ciri_apis:latest) the docker container is built on all merges of new code to master branch and made available via the GitHub Container Registry as a public image (no secrets or confidential information is stored within the Image).

For deployment of Kubernetes application (ciri_app) a request for deployment is generated with all changes merged to master branch.  Requests must be approved by an repository team member that is autorized for approval of the production environment.  When approved, the Deployment Action will either deploy all components or patch existing components depending on if components already exist or not within cluster.  Deployments are set to pull new images so latest component Docker containers will be used on Deploy or Patch.

## Getting Started

Initial cluster creation scripts...
