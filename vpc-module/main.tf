provider "aws" {
  shared_credentials_files = ["aws-creds.ini"]
  region = "us-east-1"
}

// Modules _must_ use remote state. The provider does not persist state.
terraform {
  backend "kubernetes" {
    secret_suffix     = "providerconfig-default"
    namespace         = "default"
    in_cluster_config = true
  }
}
resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "TF VPC for MIKE"
 }
}
