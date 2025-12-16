variable "aws_region" {
  description = "AWS region to deploy the Nitro Enclave stack into."
  type        = string
}

variable "project" {
  description = "Short name used for tagging and resource names."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all created resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC hosting Nitro Enclave parents."
  type        = string
  default     = "10.60.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for the public subnets hosting Nitro Enclave parent instances."
  type        = list(string)
  default     = ["10.60.1.0/24"]
}

variable "availability_zones" {
  description = "List of AZs to associate with the provided subnet CIDRs. Leave empty to auto-pick."
  type        = list(string)
  default     = []
}

variable "parent_instance_type" {
  description = "Nitro-based EC2 instance type that will host enclaves."
  type        = string
  default     = "m6i.xlarge"
}

variable "parent_instance_name" {
  description = "Name tag applied to the parent EC2 instance."
  type        = string
  default     = "nitro-enclave-parent"
}

variable "ssh_key_name" {
  description = "Optional EC2 key pair name for SSH access to the parent instance."
  type        = string
  default     = null
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks permitted to reach the parent instance (TCP/22)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enclave_cpu_count" {
  description = "Number of vCPUs allocated per enclave from the parent instance."
  type        = number
  default     = 2
}

variable "enclave_memory_mib" {
  description = "Memory given to the enclave allocator in MiB."
  type        = number
  default     = 2048
}

variable "create_kms_key" {
  description = "Create a dedicated KMS key for enclave attestation payloads."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing KMS key ARN to reuse. Overrides automatic key creation when set."
  type        = string
  default     = null
}
