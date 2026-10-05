# Spring PetClinic Kubernetes Manifests

Production-ready Kubernetes manifests for deploying Spring PetClinic Microservices to **AWS EKS** (and local test clusters).

---

## 1. Directory Structure

Following senior engineering blueprint standards (`k8s/<service-name>/`):

```
k8s/
├── 00-namespace.yaml             # Uniform namespace definition ('spring-petclinic')
├── 01-db-secret.yaml             # Centralized MySQL credentials secret ('petclinic-db')
├── kustomization.yaml            # Single-command deployment bundle
├── config-server/
│   ├── deployment.yaml           # Config server deployment (Spring Cloud Config)
│   └── service.yaml              # ClusterIP service on port 8888
├── discovery-server/
│   ├── deployment.yaml           # Netflix Eureka discovery server with init-container
│   └── service.yaml              # ClusterIP service on port 8761
├── customers-service/
│   ├── deployment.yaml           # Dual init-containers + MySQL DB secret wiring
│   └── service.yaml              # ClusterIP service on port 8081
├── visits-service/
│   ├── deployment.yaml           # Dual init-containers + MySQL DB secret wiring
│   └── service.yaml              # ClusterIP service on port 8082
├── vets-service/
│   ├── deployment.yaml           # Dual init-containers + MySQL DB secret wiring
│   └── service.yaml              # ClusterIP service on port 8083
├── api-gateway/
│   ├── deployment.yaml           # Dual init-containers
│   ├── service.yaml              # LoadBalancer service on port 80 -> 8080 (AWS ELB)
│   └── ingress.yaml              # Optional AWS ALB Ingress controller spec
└── admin-server/
    ├── deployment.yaml           # Dual init-containers
    └── service.yaml              # ClusterIP service on port 9090
```

---

## 2. Key Architecture & Design Highlights

### Uniform Namespace Enforcement
All manifests are deployed into the **`spring-petclinic`** namespace. This satisfies governance requirements and isolates application workloads from EKS cluster system components.

### Preventing Database Password Mismatches
To prevent database connection discrepancies:
- A single Secret **`petclinic-db`** stores `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_DATABASE`, `MYSQL_USER`, and `MYSQL_PASSWORD`.
- All database-backed services (`customers-service`, `visits-service`, and `vets-service`) inject credentials directly from this single secret.
- Updating database credentials in `01-db-secret.yaml` automatically syncs across all services.

### Deterministic Startup Order (Dual Init-Containers)
Spring PetClinic microservices will crash loop if started before configuration and discovery servers are fully responsive. We enforce a deterministic startup chain:

```
[config-server:8888]
         │
         ▼ (init-container checks /actuator/health)
[discovery-server:8761]
         │
         ▼ (dual init-containers check both /actuator/health)
[customers, visits, vets, api-gateway, admin-server]
```

Every downstream pod includes lightweight `curlimages/curl` init-containers that poll until upstream dependencies respond with HTTP 200 before launching the main Spring Boot JVM.

### Tuned Health Probes
- Probes use a **5-second timeout** (`timeoutSeconds: 5`) to prevent false-positive pod terminations during JVM garbage collection or initial Spring context loading.
- Startup probes allow up to 150 seconds for initial container initialization.

---

## 3. Deployment Instructions

### Prerequisites
- Active Kubernetes context pointed to AWS EKS (or Kind/Minikube):
  ```bash
  aws eks update-kubeconfig --name petclinic-dev --region eu-central-1
  ```

### Step 1: Deploy Namespace and Database Secrets
```bash
# 1. Create the uniform namespace
kubectl apply -f k8s/00-namespace.yaml

# 2. Deploy database credentials
# (Edit k8s/01-db-secret.yaml with Reddy's RDS endpoint and password first)
kubectl apply -f k8s/01-db-secret.yaml
```

### Step 2: Deploy All Microservices
You can deploy all services at once using Kustomize:
```bash
kubectl apply -k k8s/
```

Or deploy incrementally in dependency order:
```bash
# Core Foundation Services
kubectl apply -f k8s/config-server/
kubectl apply -f k8s/discovery-server/

# Wait for Eureka to become healthy
kubectl rollout status deployment/config-server -n spring-petclinic
kubectl rollout status deployment/discovery-server -n spring-petclinic

# Business Services & Gateways
kubectl apply -f k8s/customers-service/
kubectl apply -f k8s/visits-service/
kubectl apply -f k8s/vets-service/
kubectl apply -f k8s/api-gateway/
kubectl apply -f k8s/admin-server/
```

---

## 4. Verification & Health Checks

### Check Pod Status
```bash
kubectl get pods -n spring-petclinic -o wide
```
*Expected: All 7 pods showing `1/1 Running` and `0 Restarts`.*

### Check Services & External Load Balancer
```bash
kubectl get svc -n spring-petclinic
```
The `api-gateway` service will display the external AWS Load Balancer DNS endpoint under `EXTERNAL-IP`.

### Port Forwarding (For Local / Bastion Inspection)
```bash
# API Gateway (Web UI)
kubectl port-forward svc/api-gateway 8080:80 -n spring-petclinic

# Eureka Discovery Dashboard
kubectl port-forward svc/discovery-server 8761:8761 -n spring-petclinic

# Spring Boot Admin UI
kubectl port-forward svc/admin-server 9090:9090 -n spring-petclinic
```
Open your browser at `http://localhost:8761` to verify all microservices are registered in Eureka.

---

## 5. Switching to Private AWS ECR Images (Optional)
When Reddy provisions private ECR repositories, update the container image paths:
```bash
# Format: <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/petclinic/spring-petclinic-<SERVICE>:latest
```
Using Kustomize, you can override images dynamically without modifying individual manifests:
```bash
cd k8s
kustomize edit set image springcommunity/spring-petclinic-api-gateway=<ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/petclinic/spring-petclinic-api-gateway:latest
```
