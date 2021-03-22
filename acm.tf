# WARNING: The private key will be stored in terraform state
resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "this" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = var.domain_name
    organization = "Hello World"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Tip: Use ACM to create a certificate to avoid using a self-signed cert
resource "aws_acm_certificate" "this" {
  private_key      = tls_private_key.this.private_key_pem
  certificate_body = tls_self_signed_cert.this.cert_pem
}
