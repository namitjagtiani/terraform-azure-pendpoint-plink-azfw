# Using Azure Private Endpoints and Private Link Service with Azure Firewall

This repo contains the components required to test the Azure Private Endpoint and Private Link functionality outlined in the This site was built using [Blog article](https://namitjagtiani.com/2020/02/14/azure-private-link-udr-support-public-preview/).

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

### 1. Clone the repo

Run the `git clone <repo url>` command to clone the repo locally.

### 2. Create a local tfvars file

Create a local `terraform.tfvars` file within this repo, in the below format.

```hcl
username = "adminuser"
password = "P@$$w0rd1234!"


plink_sub_sub_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_cl_id  = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_cl_sec = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_ten_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
```

Replace the "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" values with the relevant information based on your `Producer subscription`.

### 3. Initialize the Terraform Code

Run `terraform init` to initialise the code and download the required providers.

### 4. Authenticate to the Azure portal

Run the `az login` command to authenticate to your Azure consumer tenancy.

### 5. Create a deployment plan

Run `terraform plan` to ensure the code is validated and the correct components are listed in the items to be created.

### 6. Deploy the resources to Azure

Run `terraform apply` to deploy the resources to your Azure tenancy. You can suffix the `--auto-approve` flag to the apply command to avoid the confirmation message.

## 7. Clean up

run the `terraform destroy` command to delete all the created resources once you are done testing the required functionality.