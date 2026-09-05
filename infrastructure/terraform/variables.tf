variable "environment" {
  type        = string
  description = "Target deployment tier (dev, test, prod)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
  default     = "copilotstudio"
}
