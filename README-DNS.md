
# Domain + DNS Setup for FE & BE Subdomains

## Step 1: Buy Domain
Purchase your desired domain in [Google Domains](https://domains.google). Example: `mychatbot.xyz`.

## Step 2: Set Nameservers
After `terraform apply`, note the `dns_name_servers` output.  
In Google Domains → DNS → "Use custom name servers" → enter the Cloud DNS nameservers from Terraform output.

## Step 3: DNS Records
Terraform creates:
- `chat.<domain>` → Points to Frontend Cloud Run via HTTPS Load Balancer
- `api.<domain>` → Points to Backend Cloud Run via HTTPS Load Balancer

## Step 4: IAP Protection
Both subdomains are behind IAP.  
Access requires Google login with allowed accounts.

## Step 5: Wait for Propagation
DNS changes can take minutes to hours. Google Managed SSL certs activate automatically.

## Step 6: Access
- Frontend: `https://chat.<yourdomain>`  
- Backend API: `https://api.<yourdomain>`  
Both require Google authentication.
