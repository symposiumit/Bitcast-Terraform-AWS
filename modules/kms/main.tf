resource "aws_kms_key" "this" {
  description             = "${var.project} Nitro Enclave attestation"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  tags = merge(var.tags, {
    Name = "${var.project}-enclave-kms"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project}-enclave"
  target_key_id = aws_kms_key.this.key_id
}
