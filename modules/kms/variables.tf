variable "project" {
  description = "Project prefix for the key alias."
  type        = string
}

variable "tags" {
  description = "Tags applied to the KMS key."
  type        = map(string)
}

variable "deletion_window_in_days" {
  description = "Waiting period before key deletion."
  type        = number
  default     = 7
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation."
  type        = bool
  default     = true
}
