variable "region" {
  description = "The region for all applicable resources"
  type        = string
}

variable "application" {
  type = object({
    src_dir = string
    port    = number
  })

  default = {
    src_dir = "app"
    port    = 80
  }
}
variable "domain_name" {
  description = "The name of the domain to use"
  type        = string
}

variable "project_name" {
  description = "The name of the project (used when naming terraform resources)"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance."
  type        = string
  default     = "t2.micro"
}

variable "enable_enhanced_reporting_enabled" {
  description = "Whether or not to enable enhanced reporting"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Whether or not to enable cloudwatch alarms"
  type        = bool
  default     = false
}

variable "autoscaling" {
  type = object({
    min_size        = number
    max_size        = number
    breach_duration = number
  })

  default = {
    min_size        = 1
    max_size        = 4
    breach_duration = 5
  }
}

variable "sns_subscription_emails" {
  description = "List of email addresses to send alarms to."
  type        = list(string)
}
