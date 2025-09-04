kind create cluster --name kaiko --config resources/kind-config.yaml

kubectl cluster-info --context kind-kaiko

kubectl apply -f resources/pre-helm-install-configs-to-install.yaml

# docker build step
docker build -t kaiko-app:latest ./app
kind load docker-image kaiko-app:latest --name kaiko

helm upgrade --install kaiko-app ./chart

sleep 20

helm test kaiko-app