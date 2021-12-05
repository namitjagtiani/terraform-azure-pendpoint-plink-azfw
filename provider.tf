provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  alias           = "plink_sub"
  client_id       = var.plink_sub_cl_id
  client_secret   = var.plink_sub_cl_sec
  subscription_id = var.plink_sub_sub_id
  tenant_id       = var.plink_sub_ten_id
}