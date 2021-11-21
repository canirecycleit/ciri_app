gcloud container clusters create ciri-k8s-cluster --num-nodes 2 --zone us-east1-c

# Install nginx-ingress
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/cloud/deploy.yaml

# Create persistent disk
gcloud compute disks create --size=10GB --zone=us-east1-c gce-db-disk
