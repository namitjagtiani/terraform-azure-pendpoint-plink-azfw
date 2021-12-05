variable "vnetlist" {
  type = object({
    iaas = object({
      vname     = string
      sname     = string
      rt        = string
      addspace  = list(string)
      sprefixes = list(string)
      nsg       = string
    })
    azfw = object({
      vname     = string
      sname     = string
      rt        = string
      addspace  = list(string)
      sprefixes = list(string)
      nsg       = string
    })
    paas = object({
      vname     = string
      sname     = string
      rt        = string
      addspace  = list(string)
      sprefixes = list(string)
      nsg       = string
    })
    plink = object({
      vname     = string
      sname     = string
      rt        = string
      addspace  = list(string)
      sprefixes = list(string)
      nsg       = string
    })
  })

  default = {
    iaas = {
      vname     = "iaas-vnet"
      sname     = "iaas-subnet"
      rt        = "iaas-rt"
      addspace  = ["10.0.0.0/16"]
      sprefixes = ["10.0.0.0/24"]
      nsg       = ""
    }
    azfw = {
      vname     = "azfw-vnet"
      sname     = "AzureFirewallSubnet"
      rt        = ""
      addspace  = ["10.1.0.0/16"]
      sprefixes = ["10.1.0.0/24"]
      nsg       = ""
    }
    paas = {
      vname     = "paas-vnet"
      sname     = "paas-subnet"
      rt        = ""
      addspace  = ["10.2.0.0/16"]
      sprefixes = ["10.2.0.0/24"]
      nsg       = "paas-nsg"
    }
    plink = {
      vname     = "plink-vnet"
      sname     = "plink-subnet"
      rt        = ""
      addspace  = ["10.3.0.0/16"]
      sprefixes = ["10.3.0.0/24"]
      nsg       = ""
    }
  }
}

variable "username" {
  description = "Virtual Machine Login Username"
}

variable "password" {
  description = "Virtual Machine Login Password"
}

variable "plink_sub_cl_id" {
  description = "Producer Subscription Client ID"
}

variable "plink_sub_cl_sec" {
  description = "Producer Subscription Client Secret"
}

variable "plink_sub_sub_id" {
  description = "Producer Subscription ID"
}

variable "plink_sub_ten_id" {
  description = "Producer Subscription Tenant ID"
}

variable "pendpoint_sub_id" {
  description = "Consumer Subscription ID"
}


