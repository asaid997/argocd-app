kind create cluster --name kaiko --config step1/resources/kind-config.yaml

kubectl cluster-info --context kind-kaiko

kubectl apply -f step1/resources/pre-helm-install-configs-to-install.yaml

# docker build step
docker build -t kaiko-app:latest ./app
kind load docker-image kaiko-app:latest --name kaiko

helm upgrade --install kaiko-app ./charts/app-chart

sleep 20

kubectl port-forward svc/kaiko-app-service 8000:8000 -n kaiko-app&
echo you can now access the application at http://localhost:8000