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

This repo includes a GitHub Actions workflow (`.github/workflows/bitcast-nitro.yml`) plus container templates under `bitcast-container/` that package the [bitcast-network/bitcast](https://github.com/bitcast-network/bitcast) codebase into a Nitro-ready enclave image. The workflow is triggered manually (`workflow_dispatch`) so operators explicitly decide which Bitcast commit and role (validator/miner) is promoted.

### Pipeline flow
1. **Checkout + Source Sync** – Actions checks out this infra repo, then clones `bitcast-network/bitcast` using the `bitcast_ref` input. The Dockerfile and entrypoint under `bitcast-container/` are copied into the Bitcast checkout so the build is reproducible from this repo.
2. **Test & Build** – Python 3.10 is configured, Bitcast dependencies are installed, and `pytest -q` is executed. Docker Buildx then builds a Linux/amd64 container tagged as `<aws_account>.dkr.ecr.<region>.amazonaws.com/<BITCAST_ECR_REPOSITORY>:<tag>` and pushes it to Amazon ECR. The role (validator/miner) is injected via the `BITCAST_ROLE` build arg for the entrypoint script.
3. **EIF Creation** – The workflow runs the public `aws-nitro-enclaves/cli` container to convert the pushed image into an EIF named `bitcast-<role>-<tag>.eif`, which is uploaded to `s3://<BITCAST_ENCLAVE_BUCKET>/<BITCAST_ENCLAVE_PREFIX>/`.
4. **Deployment to Nitro Parents** – Using AWS Systems Manager, the workflow downloads the EIF to each Nitro parent (IDs provided in `NITRO_PARENT_INSTANCE_IDS`), stores it under `/opt/bitcast/enclaves/`, and restarts the enclave with the requested CPU/memory/CID values.

Artifacts produced:
- **Container images** live in the Amazon ECR repository defined by `BITCAST_ECR_REPOSITORY` (default `bitcast-nitro`). Apply lifecycle policies there to control retention.
- **EIF binaries** are stored in the S3 bucket/prefix defined by `BITCAST_ENCLAVE_BUCKET` and `BITCAST_ENCLAVE_PREFIX` (defaults `bitcast-nitro-enclaves/eif`). Bucket versioning can be used for recovery.

### Required secrets & variables

| Name | Type | Description |
| ---- | ---- | ----------- |
| `AWS_GITHUB_ROLE_ARN` | secret | IAM role ARN assumed by the workflow for AWS access (needs ECR, S3, SSM permissions). |
| `NITRO_PARENT_INSTANCE_IDS` | secret | Comma-separated list of Nitro parent EC2 instance IDs to update via SSM. |
| `AWS_REGION` | repo variable (optional) | Overrides the default AWS region (`eu-west-1`). |
| `BITCAST_ECR_REPOSITORY` | repo variable (optional) | Name of the ECR repository that stores Bitcast images (`bitcast-nitro` by default). |
| `BITCAST_ENCLAVE_BUCKET` | repo variable (optional) | S3 bucket holding EIF artifacts (`bitcast-nitro-enclaves` default). |
| `BITCAST_ENCLAVE_PREFIX` | repo variable (optional) | Folder/prefix inside the bucket for EIF uploads (`eif` default). |
| `BITCAST_ENCLAVE_ROLE` | repo variable (optional) | Default Bitcast role when no workflow input override is provided (`validator`). |

### Running the workflow
1. Navigate to **GitHub → Actions → Build Bitcast Enclave** and click **Run workflow**.
2. Provide inputs:
   - `bitcast_ref` (branch/tag/commit from `bitcast-network/bitcast`).
   - `bitcast_role` (`validator` or `miner`).
   - Optional `image_tag` (defaults to the infra repo commit SHA).
   - `enclave_cpu_count`, `enclave_memory_mib`, `enclave_cid` (resources used by `nitro-cli run-enclave`).
3. Ensure `AWS_GITHUB_ROLE_ARN` allows:
   - `sts:AssumeRole` (trust GitHub OIDC).
   - `ecr:*` on the target repository.
   - `s3:GetObject`/`PutObject` on the EIF bucket/prefix.
   - `ssm:SendCommand` on the Nitro parent instance IDs.
4. Monitor the run. On success you’ll have a new ECR image, an EIF in S3, and Nitro parents restarted with the fresh build. Because the process is fully declarative, rerunning with the same inputs will produce new artifacts without impacting previously published versions.
