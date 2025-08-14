# RAG on GCP — Terraform Starter (Cloud Run + HTTPS LB + Cloud Armor + VPC + NAT)

This starter stands up a **production-ready baseline** for your RAG stack:

- 2 Cloud Run services:
  - `rag-backend` (Python agent with internet egress via VPC Connector + Cloud NAT)
  - `rag-frontend` (React app)
- Global HTTPS Load Balancer (path-based routing: `/api/*` -> backend, `/` -> frontend)
- Managed SSL cert for your domain
- Cloud Armor WAF policy (with sensible OWASP/anti-abuse rules)
- VPC, Subnet, Cloud Router + Cloud NAT
- Serverless VPC Connector (egress via NAT; restrict egress with firewall rules)
- Secret Manager integration (mount or env-injection for API keys)
- Logging sinks (Error logs kept local; optional sink to BigQuery/Storage)
- Basic Uptime Check + Alerting policies
- Required APIs enabled

> **Note**: This is a *starter*. Review and tailor before production. Add VPC Service Controls, CMEK, and GitOps as needed.

## Prereqs

- Terraform >= 1.6
- gcloud authenticated with a user that can create infra in the target project
- A DNS-managed domain you control (Cloud DNS or external) and ability to point an A/AAAA to the LB IP

## Quick start

```bash
terraform init
terraform plan -var="project_id=YOUR_PROJECT" -var="region=us-central1" -var="domain_name=your.domain.com"
terraform apply -auto-approve -var="project_id=YOUR_PROJECT" -var="region=us-central1" -var="domain_name=your.domain.com"
```

After `apply`:
1. Point your domain's A/AAAA to the printed `lb_ip_address` output.
2. Wait for the **Managed SSL cert** to become ACTIVE (usually minutes).
3. Deploy your containers to Artifact Registry & update `image` values (or wire CI/CD). See `samples/cloudbuild/`.
4. Verify:
   - `https://your.domain.com/` serves the frontend.
   - `https://your.domain.com/api/health` hits backend (example handler).

## Structure

- `apis/` — enable required services
- `modules/` — reusable modules (network, cloudrun, armor, lb, logging, secrets)
- `env/` — root compositions
- `samples/` — Cloud Build YAMLs and Dockerfile examples

## Security Notes (high-level)

- End-user auth: Prefer **IAP** or **Google Identity Platform (GIP)** in front of the LB.
- Backend auth: Cloud Run requires auth; with LB+Cloud Armor use IAP or signed OIDC from FE via a BFF.
- Internet egress for the agent is allowed via **VPC Connector + NAT**; apply **egress firewall** allowlist rules.
- Store all sensitive config in **Secret Manager**; mount in Cloud Run (volumes) or inject via env.
- Enable **Audit Logs**, **Log-based Metrics**, **Alerting**. Consider **VPC Service Controls** for Vertex AI & Storage.
- Consider replacing **Chroma** with **AlloyDB/Cloud SQL + pgvector** for durability and HA; if staying on Chroma, run on GKE with PD.

See inline comments in the modules for more details.

---

## Add-on: Cloud SQL PostgreSQL + pgvector (replacing Chroma)

This edition provisions a **private IP** Cloud SQL PostgreSQL 15 instance and wires secrets+env
for the backend. After `apply`, run the following once to enable pgvector:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### Connection details injected into backend (via Secret Manager)
- `DB_HOST` — private IP of the instance
- `DB_NAME` — database name
- `DB_USER` — database user
- `DB_PASSWORD` — database password

### Example SQL schema
```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE TABLE IF NOT EXISTS rag_vectors (
  id TEXT PRIMARY KEY,
  embedding vector(1536),
  metadata JSONB,
  document TEXT
);
CREATE INDEX IF NOT EXISTS rag_vectors_embedding_idx ON rag_vectors USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

### Example Python (SQLAlchemy + psycopg2)
```python
import os
from sqlalchemy import create_engine, text

db_user = os.environ["DB_USER"]
db_pass = os.environ["DB_PASSWORD"]
db_name = os.environ["DB_NAME"]
db_host = os.environ["DB_HOST"]  # private IP (no proxy)
engine = create_engine(f"postgresql+psycopg2://{db_user}:{db_pass}@{db_host}:5432/{db_name}")
```

> Tip: For stricter security, switch to **IAM DB Auth** and remove static passwords.

---

## IAP (Identity-Aware Proxy) — Protect BOTH Frontend & Backend

This edition can protect **both** the React frontend and the Python backend behind the HTTPS Load Balancer using **IAP**.

### 1) Create OAuth Consent Screen & IAP OAuth Client (one-time)
```bash
# Create an OAuth brand (External or Internal as per your org)
gcloud iap oauth-brands create \
  --application_title="RAG Chatbot" \
  --support_email="YOUR_EMAIL@EXAMPLE.COM"

# Get BRAND ID
gcloud iap oauth-brands list

# Create the OAuth client for IAP
gcloud iap oauth-clients create BRAND_ID \
  --display_name="RAG HTTPS LB"
# Capture and store the client_id and client_secret
```

> The OAuth consent screen must be configured in the Cloud Console UI at least once (scopes, domain, etc.).

### 2) Set Terraform variables for IAP
Create `terraform.tfvars`:
```hcl
project_id        = "YOUR_PROJECT"
region            = "us-central1"
domain_name       = "chat.yourdomain.com"

# IAP
enable_iap        = true
iap_client_id     = "YOUR_IAP_CLIENT_ID"
iap_client_secret = "YOUR_IAP_CLIENT_SECRET"
iap_members = [
  "user:alice@example.com",
  "group:ml-team@example.com",
  # "serviceAccount:frontend-caller@YOUR_PROJECT.iam.gserviceaccount.com"
]
```

### 3) Apply
```bash
terraform init
terraform apply
```

### 4) Behavior
- **Frontend**: The root `https://chat.yourdomain.com/` is behind IAP. Users must sign in before seeing the UI.
- **Backend**: `https://chat.yourdomain.com/api/*` also behind IAP. The same session covers both.
- **Headers**: After auth, IAP injects `X-Goog-Authenticated-User-Email` and `X-Goog-Authenticated-User-Id` to the backend.
- **Service-to-service**: If your **frontend** (or another service) needs to call the backend programmatically, grant its **service account** access by adding it to `iap_members` as `serviceAccount:...` and obtain an IAP-signed token if calling from outside the LB.

### 5) Notes & Tips
- Keep Cloud Run services set to allow ingress from **All** or **Internal + LB** (LB health checks must reach them). Traffic still gates through IAP at the LB.
- You can also use **Google Groups** in `iap_members` for easier user management.
- Combine with **Cloud Armor** WAF; IAP runs before your containers execute.
- For local development, access the FE URL; IAP will prompt for Google login.

### 6) Troubleshooting
- If you see 403 errors, confirm:
  - The user/account is listed in `iap_members`.
  - The OAuth brand & client are created and the **client id/secret** are set in TF.
  - The domain in the Managed SSL cert is validated (DNS A/AAAA pointing to LB IP).
  - `enable_iap=true` and both `iap_client_id/secret` are non-empty.
