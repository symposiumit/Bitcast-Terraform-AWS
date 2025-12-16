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

## Bitcast GitHub Actions Pipeline

This repo includes a GitHub Actions workflow (`.github/workflows/bitcast-nitro.yml`) plus container templates under `bitcast-container/` that package the [bitcast-network/bitcast](https://github.com/bitcast-network/bitcast) codebase into a Nitro-ready enclave image.

Pipeline highlights:
- Clones the upstream Bitcast repo at a chosen ref and copies `bitcast-container/Dockerfile` + `entrypoint.sh` into it.
- Installs dependencies, runs the Bitcast test suite, builds a Linux/amd64 container, and pushes it to Amazon ECR.
- Uses the public Nitro Enclaves CLI container to convert the image into an EIF artifact and uploads it to an S3 bucket.
- Invokes AWS Systems Manager to pull the EIF onto the Nitro parent instances created by this Terraform stack and restarts the enclave with the requested CPU/memory/cid.

### Required secrets & variables

| Name | Type | Description |
| ---- | ---- | ----------- |
| `AWS_GITHUB_ROLE_ARN` | secret | IAM role ARN assumed by the workflow for AWS access (needs ECR, S3, SSM permissions). |
| `NITRO_PARENT_INSTANCE_IDS` | secret | Comma-separated list of Nitro parent EC2 instance IDs to update via SSM. |
| `AWS_REGION` | repo variable (optional) | Overrides the default AWS region (`eu-west-1`). |
| `BITCAST_ECR_REPOSITORY` | repo variable (optional) | Name of the ECR repository that stores Bitcast images (`bitcast-nitro` by default). |
| `BITCAST_ENCLAVE_BUCKET` | repo variable (optional) | S3 bucket holding EIF artifacts (`bitcast-nitro-enclaves` default). |
| `BITCAST_ENCLAVE_PREFIX` | repo variable (optional) | Folder/prefix inside the bucket for EIF uploads (`eif` default). |

Run the workflow manually via **Actions → Build Bitcast Enclave → Run workflow**, choose the Bitcast git ref and neuron role (validator/miner), and provide the desired enclave resources. The pipeline handles containerization and pushes the refreshed EIF to your Nitro fleet automatically.
