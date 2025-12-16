output "vpc_id" {
  description = "ID of the VPC that hosts the Nitro Enclave parent instances."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Subnets containing Nitro Enclave parent instances."
  value       = module.network.public_subnet_ids
}

output "parent_instance_id" {
  description = "EC2 instance ID running Nitro Enclaves."
  value       = module.enclave_parent.instance_id
}

output "parent_security_group_id" {
  description = "Security group protecting the parent EC2 instance."
  value       = module.enclave_parent.security_group_id
}

output "enclave_instance_profile" {
  description = "Instance profile attached to the Nitro Enclave parent instance."
  value       = module.enclave_parent.instance_profile_name
}

output "kms_key_arn" {
  description = "KMS key used by the enclave parent (if provisioned)."
  value       = coalesce(var.kms_key_arn, try(module.kms[0].key_arn, null))
}
