# AWS Nitro Enclaves Terraform Stack

This repository contains a module-based Terraform configuration that provisions the foundational components required to run [AWS Nitro Enclaves](https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave.html). The stack focuses on:

- A dedicated VPC with public subnets for Nitro-capable parent instances
- Optional KMS key for attestation payloads and vsock proxy secrets
- A Nitro-ready EC2 instance configured to host enclaves using Amazon Linux 2023

## Project Structure

```
.
├── main.tf                 # Root composition wiring modules together
├── outputs.tf              # Surfaces important IDs after apply
├── providers.tf            # AWS provider definition
├── variables.tf            # Input variables for the stack
├── versions.tf             # Provider and Terraform version constraints
├── terraform.tfvars.example
├── modules
│   ├── network             # VPC, subnets, internet connectivity
│   ├── kms                 # Optional dedicated KMS key
│   └── enclave_instance    # Nitro-capable EC2 parent and IAM roles
```

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust values (region, key pair, allowed CIDRs, etc.).
2. (Optional) Update `backend.tf` with the desired S3 bucket, key prefix, DynamoDB lock table, and region for remote state storage.

3. Initialize Terraform in this directory:

   ```bash
   terraform init
   ```

4. Review the plan:

   ```bash
   terraform plan
   ```

5. Apply the configuration:

   ```bash
   terraform apply
   ```

## Notes

- The parent instance uses Amazon Linux 2023 and enables the Nitro Enclaves allocator and vsock proxy services.
- To attach an existing KMS key, set `kms_key_arn` and disable `create_kms_key`.
- Enclave CPU and memory settings are exposed via `enclave_cpu_count` and `enclave_memory_mib` variables to match the workload profile.
- Additional parent instances can be added by reusing the `enclave_instance` module in the root configuration.

Refer to the AWS Nitro Enclaves developer guide for building, signing, and running enclave images on the provisioned parent instance.
