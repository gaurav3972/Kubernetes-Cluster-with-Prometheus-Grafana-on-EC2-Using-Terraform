# Kubernetes Cluster with Prometheus & Grafana on EC2 Using Terraform

---

## 📌 Overview

This documentation provides a detailed step-by-step guide to provisioning a **Kubernetes cluster on AWS EC2 instances using Terraform**, and deploying **Prometheus and Grafana** for monitoring your cluster. This stack is ideal for learning DevOps and infrastructure-as-code (IaC) workflows.

---

## 🧰 Prerequisites

### 🔧 Local Machine Requirements

* Terraform (v1.0 or higher)
* AWS CLI (configured with `aws configure`)
* SSH key pair (e.g., `~/.ssh/id_rsa`)
* kubectl
* Helm (v3.x)
* Git (optional, for versioning your Terraform and K8s configs)

### 🖥️ AWS Resources Used

* EC2 (Ubuntu 20.04 LTS or Amazon Linux 2)
* VPC (default or custom)
* Security Groups

---

## 📁 Project Structures

```
k8s-monitoring-ec2/
└── terraform/
    ├── .terraform/                    # Terraform internal directory
    ├── .terraform.lock.hcl            # Terraform dependency lock file
    ├── 3972gaurav.pub                 # Public key for EC2 SSH access
    ├── install-master.sh              # Script to setup Kubernetes master
    ├── install-worker.sh              # Script to setup Kubernetes worker
    ├── main.tf                        # Main Terraform configuration
    ├── output.tf                      # Output values
    ├── terraform.tfstate              # Terraform state file
    ├── terraform.tfstate.backup       # Backup state file
```

---

## 🔨 Step 1: Generate an SSH Key Pair

Run the following on your local machine:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Copy the public key `~/.ssh/id_rsa.pub` to your project as `3972gaurav.pub`.

---

## 📦 Step 2: Terraform Configuration Files

### 🧾 main.tf

This file defines the AWS provider, EC2 instances, networking, key pair, and user-data scripts:

* **provider block**: specifies AWS region
* **aws\_key\_pair**: creates SSH access key
* **aws\_security\_group**: opens required ports (e.g., 22, 6443, 3000, 9090)
* **aws\_instance**: launches master and worker nodes
* **user\_data**: runs shell scripts (`install-master.sh`, `install-worker.sh`)

### 📤 output.tf

Prints public IPs of the instances after deployment.

---

## 🚀 Step 3: Deploy Infrastructure

Navigate into the `terraform` directory and run:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

After provisioning, you'll see output like:

```
master_public_ip = "3.209.xxx.xxx"
worker_public_ip = "34.201.xxx.xxx"
```

---

## 🔗 Step 4: SSH into EC2 Instances

### SSH into Master

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<master_public_ip>
```

### Setup kubeconfig

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown ec2-user:ec2-user $HOME/.kube/config
```

### SSH into Worker

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<worker_public_ip>
```

Run the join command provided by the master (see next step).

---

## 🔗 Step 5: Join Worker Node

On the master node:

```bash
kubeadm token create --print-join-command
```

Copy the output and run it on the worker node to join the cluster.

Back on the master:

```bash
kubectl get nodes
```

Expected:

```
NAME           STATUS   ROLES           AGE   VERSION
master-node    Ready    control-plane   5m    v1.29.x
worker-node    Ready    <none>          2m    v1.29.x
```

---

## 📦 Step 6: Install Helm and Prometheus Stack

### Add Helm Repo

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Install Prometheus Stack

```bash
kubectl create namespace monitoring

helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

Check installation:

```bash
kubectl get pods -n monitoring
```

---

## 🌐 Step 7: Access Prometheus & Grafana

### Option 1: Port Forward (Local Access)

#### Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Visit [http://localhost:9090](http://localhost:9090)

#### Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Visit [http://localhost:3000](http://localhost:3000)

Default login:

* **User**: `admin`
* **Pass**: `prom-operator`

---

### Option 2: NodePort (Public Access - Not Recommended for Production)

Expose via NodePort or LoadBalancer and open relevant security group ports:

```yaml
# prometheus-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-server
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app: prometheus
  ports:
    - port: 80
      targetPort: 9090
      nodePort: 30480
```

```bash
kubectl apply -f prometheus-nodeport.yaml
```

Then access via:

```
http://<master_public_ip>:30480
```

---

## 📈 Step 8: Configure Grafana Dashboard

### Login to Grafana ([http://localhost:3000](http://localhost:3000))

* Navigate to **Dashboards > New > Import**
* Use dashboard ID `1860` (Node Exporter)
* Select **Prometheus** as the data source

You can also import other dashboards like:

* Kubernetes Cluster Monitoring: `315`
* Prometheus Stats: `3662`

---

## ✅ Validation

Check Prometheus targets:

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090
```

Visit **Status > Targets** in Prometheus UI

Check services:

```bash
kubectl get svc -n monitoring
```

Check node health:

```bash
kubectl get nodes -o wide
```

---

## 🧹 Cleanup

To tear down all resources:

```bash
terraform destroy -auto-approve
```

---

## 📚 Additional Tips

* Store Terraform state remotely using S3 and DynamoDB for production
* Use a custom VPC with private/public subnets for secure deployment
* Add HTTPS with Ingress + Cert Manager for secure dashboard access
* Enable persistent volumes for Prometheus and Grafana

---

## 🔐 Security Considerations

* Do not expose NodePort services to the internet without auth
* Limit security group access by IP range
* Use AWS IAM roles for EC2 and services (if expanded)

---

## 🧾 Summary

| Component  | Description                   |
| ---------- | ----------------------------- |
| EC2        | Hosts master and worker nodes |
| Terraform  | Automates infra provisioning  |
| kubeadm    | Bootstraps Kubernetes cluster |
| Helm       | Installs Prometheus & Grafana |
| Prometheus | Metrics collection & alerting |
| Grafana    | Visualization of metrics      |

---
