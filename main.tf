#---------------------------------------
# Resource Group
#---------------------------------------

# Create a resource group.
# Ensure that this is created in one of the supported regions for the public preview of the 
# feature or you won't be able to use the feature.
resource "azurerm_resource_group" "pe-rg" {
  name     = "pendpoint-rg"
  location = "eastus"
}

#---------------------------------------
# Virtual Networks and Subnets
#---------------------------------------

# Create virtual networks within the resource group
resource "azurerm_virtual_network" "vnets" {
  for_each            = var.vnetlist
  name                = each.value.vname
  resource_group_name = azurerm_resource_group.pe-rg.name
  location            = azurerm_resource_group.pe-rg.location
  address_space       = each.value.addspace
}

# Create required subnets for Firewall, Iaas and PaaS
resource "azurerm_subnet" "subnets" {
  for_each                                       = var.vnetlist
  name                                           = each.value.sname
  resource_group_name                            = azurerm_resource_group.pe-rg.name
  virtual_network_name                           = each.value.vname
  address_prefixes                               = each.value.sprefixes
  enforce_private_link_endpoint_network_policies = each.value == "plink" ? true : false # This is required to use the UDR and NSG functionality
  enforce_private_link_service_network_policies  = each.value == "plink" ? true : false # This is required to use the UDR and NSG functionality
  depends_on = [
    azurerm_virtual_network.vnets
  ]
}

#---------------------------------------
# Virtual Network Peering
#---------------------------------------

resource "azurerm_virtual_network_peering" "iaas-to-azfw" {
  name                         = "peering-to-azfw"
  resource_group_name          = azurerm_resource_group.pe-rg.name
  virtual_network_name         = azurerm_virtual_network.vnets["iaas"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnets["azfw"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "paas-to-azfw" {
  name                         = "peering-to-azfw"
  resource_group_name          = azurerm_resource_group.pe-rg.name
  virtual_network_name         = azurerm_virtual_network.vnets["paas"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnets["azfw"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "plink-to-azfw" {
  name                         = "peering-to-azfw"
  resource_group_name          = azurerm_resource_group.pe-rg.name
  virtual_network_name         = azurerm_virtual_network.vnets["plink"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnets["azfw"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "azfw-to-iaas" {
  name                         = "peering-to-iaas"
  resource_group_name          = azurerm_resource_group.pe-rg.name
  virtual_network_name         = azurerm_virtual_network.vnets["azfw"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnets["iaas"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "azfw-to-paas" {
  name                         = "peering-to-paas"
  resource_group_name          = azurerm_resource_group.pe-rg.name
  virtual_network_name         = azurerm_virtual_network.vnets["azfw"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnets["paas"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "azfw-to-plink" {
  name                         = "peering-to-plink"
  resource_group_name          = azurerm_resource_group.pe-rg.name
  virtual_network_name         = azurerm_virtual_network.vnets["azfw"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnets["plink"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}

#---------------------------------------
# Azure Firewall and Public IP
#---------------------------------------

# Create Azure Firewall Public IP
resource "azurerm_public_ip" "azfw-pip" {
  name                = "azfw-pip"
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Azure Firewall
resource "azurerm_firewall" "azfw" {
  name                = "azfw"
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name
  # private_ip_ranges = ["0.0.0.0/0"]

  ip_configuration {
    name                 = "azfw-ipconfig"
    subnet_id            = azurerm_subnet.subnets["azfw"].id
    public_ip_address_id = azurerm_public_ip.azfw-pip.id
  }
}

# Create Azure Firewall Rule Collection
resource "azurerm_firewall_application_rule_collection" "pendpoint-app-rc" {
  name                = "azfw-pendpoint-app-rc"
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.pe-rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name = "allow-vm-to-pendpoint"

    source_addresses = [
      "10.0.0.0/24",
    ]

    target_fqdns = [
      "pendpoint-test-webapp.azurewebsites.net",
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

# resource "azurerm_firewall_network_rule_collection" "pendpoint-net-rc" {
#   name                = "azfw-pendpoint-net-rc"
#   azure_firewall_name = azurerm_firewall.azfw.name
#   resource_group_name = azurerm_resource_group.pe-rg.name
#   priority            = 1001
#   action              = "Allow"

#   rule {
#     name = "allow-vm-to-pendpoint"

#     source_addresses = [
#       "10.0.0.0/24",
#     ]

#     destination_ports = [
#       "443",
#     ]

#     destination_addresses = [
#       "10.2.0.4"
#     ]

#     protocols = [
#       "TCP",
#     ]
#   }
# }

# resource "azurerm_firewall_application_rule_collection" "plink-app-rc" {
#   name                = "azfw-plink-app-rc"
#   azure_firewall_name = azurerm_firewall.azfw.name
#   resource_group_name = azurerm_resource_group.pe-rg.name
#   priority            = 1000
#   action              = "Allow"

#   rule {
#     name = "allow-vm-to-plink"

#     source_addresses = [
#       "10.0.0.0/24",
#     ]

#     target_fqdns = [
#       "plink-test-webapp.privatelink.azurewebsites.net",
#     ]

#     protocol {
#       port = "80"
#       type = "Http"
#     }
#   }
# }

# resource "azurerm_firewall_network_rule_collection" "plink-net-rc" {
#   name                = "azfw-plink-net-rc2"
#   azure_firewall_name = azurerm_firewall.azfw.name
#   resource_group_name = azurerm_resource_group.pe-rg.name
#   priority            = 1001
#   action              = "Allow"

#   rule {
#     name = "allow-vm-to-plink"

#     source_addresses = [
#       "10.0.0.0/24",
#     ]

#     destination_ports = [
#       "80",
#     ]

#     destination_addresses = [
#       "10.3.0.4"
#     ]

#     protocols = [
#       "TCP",
#     ]
#   }
# }

#---------------------------------------
# Route Tables
#---------------------------------------

# Create Route Tables
resource "azurerm_route_table" "route-table" {
  name                          = "iaas-rt"
  location                      = azurerm_resource_group.pe-rg.location
  resource_group_name           = azurerm_resource_group.pe-rg.name
  disable_bgp_route_propagation = true

  route {
    name                   = "pendpoint"
    address_prefix         = "10.2.0.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.0.4"
  }

  route {
    name                   = "plink"
    address_prefix         = "10.3.0.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.0.4"
  }
}

# Associate created Route Tables with Subnets
resource "azurerm_subnet_route_table_association" "rt-association" {
  subnet_id      = azurerm_subnet.subnets["iaas"].id
  route_table_id = azurerm_route_table.route-table.id
}

#---------------------------------------
# Network Security Groups
#---------------------------------------

# Create Network Security Group for PaaS subnet
resource "azurerm_network_security_group" "paas-nsg" {
  name                = var.vnetlist["paas"].nsg
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name

  # security_rule {
  #   name                       = "test123"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }
}

# Associate Network Security Groups with subnets
# resource "azurerm_subnet_network_security_group_association" "paas-nsga" {
#   subnet_id                 = azurerm_subnet.subnets["paas"].id
#   network_security_group_id = azurerm_network_security_group.paas-nsg.id
# }

#---------------------------------------
# Private DNS Zone
#---------------------------------------

# Create Private DNS Zone
resource "azurerm_private_dns_zone" "pdns" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.pe-rg.name
}

# Create VNET link to Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "iaas-vnet-link" {
  name                  = "iaas-link"
  resource_group_name   = azurerm_resource_group.pe-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pdns.name
  virtual_network_id    = azurerm_virtual_network.vnets["iaas"].id
}

resource "azurerm_private_dns_zone_virtual_network_link" "azfw-vnet-link" {
  name                  = "azfw-link"
  resource_group_name   = azurerm_resource_group.pe-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pdns.name
  virtual_network_id    = azurerm_virtual_network.vnets["azfw"].id
}

# Create A records for Private Endpoint
resource "azurerm_private_dns_a_record" "arecord1" {
  name                = "pendpoint-test-webapp"
  zone_name           = azurerm_private_dns_zone.pdns.name
  resource_group_name = azurerm_resource_group.pe-rg.name
  ttl                 = 10
  records             = ["10.2.0.4"]
}

resource "azurerm_private_dns_a_record" "arecord2" {
  name                = "pendpoint-test-webapp.scm"
  zone_name           = azurerm_private_dns_zone.pdns.name
  resource_group_name = azurerm_resource_group.pe-rg.name
  ttl                 = 10
  records             = ["10.2.0.4"]
}

resource "azurerm_private_dns_a_record" "arecord3" {
  name                = "plink-test-webapp"
  zone_name           = azurerm_private_dns_zone.pdns.name
  resource_group_name = azurerm_resource_group.pe-rg.name
  ttl                 = 10
  records             = ["10.3.0.4"]
}

#---------------------------------------
# Private Endpoints
#---------------------------------------

# Create Private Endpoint for the App Service
resource "azurerm_private_endpoint" "pendpoint" {
  depends_on          = [azurerm_app_service.webapp]
  name                = "web-pendpoint"
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name
  subnet_id           = azurerm_subnet.subnets["paas"].id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.pdns.id]
  }

  private_service_connection {
    name                           = "web-privateserviceconnection"
    private_connection_resource_id = azurerm_app_service.webapp.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
}

resource "azurerm_resource_group_template_deployment" "temp" {
  name                = "arm"
  resource_group_name = azurerm_resource_group.pe-rg.name
  template_content    = file("${path.module}/templates/template.json")
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    location                    = { value = azurerm_resource_group.pe-rg.location }
    privateEndpointName         = { value = "plink-pendpoint" }
    privateLinkResource         = { value = azurerm_private_link_service.plink-svc.alias }
    targetSubResource           = { value = [] }
    requestMessage              = { value = "" }
    subnet                      = { value = azurerm_subnet.subnets["plink"].id }
    virtualNetworkId            = { value = azurerm_virtual_network.vnets["plink"].id }
    virtualNetworkResourceGroup = { value = azurerm_resource_group.pe-rg.name }
    subnetDeploymentName        = { value = "testdeploy" }
    Id                          = { value = "/subscriptions/<replace with your subscription id>/resourceGroups/pendpoint-rg/providers/Microsoft.Network/virtualNetworks/plink-vnet/subnets/plink-subnet" }
  })
  depends_on = [
    azurerm_subnet.subnets
  ]
}

#---------------------------------------
# App Services
#---------------------------------------

# Create App Service Plan
# Ensure you select a PremiumV2 plan to be able to use Private Endpoints
resource "azurerm_app_service_plan" "asp" {
  name                         = "pendpoint-test-asp"
  location                     = azurerm_resource_group.pe-rg.location
  resource_group_name          = azurerm_resource_group.pe-rg.name
  maximum_elastic_worker_count = 1
  kind                         = "Windows"

  sku {
    tier     = "PremiumV2"
    size     = "P1v2"
    capacity = 1
  }
}

# Create App Service
resource "azurerm_app_service" "webapp" {
  name                = "pendpoint-test-webapp"
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  source_control {
    repo_url           = "https://github.com/Azure-Samples/html-docs-hello-world"
    branch             = "master"
    manual_integration = true
    use_mercurial      = false
  }
}

#---------------------------------------
# Azure Bastion
#---------------------------------------

# Create Azure Bastion subnet
resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.pe-rg.name
  virtual_network_name = azurerm_virtual_network.vnets["iaas"].name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Azure Bastion Public IP
resource "azurerm_public_ip" "bastion-pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Azure Bastion Host
resource "azurerm_bastion_host" "bastion-host" {
  name                = "bastion-host"
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}

#---------------------------------------
# Test Virtual Machine
#---------------------------------------

# Create Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets["iaas"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Test Virtual Machine
resource "azurerm_windows_virtual_machine" "test-vm" {
  name                  = "test-vm"
  resource_group_name   = azurerm_resource_group.pe-rg.name
  location              = azurerm_resource_group.pe-rg.location
  size                  = "Standard_F2"
  admin_username        = var.username
  admin_password        = var.password
  license_type          = "Windows_Server"
  network_interface_ids = [azurerm_network_interface.nic.id]

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

#---------------------------------------
# Log Analytics Workspace
#---------------------------------------

resource "azurerm_log_analytics_workspace" "la-wks" {
  name                = "pendpoint-wks"
  location            = azurerm_resource_group.pe-rg.location
  resource_group_name = azurerm_resource_group.pe-rg.name
  sku                 = "Free"
  retention_in_days   = 7
}

resource "azurerm_monitor_diagnostic_setting" "azfw-diag" {
  name                       = "azfwdiag"
  target_resource_id         = azurerm_firewall.azfw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.la-wks.id
  depends_on = [
    azurerm_firewall_application_rule_collection.pendpoint-app-rc,
    # azurerm_firewall_network_rule_collection.pendpoint-net-rc, 
    # azurerm_firewall_application_rule_collection.plink-app-rc, 
    # azurerm_firewall_network_rule_collection.plink-net-rc
  ]

  log {
    category = "AzureFirewallNetworkRule"
    enabled  = true
  }

  log {
    category = "AzureFirewallApplicationRule"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
  }
}