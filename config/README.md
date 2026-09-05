# Deployment Configuration

This folder contains environment-specific deployment settings used when a solution is imported into Test or Prod.

Use these files for values that should change between environments, such as:

- Support email addresses
- API endpoints
- Azure AI Search endpoints
- Connection reference IDs
- Feature flags

The deployment workflow passes the appropriate file to Power Platform during solution import.

Never store client secrets, API keys, or passwords in these files. Use GitHub Actions secrets, Azure Key Vault, or Power Platform connection references instead.

