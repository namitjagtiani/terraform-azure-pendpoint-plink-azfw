#---------------------------------------
# Data Resources
#---------------------------------------

data "azurerm_subscription" "current" {
}

#---------------------------------------
# Resource Group
#---------------------------------------

# Create a resource group.
# Ensure that this is created in one of the supported regions for the public preview of the 
# feature or you won't be able to use the feature.
resource "azurerm_resource_group" "plink-rg" {
  name     = "plink-rg"
  location = "eastus"
  provider = azurerm.plink_sub
}

#---------------------------------------
# Virtual Networks and Subnets
#---------------------------------------

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "plink-vnet" {
  name                = "plink-vnet"
  resource_group_name = azurerm_resource_group.plink-rg.name
  location            = azurerm_resource_group.plink-rg.location
  address_space       = ["10.10.0.0/16"]
  provider            = azurerm.plink_sub
}

# Create required subnets for Firewall, Iaas and PaaS
resource "azurerm_subnet" "plink-subnet" {
  name                                          = "plink-subnet"
  resource_group_name                           = azurerm_resource_group.plink-rg.name
  virtual_network_name                          = azurerm_virtual_network.plink-vnet.name
  address_prefixes                              = ["10.10.0.0/24"]
  enforce_private_link_service_network_policies = true # This is required to use the UDR and NSG functionality
  provider                                      = azurerm.plink_sub
}

#---------------------------------------
# IIS Virtual MAchine
#---------------------------------------

# Create Network Interface
resource "azurerm_network_interface" "plink-nic" {
  name                = "plink-nic"
  location            = azurerm_resource_group.plink-rg.location
  resource_group_name = azurerm_resource_group.plink-rg.name
  provider            = azurerm.plink_sub

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.plink-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Test Virtual Machine
resource "azurerm_windows_virtual_machine" "plink-vm" {
  name                  = "plink-vm"
  resource_group_name   = azurerm_resource_group.plink-rg.name
  location              = azurerm_resource_group.plink-rg.location
  size                  = "Standard_F2"
  admin_username        = var.username
  admin_password        = var.password
  license_type          = "Windows_Server"
  network_interface_ids = [azurerm_network_interface.plink-nic.id]
  provider              = azurerm.plink_sub

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_extension_install_iis" {
  name                       = "vm_extension_install_iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.plink-vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  provider                   = azurerm.plink_sub

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
SETTINGS
}

#---------------------------------------
# Private Link Service
#---------------------------------------

resource "azurerm_public_ip" "plink-fe-pip" {
  name                = "plink-fe-pip"
  sku                 = "Standard"
  location            = azurerm_resource_group.plink-rg.location
  resource_group_name = azurerm_resource_group.plink-rg.name
  allocation_method   = "Static"
  provider            = azurerm.plink_sub
}

resource "azurerm_lb" "plink-lb" {
  name                = "plink-lb"
  sku                 = "Standard"
  location            = azurerm_resource_group.plink-rg.location
  resource_group_name = azurerm_resource_group.plink-rg.name
  provider            = azurerm.plink_sub

  frontend_ip_configuration {
    name                 = azurerm_public_ip.plink-fe-pip.name
    public_ip_address_id = azurerm_public_ip.plink-fe-pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "plink-lb-bck-pool" {
  loadbalancer_id = azurerm_lb.plink-lb.id
  name            = "BackEndAddressPool"
  depends_on = [
    azurerm_windows_virtual_machine.plink-vm
  ]
  provider = azurerm.plink_sub
}

resource "azurerm_network_interface_backend_address_pool_association" "plink-bck-pool-as" {
  network_interface_id    = azurerm_network_interface.plink-nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.plink-lb-bck-pool.id
  provider                = azurerm.plink_sub
}

resource "azurerm_lb_rule" "plink-lb-rule" {
  resource_group_name            = azurerm_resource_group.plink-rg.name
  loadbalancer_id                = azurerm_lb.plink-lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_public_ip.plink-fe-pip.name
  provider                       = azurerm.plink_sub
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.plink-lb-bck-pool.id]
  probe_id                       = azurerm_lb_probe.plink-hlth-prob.id
}

resource "azurerm_lb_probe" "plink-hlth-prob" {
  resource_group_name = azurerm_resource_group.plink-rg.name
  loadbalancer_id     = azurerm_lb.plink-lb.id
  name                = "http-running-probe"
  port                = 80
  protocol            = "Http"
  request_path        = "/"
  provider            = azurerm.plink_sub
}

resource "azurerm_private_link_service" "plink-svc" {
  name                = "plink-svc"
  location            = azurerm_resource_group.plink-rg.location
  resource_group_name = azurerm_resource_group.plink-rg.name
  provider            = azurerm.plink_sub

  auto_approval_subscription_ids = [data.azurerm_subscription.current.subscription_id]
  visibility_subscription_ids    = [data.azurerm_subscription.current.subscription_id]

  nat_ip_configuration {
    name      = azurerm_public_ip.plink-fe-pip.name
    subnet_id = azurerm_subnet.plink-subnet.id
    primary   = true
  }

  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.plink-lb.frontend_ip_configuration.0.id]
}