# Create the fusion resource group
resource "azurerm_resource_group" "fusion" {
  name     = "fusion"
  location = "West US 2" # Azure equivalent of us-west-2

  tags = {
    Environment = "production"
    Project     = "fusion"
    ManagedBy   = "terraform"
  }
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "fusion_logs" {
  name                = "fusion-log-analytics"
  location            = azurerm_resource_group.fusion.location
  resource_group_name = azurerm_resource_group.fusion.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "production"
    Project     = "fusion"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.fusion.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.fusion.location
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.fusion_logs.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.fusion_logs.name
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.fusion_logs.primary_shared_key
  sensitive   = true
}
