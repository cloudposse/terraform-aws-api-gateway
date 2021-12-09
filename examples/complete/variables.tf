variable "region" {
  type        = string
  description = "AWS Region"
}

variable "logging_level" {
  type    = string
  default = "INFO"

  validation {
    condition     = contains(["OFF", "INFO", "ERROR"], var.logging_level)
    error_message = "Valid values for var: logging_level are (OFF, INFO, ERROR)."
  }
}
