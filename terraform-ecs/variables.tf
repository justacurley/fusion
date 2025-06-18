variable "my_pip" {
  type    = string
  default = "71.218.104.230"
}
variable "force_new_svc_deployment" {
  description = "will force a new deployment of ecs service and tasks"
  type        = bool
  default     = false
}