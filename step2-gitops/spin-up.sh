helm upgrade --install argocd argo/argo-cd --namespace argocd  --create-namespace

sleep 60

kubectl apply -f step2-gitops/argocd-seed-app.yaml

echo password can be retrieved by running: \''kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d'\'

echo run after getting the password: 'kubectl port-forward svc/argocd-server 8080:80 -n argocd'

echo
echo incase the password secret is not present then please run the script again