output "key_arn" {
  description = "ARN of the created KMS key."
  value       = aws_kms_key.this.arn
}

output "alias" {
  description = "Alias attached to the KMS key."
  value       = aws_kms_alias.this.name
}
