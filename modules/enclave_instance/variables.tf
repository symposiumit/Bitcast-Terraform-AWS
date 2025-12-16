variable "project" {
  description = "Project prefix for tagging."
  type        = string
}

variable "name" {
  description = "Name tag for the parent EC2 instance."
  type        = string
}

variable "subnet_id" {
  description = "Subnet where the parent EC2 instance resides."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used for associated resources."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (must be Nitro-capable)."
  type        = string
}

variable "ssh_key_name" {
  description = "Optional SSH key pair name."
  type        = string
  default     = null
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks permitted for SSH access."
  type        = list(string)
}

variable "enclave_cpu_count" {
  description = "Number of CPUs allocated per enclave."
  type        = number
}

variable "enclave_memory_mib" {
  description = "Memory allocated per enclave in MiB."
  type        = number
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for enclave attestations."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply."
  type        = map(string)
}
