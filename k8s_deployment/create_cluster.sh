gcloud container clusters create ciri-k8s-cluster --num-nodes 2 --zone us-east1-c

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/cloud/deploy.yaml

# kubectl create ingress ui --class=nginx --rule=/*=ui:8080
# kubectl create ingress api --class=nginx --rule=/api/*=api:8080