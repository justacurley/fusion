variable "table_name_prefix" {
  type        = string
  description = "Prefix for DynamoDB table names"
  default     = "fusion"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, production)"
  default     = "production"
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for DynamoDB tables"
  default     = false
}

variable "enable_point_in_time_recovery" {
  type        = bool
  description = "Enable point-in-time recovery for DynamoDB tables"
  default     = true
}

variable "billing_mode" {
  type        = string
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}

variable "read_capacity" {
  type        = number
  description = "Read capacity units (only used if billing_mode is PROVISIONED)"
  default     = 5
}

variable "write_capacity" {
  type        = number
  description = "Write capacity units (only used if billing_mode is PROVISIONED)"
  default     = 5
}
