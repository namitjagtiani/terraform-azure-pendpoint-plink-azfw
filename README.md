# Using Azure Private Endpoints and Private Link Service with Azure Firewall

This repo contains the components required to test the Azure Private Endpoint and Private Link functionality outlined in the This site was built using [Blog article](https://namitjagtiani.com/2020/02/14/azure-private-link-udr-support-public-preview/).

## How to use this repo to deploy the code

### 1. Clone the repo

Run the `git clone <repo url>` command to clone the repo locally.

### 2. Create a tfvars file

Create a local `terraform.tfvars` file in the below format.



```hcl
username = "adminuser"
password = "P@$$w0rd1234!"


plink_sub_sub_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_cl_id  = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_cl_sec = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
plink_sub_ten_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
```
Replace the "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" values with the relevant information based on your `Producer subscription`.