variable "location" {
  description = "Azure region for resources (e.g., 'East US', 'West Europe', 'Southeast Asia')"
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "Name of the project (used for resource naming). Must be lowercase, alphanumeric, and hyphens only."
  type        = string
  default     = "devopsproj04"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}
