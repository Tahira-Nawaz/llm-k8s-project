# =============================================================================
# Terraform Remote State Backend (S3 + DynamoDB locking)
# =============================================================================
# IMPORTANT: The S3 bucket and DynamoDB table must be created MANUALLY before
# running terraform init. This prevents circular dependencies and ensures
# manual control over state management infrastructure.
# =============================================================================
terraform {
  backend "s3" {
    bucket         = "llm-k8s-terraform-state"
    key            = "terraform-state/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "llm-k8s-terraform-state-lock"
  }
}