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

# Create Application Insights (linked to Log Analytics)
resource "azurerm_application_insights" "fusion_app_insights" {
  name                = "fusion-app-insights"
  location            = azurerm_resource_group.fusion.location
  resource_group_name = azurerm_resource_group.fusion.name
  workspace_id        = azurerm_log_analytics_workspace.fusion_logs.id
  application_type    = "web"

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

output "log_analytics_connection_string" {
  description = "Log Analytics workspace connection details for applications"
  value = {
    workspace_id = azurerm_log_analytics_workspace.fusion_logs.workspace_id
    primary_key  = azurerm_log_analytics_workspace.fusion_logs.primary_shared_key
    endpoint     = "https://${azurerm_log_analytics_workspace.fusion_logs.workspace_id}.ods.opinsights.azure.com"
  }
  sensitive = true
}

output "log_analytics_ingestion_endpoint" {
  description = "Data ingestion endpoint for Log Analytics workspace"
  value       = "https://${azurerm_log_analytics_workspace.fusion_logs.workspace_id}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
}

# Application Insights outputs
output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.fusion_app_insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.fusion_app_insights.connection_string
  sensitive   = true
}

output "application_insights_app_id" {
  description = "Application Insights application ID"
  value       = azurerm_application_insights.fusion_app_insights.app_id
}
