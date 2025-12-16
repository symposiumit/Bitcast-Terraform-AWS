locals {
  tags = merge({
    Project   = var.project
    ManagedBy = "terraform"
  }, var.tags)
}

module "network" {
  source = "./modules/network"

  project             = var.project
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
  tags                = local.tags
}

module "kms" {
  source = "./modules/kms"
  count  = var.kms_key_arn == null && var.create_kms_key ? 1 : 0

  project = var.project
  tags    = local.tags
}

module "enclave_parent" {
  source = "./modules/enclave_instance"

  project               = var.project
  name                  = var.parent_instance_name
  subnet_id             = module.network.public_subnet_ids[0]
  vpc_id                = module.network.vpc_id
  instance_type         = var.parent_instance_type
  ssh_key_name          = var.ssh_key_name
  allowed_ingress_cidrs = var.allowed_ingress_cidrs
  enclave_cpu_count     = var.enclave_cpu_count
  enclave_memory_mib    = var.enclave_memory_mib
  kms_key_arn           = coalesce(var.kms_key_arn, try(module.kms[0].key_arn, null))
  tags                  = local.tags
}
