gcloud container clusters create $GCP_CLUSTER_NAME --num-nodes 2 --zone $GCP_ZONE

gcloud container clusters get-credentials --zone $GCP_ZONE $GCP_CLUSTER_NAME

# Install nginx-ingress
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/cloud/deploy.yaml


# Create persistent disk
gcloud compute disks create --size=10GB --zone=$GCP_ZONE gce-db-disk
