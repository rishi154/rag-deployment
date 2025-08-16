# Apigee X AI Gateway Module

This module sets up Apigee X for AI Gateway functionality.

## Usage

```hcl
module "apigee" {
  source              = "./apigee"
  project_id          = var.project_id
  region              = var.region
  ai_gateway_hostname = "api.nvrstech.com"
  vpc_network         = module.network.vpc_id
}
```

## What it creates

- Apigee X Organization
- Apigee Environment (ai-env)
- Apigee Instance
- Environment Group for hostname routing
- Required API enablement

## Requirements

- Billing account enabled
- Apigee X pricing applies (~$45/month minimum)
- VPC network for authorized network

## Outputs

- `apigee_endpoint` - Gateway endpoint URL
- `apigee_org_id` - Organization ID
- `apigee_environment` - Environment name