# Bitcast AWS Nitro Enclave Stack

Terraform modules that lay down the AWS infrastructure required to run Bitcast inside Nitro Enclaves, mirroring the deployment goals in [bitcast-network/bitcast-deploy](https://github.com/bitcast-network/bitcast-deploy).

## Stack Overview
### `modules/network`
Creates a DNS-enabled VPC, internet gateway, and the requested public subnets. Route tables are associated automatically so Nitro parent instances can reach AWS APIs and pull enclave artifacts. Inputs: `vpc_cidr`, `public_subnet_cidrs`, optional AZ overrides, and shared `tags`. Outputs: `vpc_id` plus `public_subnet_ids` for downstream modules.

### `modules/kms`
Provisioning this module is optional and controlled via `create_kms_key`/`kms_key_arn`. When enabled it creates a CMK and alias dedicated to Nitro enclave attestation payloads or vsock proxy secrets. Exported `key_arn` can be passed to enclave applications; alternatively provide an existing ARN from your environment.

### `modules/enclave_instance`
Launches a Nitro-capable Amazon Linux 2023 EC2 parent instance. It wires up security groups, IAM role/profile, enables the Nitro allocator and vsock proxy services via user data, and exposes tuning inputs (`enclave_cpu_count`, `enclave_memory_mib`, `allowed_ingress_cidrs`, etc.). Outputs surface the instance ID, security group ID, and IAM instance profile.

## Usage
1. Copy `terraform.tfvars.template` to `terraform.tfvars` and adjust region, CIDRs, key pair, etc.
2. (Optional) Update `backend.tf` with your S3 bucket/DynamoDB table for remote state.
3. Run `terraform init && terraform plan` (requires internet access to pull providers).
4. Apply when ready: `terraform apply`.

Outputs include VPC/subnets, the parent EC2 instance ID, security group, instance profile, and the KMS ARN when provisioned. Use the resulting parent instance as the target host for the Bitcast enclave workloads described in the Bitcast deployment guide.

For application build/run instructions, consult the upstream [bitcast-network/bitcast-deploy README](https://github.com/bitcast-network/bitcast-deploy/blob/main/README.md); this Terraform stack simply prepares the AWS infrastructure that deployment expects.
