# Using Azure Private Endpoints and Private Link Service with Azure Firewall

This repo contains the components required to test the Azure Private Endpoint and Private Link functionality outlined in the This site was built using [Blog article](https://namitjagtiani.com/2020/02/14/azure-private-link-udr-support-public-preview/).

hcl```
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
```