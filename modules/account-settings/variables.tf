variable "iam_role_arn" {
  type        = string
  description = "ARN of the IAM role for API Gateway to use. If not specified, a new role will be created."
  default     = null
}

variable "iam_tags_enabled" {
  type        = string
  description = "Enable/disable tags on IAM roles"
  default     = true
}

variable "permissions_boundary" {
  type        = string
  default     = ""
  description = "ARN of the policy that is used to set the permissions boundary for the role"
}