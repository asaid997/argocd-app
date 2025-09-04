kind create cluster --name kaiko --config step1/resources/kind-config.yaml

kubectl cluster-info --context kind-kaiko

kubectl apply -f step1/resources/pre-helm-install-configs-to-install.yaml

# docker build step
docker build -t kaiko-app:latest ./app
kind load docker-image kaiko-app:latest --name kaiko

helm upgrade --install kaiko-app ./charts/app-chart

sleep 300

echo we can run \'helm test kaiko-app\'