# RAG Infrastructure Deployment Guide

## Prerequisites

1. **Terraform >= 1.6** installed
2. **gcloud CLI** authenticated with project admin permissions
3. **Domain name** you control (for DNS configuration)
4. **Billing enabled** on your GCP project

## Step-by-Step Deployment

### Step 1: Set up IAP OAuth (Required for IAP protection)

```bash
# 1. Create OAuth consent screen (one-time setup)
gcloud iap oauth-brands create \
  --application_title="RAG Chatbot" \
  --support_email="YOUR_EMAIL@EXAMPLE.COM"

# 2. Get the brand ID
BRAND_ID=$(gcloud iap oauth-brands list --format="value(name)" | head -1)

# 3. Create OAuth client for IAP
gcloud iap oauth-clients create $BRAND_ID \
  --display_name="RAG HTTPS LB"

# 4. Save the client ID and secret from the output
```

### Step 2: Create terraform.tfvars

```bash
# Create terraform.tfvars file
cat > terraform.tfvars << EOF
project_id        = "YOUR_PROJECT_ID"
region            = "us-central1"
domain_name       = "your-domain.com"

# IAP Configuration (REQUIRED for protection)
enable_iap        = true
iap_client_id     = "YOUR_IAP_CLIENT_ID_FROM_STEP1"
iap_client_secret = "YOUR_IAP_CLIENT_SECRET_FROM_STEP1"
iap_members = [
  "user:your-email@example.com",
  # Add more users/groups as needed
]

# Container images (will be updated after building)
frontend_image = "us-central1-docker.pkg.dev/YOUR_PROJECT_ID/rag-repo/rag-frontend:latest"
backend_image  = "us-central1-docker.pkg.dev/YOUR_PROJECT_ID/rag-repo/rag-backend:latest"
EOF
```

### Step 3: Initialize and Plan

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan
```

### Step 4: Deploy Infrastructure

```bash
# Apply infrastructure
terraform apply -auto-approve
```

**Expected outputs:**
- `lb_ip_address` - Point your domain to this IP
- `artifact_registry_repo` - Use this for container images
- `frontend_url` - Your app URL
- `backend_url` - API endpoint

### Step 5: Configure DNS

```bash
# Get the load balancer IP
LB_IP=$(terraform output -raw lb_ip_address)

# Point your domain to this IP (A record)
# Example with Cloud DNS:
gcloud dns record-sets create your-domain.com. \
  --zone=YOUR_DNS_ZONE \
  --type=A \
  --ttl=300 \
  --rrdatas=$LB_IP
```

### Step 6: Build and Deploy Containers

```bash
# Build and push frontend
cd samples/
docker build -f Dockerfile.frontend -t us-central1-docker.pkg.dev/YOUR_PROJECT_ID/rag-repo/rag-frontend:latest .
docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/rag-repo/rag-frontend:latest

# Build and push backend
docker build -f Dockerfile.backend -t us-central1-docker.pkg.dev/YOUR_PROJECT_ID/rag-repo/rag-backend:latest .
docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/rag-repo/rag-backend:latest

# Update Cloud Run services with new images
gcloud run services update rag-frontend \
  --image=us-central1-docker.pkg.dev/YOUR_PROJECT_ID/rag-repo/rag-frontend:latest \
  --region=us-central1

gcloud run services update rag-backend \
  --image=us-central1-docker.pkg.dev/YOUR_PROJECT_ID/rag-repo/rag-backend:latest \
  --region=us-central1
```

### Step 7: Enable pgvector Extension

```bash
# Connect to Cloud SQL and enable pgvector
gcloud sql connect rag-pgvector --user=raguser

# In the SQL prompt:
CREATE EXTENSION IF NOT EXISTS vector;
```

### Step 8: Verify Deployment

```bash
# Wait for SSL certificate to be active (5-10 minutes)
gcloud certificate-manager certificates describe rag-managed-cert --global

# Test endpoints (will require Google login due to IAP)
curl -I https://your-domain.com/
curl -I https://your-domain.com/api/health
```

## File Execution Sequence

1. **terraform.tfvars** - Configuration
2. **terraform init** - Initialize
3. **terraform plan** - Review changes
4. **terraform apply** - Deploy infrastructure
5. **DNS configuration** - Point domain to LB IP
6. **Container builds** - Build and push images
7. **Cloud Run updates** - Deploy containers
8. **Database setup** - Enable pgvector
9. **Verification** - Test endpoints

## Security Features Enabled

✅ **IAP Protection**: Both frontend and backend protected  
✅ **Cloud Armor WAF**: OWASP rules enabled  
✅ **HTTPS Only**: HTTP redirects to HTTPS  
✅ **VPC Isolation**: Private networking  
✅ **Secret Manager**: Secure credential storage  
✅ **Health Checks**: Proper service monitoring  

## Troubleshooting

- **SSL Certificate**: Wait 5-10 minutes for activation
- **IAP 403 Errors**: Check user is in `iap_members` list
- **Health Check Failures**: Ensure containers respond on `/` and `/api/health`
- **DNS Issues**: Verify A record points to `lb_ip_address`

## Clean Up

```bash
terraform destroy -auto-approve
```