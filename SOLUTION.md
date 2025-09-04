# Solution


# Step 1

## Prerequisites

- Docker
- kubectl
- Helm
- Kind
- Bash

## Quick Start Script

For simplicity, I prepared a script `step1-spin-up.sh` to automate the entire setup for Step 1. This script creates the cluster, applies pre Helm resources, builds and loads the Docker image, deploys the Helm chart, and runs the Helm test suite.

To use:
```sh
bash ./step1-spin-up.sh
```
This will spin up everything and run `helm test` to verify the deployment.

---

## Step 1: Kubernetes Cluster Setup (Kind)

**Cluster Topology:**
- 1 control-plane node
- 2 worker nodes

**Setup Instructions:**
1. Create the cluster:
	```sh
	kind create cluster --name kaiko --config resources/kind-config.yaml
	```
	```sh
	kubectl cluster-info --context kind-kaiko
	```

This sets up a local Kubernetes cluster with the required node roles for further steps.

---

## Step 2: pre app deploy configs to install

includes:
- Configmap
- Secret
- Namespace
- NetworkPolicy
- ResourceQuota

```sh
kubectl apply -f resources/pre-helm-install-configs-to-install.yaml
```

None app level resource which we want to deploy before we install the app using helm

---

## Step 3: Build and Load Docker Image

Build app image and load it into kind cluster for local deployment.

#### Build the Docker Image

```sh
docker build -t kaiko-app:latest ./app
```

#### Load the image into kind

```sh
kind load docker-image kaiko-app:latest --name kaiko
```

---

## Step 4: Deploy the Application

### Apply the Deployment

Run the following command:

```sh
helm upgrade --install kaiko-app ./chart
```

Verify the app endpoints are ok by running:

```sh
helm test kaiko-app
```

Or by port forward:

```sh
kubectl port-forward svc/kaiko-app-service 8000:8000 -n kaiko-app
```
and testing out the endpoint on `localhost:8000/<endpoint>`

### Resources and Limits
The resources chosen for this app are as follows:
```
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```
Its reasonable to choose this for a lightweight stateless web app, we can adjust them incase there is a need for more load to be handled.


## Trade-offs and Assumptions

- I chose [Kind](https://kind.sigs.k8s.io/) for a local setup for this assignment because its lightweight and easy to use, plus it supports multi node clusters out of the box which makes it ideal. k3s might be more suitable for production scenarios, but for the simplicity of this task I went with kind
- Went with a nodeport to expose the app, allowing access from outside the cluster, for production/cloud envs i would go with a loadbalancer but for this assignment the nodeport is enough.
- Went with deployment because the app is stateless and needs easy scaling and updates. StatefulSet is for stateful apps, and DaemonSet is for running one pod per node which is not needed here. with deployment we can do rolling updates and self healing
- Helm was used for templating and managing resources for flexibility and reusability.
- ResourceQuota and namespace are created outside Helm to ensure proper enforcement and isolation.
- Horizontal Pod Autoscaler (HPA) is enabled for automatic scaling based on resource usage.
- PodDisruptionBudget (PDB) is set to maintain availability during voluntary disruptions.
- NetworkPolicy restricts ingress to the namespace for blast-radius limitation.

## Cleanup Instructions

To remove all resources and the cluster:
```sh
kind delete cluster --name kaiko
```
Or, to uninstall the Helm release and delete the namespace:
```sh
helm uninstall kaiko-app
kubectl delete namespace kaiko-app
```

## Reference: Helm Chart README

See `app-chart/README.md` for detailed Helm chart usage, configuration options, and examples (generated via Bitnami readme-generator-for-helm or Frigate).





---
# Step 2: GitOps with ArgoCD

## Overview
This step implements a fully declarative, multi-environment GitOps workflow using ArgoCD and Helm.

## ArgoCD Setup

1. **Install ArgoCD on your cluster:**
   ```sh
    helm repo add argo https://argoproj.github.io/argo-helm
    helm upgrade --install argocd argo/argo-cd --namespace argocd  --create-namespace
   ```
2. **Access the ArgoCD UI:**
   - Port forward the ArgoCD API server:
     ```sh
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d # for the password
      kubectl port-forward svc/argocd-server -n argocd 8080:443
     ```
   - Open `https://localhost:8080` in your browser

3. **Connect ArgoCD to your Git repository:**
   - I am using my public repository for this assignment and you are welcome to check it: https://github.com/asaid997/argocd-app

## ApplicationSet Pattern

- Used ArgoCD ApplicationSet to manage both the baseline and app Helm charts for `dev` and `prd` environments.
- Each environment uses its own values file for environment specific configuration (e.g., resource limits, replica counts).

**ApplicationSet manifest:**  
See `argocd-app/app-of-apps.yaml` for the full configuration.

- The ApplicationSet generates four Applications:
  - `ns-baseline-chart-dev`
  - `ns-baseline-chart-prd`
  - `app-chart-dev`
  - `app-chart-prd`
- Sync waves ensure the baseline chart is deployed before the app chart in each environment.

## Environment-Specific Configuration

- Each environment (`dev`, `prd`) has its own values file for each chart.
- Example differences:
  - `dev` uses lower resource limits and fewer replicas.
  - `prd` uses higher resource limits and more replicas.
- All configuration is DRY no manifest duplication.

## Multi-Environment Management

- Adding a new environment is as simple as adding a new values file and an entry in the ApplicationSet.
- The structure supports easy scaling to more environments.

## ArgoCD UI & Status

- All applications are visible in the ArgoCD UI.
- Each application shows "Healthy" and "Synced" status when deployed successfully.

**Insert Screenshot 1 here:**
_ArgoCD UI showing all applications (dev and prd)_

**Insert Screenshot 2 here:**
_Application details showing different configuration for dev and prd (e.g., resource limits, replicas)_

## Commands for Managing ArgoCD

- Access ArgoCD UI:
  ```sh
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  ```
- Sync or refresh applications from the UI or CLI:
  ```sh
  argocd app sync <app-name>
  argocd app get <app-name>
  ```

## Design Justification

- **Helm + ApplicationSet**: Enables DRY, scalable, and declarative multi-environment management.
- **No manifest duplication**: All environment-specific config is handled via values files.
- **Sync waves**: Guarantee baseline resources are ready before app deployment.
- **Easy extensibility**: Add new environments or charts with minimal changes.