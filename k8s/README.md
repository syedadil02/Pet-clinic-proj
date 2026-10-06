# Spring PetClinic Kubernetes Manifests

Production-ready Kubernetes manifests for deploying Spring PetClinic Microservices using the **Kustomize Base & Overlays** pattern. Supports both local testing (Kind / Minikube) and cloud deployment (**AWS EKS** with Amazon RDS MySQL).

---

## 1. Directory Structure

```
k8s/
├── base/                                # Common microservice specifications (written once)
│   ├── 00-namespace.yaml                # Standardized 'spring-petclinic' namespace
│   ├── kustomization.yaml               # Base Kustomize bundle
│   ├── config-server/                   # Config server deployment & service (port 8888)
│   ├── discovery-server/                # Eureka discovery server with config init-container (port 8761)
│   ├── customers-service/               # Customers microservice with dual init-containers (port 8081)
│   ├── visits-service/                  # Visits microservice with dual init-containers (port 8082)
│   ├── vets-service/                    # Vets microservice with dual init-containers (port 8083)
│   ├── api-gateway/                     # API Gateway with LoadBalancer service (port 80 -> 8080)
│   └── admin-server/                    # Spring Boot Admin UI (port 9090)
└── overlays/
    ├── local/                           # Local environment overlay (Kind / Minikube)
    │   ├── kustomization.yaml           # Inherits base + adds local MySQL
    │   ├── mysql-deployment.yaml        # Lightweight MySQL 8.0 deployment & service
    │   └── db-secret.yaml               # Credentials wired to local mysql:3306
    └── prod/                            # Production environment overlay (AWS EKS)
        ├── kustomization.yaml           # Inherits base + adds AWS RDS secret & Ingress
        ├── db-secret.yaml               # Credentials wired to Reddy's AWS RDS in eu-north-1
        └── ingress.yaml                 # AWS ALB Ingress controller specification
```

---

## 2. Key Architecture & Design Highlights

### Kustomize Base & Overlays Pattern
- **DRY (Don't Repeat Yourself):** All 7 microservices, init-containers, and probe tunings are maintained exclusively in `base/`.
- **Environment Separation:** Local testing uses `overlays/local` (with an in-cluster MySQL pod), while production uses `overlays/prod` (connecting to AWS RDS with AWS ingress).

### Uniform Namespace Enforcement
All manifests strictly deploy into the **`spring-petclinic`** namespace to adhere to platform governance.

### Zero Database Password Mismatches
Database credentials are centralized in `petclinic-db` secret. All database-backed services (`customers`, `visits`, `vets`) inject credentials directly from this single secret via `secretKeyRef`.

### Deterministic Startup Order (Dual Init-Containers)
All downstream microservices use lightweight `curlimages/curl` init-containers:
1. `wait-for-config-server`: Polls `http://config-server:8888/actuator/health` until HTTP 200.
2. `wait-for-discovery-server`: Polls `http://discovery-server:8761/actuator/health` until HTTP 200.

### Tuned Health Probes
Startup, readiness, and liveness probes use `timeoutSeconds: 5` to prevent premature pod restarts during Spring Boot startup cycles.

---

## 3. Deployment Instructions

### Option A: Local Testing (Kind / Minikube)
Deploy the full stack with an in-cluster MySQL database:
```bash
# One-command deployment
kubectl apply -k k8s/overlays/local

# Watch the pods turn green
kubectl get pods -n spring-petclinic -w
```

### Option B: Production Deployment (AWS EKS)
Deploy the full stack connecting to AWS RDS MySQL:
```bash
# 1. Update your kubeconfig for AWS EKS
aws eks update-kubeconfig --name petclinic-dev --region eu-north-1

# 2. Deploy the production overlay
kubectl apply -k k8s/overlays/prod

# 3. Monitor rollout
kubectl get pods -n spring-petclinic -w
```

---

## 4. Verification & Testing

### Check Pod Status
```bash
kubectl get pods -n spring-petclinic
```
*Expected: All pods showing `1/1 Running` and `0 Restarts`.*

### Port-Forwarding (Local Inspection)
```bash
# 1. API Gateway (Web UI)
kubectl port-forward svc/api-gateway 8080:80 -n spring-petclinic

# 2. Eureka Discovery Dashboard
kubectl port-forward svc/discovery-server 8761:8761 -n spring-petclinic

# 3. Spring Boot Admin UI
kubectl port-forward svc/admin-server 9090:9090 -n spring-petclinic
```
- Open `http://localhost:8080` to access the PetClinic web application.
- Open `http://localhost:8761` to view all registered microservices in Eureka.
- Open `http://localhost:9090` to inspect application metrics in Spring Boot Admin.

---

## 5. Switching to Private AWS ECR Images (Optional)
When provisioning private ECR repositories, update the container image paths:
```bash
# Format: <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/petclinic/spring-petclinic-<SERVICE>:latest
```
Using Kustomize, you can override images dynamically without modifying individual manifests:
```bash
cd k8s/base
kustomize edit set image springcommunity/spring-petclinic-api-gateway=<ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/petclinic/spring-petclinic-api-gateway:latest
```
