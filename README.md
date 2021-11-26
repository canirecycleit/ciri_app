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

Service Account (SA) secrets for deployment operations are stored within GitHub Environment Secrets for security purposes.

## Getting Started

### Docker container

A [docker container](k8s_deployment/Dockerfile) is provided to execute initial cluster startup scripts.  Interactive shell can be launched via:

```bash
> cd k8s_deployment
> ./docker-shell.sh
```

You may get the error below if no cluster currently exists.  This can be ignored.

```
ERROR: (gcloud.container.clusters.get-credentials) ResponseError: code=404, message=Not found: projects/ciri-329403/zones/us-east1-c/clusters/ciri-k8s-cluster.
No cluster named 'ciri-k8s-cluster' in ciri-329403.
```

### Cluster creation

You can create initial cluster _from within the provided Docker container shell_ via

```bash
> ./create_cluster.sh
```

This command will:

* Create an initial 2-node cluster
* Install nginx-ingress controller in the cluster
* Create a persistent disk for database (if doesn't already exist)

You may get an error that indicates persistent disk already exists if you have previously created a cluster and have not removed the created `gce-db-disk`.  This can be ignored.

### Create secrets

You can create required secrets _from within the provided Docker container shell_ via

```bash
> ./create_secret.sh
```

It is required that `/ciri_app/secrets` folder exists and contains the `ciri-cloud-storage.json` file containing Google Service Account credentials.

### Application deployment

Once the cluster is established the CIRI application can be deployed by executing the [CIRI App GKE Deployment Action](https://github.com/canirecycleit/ciri_app/actions/workflows/deployment.yml) using the `Run workflow` button.

Alternatively the application can be deployed by commiting a change to the ciri_app GitHub repository and approving the deployment task that is automatically generated.

Alternatively the application can be deployed manually via use of the `kubectl apply` command to deploy yaml files from the `kompose` folder.

### (Optional) Deploy Model Pipeline

If you would like to run the model pipeline to create a new version of the model you should first create a dedicated `training-pool` node pool via

```bash
> ./create_traininig_node_pool.sh
```

and then deploy a run-once instance of the model-pipeline Pod via

```bash
> kubectl apply -f kompose/model-pipeline-pod.yaml
```

You should then be able to see your Pod executing via

```bash
> kubectl get all
```

### Local Development

The application can be run locally using

```bash
docker-compose up
```

The docker-compose file can be modified to mount volume drives in local file system to enable faster development.  For example within the `ui` service definition the following line can be enabled so that local changes to frontend_ui codebase are reflected in the deployed service:

```yaml
    # volumes:
      - "../frontend_ui:/app"
```

Service account credentials should be stored in `./secrets` folder as `ciri-cloud-storage.json` with read permissions to image and artifact cloud stores.
