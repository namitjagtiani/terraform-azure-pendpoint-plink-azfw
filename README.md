# Using Azure Private Endpoints and Private Link Service with Azure Firewall

This repo contains the components required to build and test the Azure Private Endpoint and Private Link functionality outlined in this blog article [Blog article](https://namitjagtiani.com/2020/02/14/azure-private-link-udr-support-public-preview/).

## Deployment diagram

![Deployment diagram](/deployment_diagram.png)

## How to use this repo to deploy the code

The repo contains the following files.

| File Name | Purpose |
| ----------- | ----------- |
| .gitignore  | The contents in this file are not committed to this repository |
| backend.tf  | This file contains the Terraform and state config |
| provider.tf  | This file contains the Azure Terraform provider, versioning and any additional provider specific features  |
| private_link.tf  | This file contains the Producer subscription components that will be deployed |
| main.tf  | This file contains all the Consumer subscription components that will be deployed |
| variables.tf  | This file contains all the variables used to populate the information in the main.tf and private_link.tf files |
| README.md | This file dictates how to use this repo to deploy the code to your respective Azure tenancies |

### 1. Pre-Requisites

- Two Azure subscriptions to hold producer and consumer resources respectively.
- An Azure Service Principal with a generated and valid Client Secret.
- Git client for Windows or MAC.
- Terraform v1.0 or above for Windows or MAC.

### 2. Clone the repo

Run the `git clone <repo url>` command to clone the repo locally.

### 3. Create a local tfvars file

Create a `terraform.tfvars` file in your local repo, in the below format.

```hcl
username = "adminuser"
password = "P@$$w0rd1234!"


plink_sub_sub_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_cl_id  = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_cl_sec = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_ten_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
pendpoint_sub_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

```

Replace the "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" values with the relevant information based on your `Producer and Consumer subscriptions`.

Replace the `username` and `password` values with a value of your choosing.

### 4. Initialize the Terraform Code

Run `terraform init` to initialise the code and download the required providers.

### 5. Authenticate to the Azure portal

Run the `az login` command to authenticate to your Azure consumer tenancy.

### 6. Create a deployment plan

Run `terraform plan` to ensure the code is validated and the correct components are listed in the items to be created.

### 7. Deploy the resources to Azure

Run `terraform apply` to deploy the resources to your Azure tenancy. You can suffix the `--auto-approve` flag to the apply command to avoid the confirmation message.

## 8. Clean up

run the `terraform destroy` command to delete all the created resources once you are done testing the required functionality.