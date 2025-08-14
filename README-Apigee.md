# Apigee AI Gateway — README (added to Terraform package)

This package includes Apigee AI Gateway artifacts to deploy a simple AI gateway proxy (`vertex-ai-gateway`) and basic prompt hygiene & quota policies.

## Important notes before using
- Apigee organization creation may require additional Org-level IAM roles and can take 30–60 minutes.
- Terraform's Apigee resources may not cover every organization-level manual consent step (OAuth brands, analytics settings). Review the Apigee Console if any step fails.
- The proxy bundle is a minimal example; review policies before sending production data through it.

## Quick deploy
1. Inspect `apigee.tf` and update `var.ai_gateway_hostname` and any other variables.
2. `terraform init`
3. `terraform apply -var="project_id=YOUR_PROJECT" -var="domain_name=yourdomain.com" -var="ai_gateway_hostname=ai-gateway.yourdomain.com"`

## Testing the AI Gateway
After deployment, use the AI gateway URL (terraform output `ai_gateway_url`) and send a POST similar to the Vertex AI predict endpoint. The gateway will apply prompt hygiene and quota policies before forwarding to Vertex AI.

## Proxy bundle
The `apigee-proxy/apiproxy.zip` is included and contains:
- `vertex-ai-gateway.xml` — API proxy descriptor
- `policies/PromptGuard-LLM.xml` — simple prompt blocklist
- `policies/QuotaPolicy.xml` — simple quota policy (60 req/min)
