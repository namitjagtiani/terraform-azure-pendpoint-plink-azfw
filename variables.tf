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
  description = "value"
}

variable "password" {
  description = "value"
}

variable "plink_sub_cl_id" {
  description = "value"
}

variable "plink_sub_cl_sec" {
  description = "value"
}

variable "plink_sub_sub_id" {
  description = "value"
}

variable "plink_sub_ten_id" {
  description = "value"
}

