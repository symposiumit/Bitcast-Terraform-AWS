# Bitcast AWS Nitro Enclave Stack

Terraform modules that lay down the AWS infrastructure required to run Bitcast inside Nitro Enclaves, mirroring the deployment goals in [bitcast-network/bitcast-deploy](https://github.com/bitcast-network/bitcast-deploy).

## Stack Overview
- `modules/network`: VPC with public subnets for Nitro-capable parent instances.
- `modules/kms`: Optional KMS key and alias for attestation payloads.
- `modules/enclave_instance`: EC2 parent instance (AL2023) with Nitro allocator and vsock proxy enabled.

## Usage
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust region, CIDRs, key pair, etc.
2. (Optional) Update `backend.tf` with your S3 bucket/DynamoDB table for remote state.
3. Run `terraform init && terraform plan` (requires internet access to pull providers).
4. Apply when ready: `terraform apply`.

Outputs include VPC/subnets, the parent EC2 instance ID, security group, instance profile, and the KMS ARN when provisioned. Use the resulting parent instance as the target host for the Bitcast enclave workloads described in the Bitcast deployment guide.

For application build/run instructions, consult the upstream [bitcast-network/bitcast-deploy README](https://github.com/bitcast-network/bitcast-deploy/blob/main/README.md); this Terraform stack simply prepares the AWS infrastructure that deployment expects.
