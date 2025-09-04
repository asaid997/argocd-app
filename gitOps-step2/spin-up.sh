helm upgrade --install argocd argo/argo-cd --namespace argocd  --create-namespace
pass=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo Argod app is: $pass

kubectl apply -f gitOps-step2/app-of-apps.yaml
