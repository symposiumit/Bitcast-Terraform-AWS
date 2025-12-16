output "instance_id" {
  description = "ID of the Nitro Enclave parent instance."
  value       = aws_instance.parent.id
}

output "security_group_id" {
  description = "Security group protecting the parent instance."
  value       = aws_security_group.parent.id
}

output "instance_profile_name" {
  description = "IAM instance profile attached to the parent instance."
  value       = aws_iam_instance_profile.parent.name
}
